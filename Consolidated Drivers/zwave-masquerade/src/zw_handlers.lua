-- Copyright 2021 SmartThings
--
-- Modified 2022 philh30 - contact/motion/switch handlers collected and
-- modified to produce a binary result
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local capabilities = require "st.capabilities"
local log = require "log"
--- @type st.zwave.CommandClass
local cc  = require "st.zwave.CommandClass"
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({version=1,strict=true})
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2,strict=true})
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({version=4,strict=true})
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({version=3})
--- @type st.zwave.CommandClass.SensorAlarm
local SensorAlarm = (require "st.zwave.CommandClass.SensorAlarm")({version=1})
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({version=2})
local emit_event = require "events"

local zwave_handlers = {}

--- Default handler for basic, binary and multilevel switch reports for
--- switch-implementing devices
---
--- This converts the command value from 0 -> Switch.switch.off, otherwise
--- Switch.switch.on.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SwitchMultilevel.Report|st.zwave.CommandClass.SwitchBinary.Report|st.zwave.CommandClass.Basic.Report
function zwave_handlers.report(driver, device, cmd)
  local event
  if cmd.args.target_value ~= nil then
    -- Target value is our best inidicator of eventual state.
    -- If we see this, it should be considered authoritative.
    if cmd.args.target_value == SwitchBinary.value.OFF_DISABLE then
      event = 0
    else
      event = 1
    end
  else
    if cmd.args.value == SwitchBinary.value.OFF_DISABLE then
      event = 0
    else
      event = 1
    end
  end
  emit_event(device,event)
end

--- Handle basic set commands
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Basic.Set
function zwave_handlers.basic_set_handler(self, device, cmd)
  local event
  if cmd.args.value > 0 then
    event = 1
  else
    event = 0
  end
  emit_event(device,event)
end

--- Default handler for binary sensor command class reports
---
--- This converts binary sensor reports to correct contact open/closed events
---
--- For a device that uses v1 of the binary sensor command class, all reports will be considered
--- contact reports.
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SensorBinary.Report
function zwave_handlers.sensor_binary_report_handler(self, device, cmd)
  local event
  if (cmd.args.sensor_value == SensorBinary.sensor_value.DETECTED_AN_EVENT) then
    event = 1
  elseif (cmd.args.sensor_value == SensorBinary.sensor_value.IDLE) then
    event = 0
  end
  emit_event(device,event)
end

--- Default handler for sensor alarm command class reports
---
--- This converts sensor alarm reports to correct motion active/inactive events
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SensorAlarm.Report
function zwave_handlers.sensor_alarm_report_handler(self, device, cmd)
  local event
  if (cmd.args.sensor_type == SensorAlarm.sensor_type.GENERAL_PURPOSE_ALARM) then
    if (cmd.args.sensor_state == SensorAlarm.sensor_state.ALARM) then
      event = 1
    elseif (cmd.args.sensor_state == SensorAlarm.sensor_state.NO_ALARM) then
      event = 0
    end
  end
  emit_event(device,event)
end

--- Default handler for notification command class reports
---
--- This converts intrusion home security reports into contact open/closed events
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Notification
function zwave_handlers.notification_handler(self, device, cmd)
  local contact_notification_events_map = {
    [Notification.event.home_security.INTRUSION_LOCATION_PROVIDED] = 1,
    [Notification.event.home_security.INTRUSION] = 1,
    [Notification.event.home_security.STATE_IDLE] = 0,
    [Notification.event.access_control.WINDOW_DOOR_IS_OPEN] = 1,
    [Notification.event.access_control.WINDOW_DOOR_IS_CLOSED] = 0,
    [Notification.event.home_security.MOTION_DETECTION_LOCATION_PROVIDED] = 1,
    [Notification.event.home_security.MOTION_DETECTION] = 1,
  }
  local event
  if cmd.args.v1_alarm_type == 0 then
    -- Notification command class
    if (cmd.args.notification_type == Notification.notification_type.HOME_SECURITY or
        cmd.args.notification_type == Notification.notification_type.ACCESS_CONTROL)
    then
      event = contact_notification_events_map[cmd.args.event]
    end
  else
    -- Older implementation using alarm command class. Assume cmd.args.v1_alarm_level = 0 is off and >0 is on.
    if cmd.args.v1_alarm_level == 0 then
      event = 0
    else
      event = 1
    end
  end
  if event then emit_event(device,event) end
end

return zwave_handlers
