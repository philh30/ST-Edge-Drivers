-- Copyright 2021 SmartThings
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
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version=1 })
--- @type st.zwave.CommandClass.Battery
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 3 })
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 1 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
--- @type st.utils
local utils = require "st.utils"
local call_parent_handler = require "call_parent"
local battery = require "battery"

local VISION_FINGERPRINTS = {
  { manufacturerId = 0x0109, productType = 0x2001, productId = 0x0102 }, -- Vision ZD2102 contact sensor (also Monoprice #10795 rebrand)
  { manufacturerId = 0x0109, productType = 0x200A, productId = 0x0A02 }, -- Vision ZG8101 garage sensor (also Monoprice #11987 rebrand)
}

---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true if the device proper, else false
local function can_handle_vision_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(VISION_FINGERPRINTS) do
    if device:id_match(fingerprint.manufacturerId, fingerprint.productType, fingerprint.productId) then
      return true
    end
  end
  return false
end

--- Handler for notification report command class
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Notification.Report
local function notification_report_handler(self, device, cmd)
  local event

  -- These sensors use INTRUSION as the event for motion, not MOTION_DETECTION as some other sensors might.
  if cmd.args.notification_type == Notification.notification_type.HOME_SECURITY then
    if cmd.args.event == Notification.event.home_security.INTRUSION then
      event = cmd.args.alarm_level == 0 and capabilities.contactSensor.contact.closed() or capabilities.contactSensor.contact.open()
    end
    if cmd.args.event == Notification.event.home_security.UNKNOWN_EVENT_STATE then
      -- For the external inputs
      event = cmd.args.alarm_level == 0 and capabilities.contactSensor.contact.closed() or capabilities.contactSensor.contact.open()
    end
    if cmd.args.event == Notification.event.home_security.TAMPERING_PRODUCT_COVER_REMOVED then
      event = capabilities.tamperAlert.tamper.detected()
      -- The tamper will be cleared when the device wakes up upon the tamper switch
      -- being closed again.
      --device.thread:call_with_delay(10, function(d)
      --  device:emit_event(capabilities.tamperAlert.tamper.clear())
      --end)
    end
  end
  if (event ~= nil) then
    device:emit_event(event)
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
  device.log.trace("wakeup_notification()")

  -- Get the sensor state on wakeup.   Note that we cannot use SENSOR BINARY GET as 
  --  the device will return SENSOR BINARY REPORT sometimes different from 
  -- the current value of the sensor.
  device:send(Basic:Get({}))

  -- When the cover is restored (tamper switch closed), the device wakes up.  Assume tamper is now clear.
  device:emit_event(capabilities.tamperAlert.tamper.clear())

  -- We may need to request a battery update while we're woken up
  if battery.getBatteryUpdate(self, device) then
    -- Request a battery update now
    device:send(Battery:Get({}))
  end
end

--- These are non-standard uses of the basic set command, but this device uses it instead of 
--- BASIC REPORT
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Basic.Set
local function basic_set_handler(driver, device, cmd)
  if cmd.args.value > 0 then
    device:emit_event(capabilities.contactSensor.contact.open())
  else
    device:emit_event(capabilities.contactSensor.contact.closed())
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SensorBinary.Report
local function sensor_binary_report_handler(self, device, cmd)

  --- These devices do not always return the correct value for 
  --- the sensor in a SENSOR BINARY REPORT.
  ---  So if we get them, just eat it.

  device.log.warn("sensor_binary_report_handler() untrusted, ignoring value")
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function doConfigure(self, device, event, args)
  -- Call the topmost 'doConfigure' lifecycle hander to do the default work first
  call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, event, args)

  -- Send the default refresh commands for the capabilities of this device
  -- This includes SENSOR_BINARY GET and BATTERY GET.
  device:default_refresh()
end

local vision_contact = {
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.SET] = basic_set_handler
    },
    [cc.SENSOR_BINARY] = {
      [SensorBinary.REPORT] = sensor_binary_report_handler,
    },
    [cc.WAKE_UP] = {
      [WakeUp.NOTIFICATION] = wakeup_notification,
    },
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = notification_report_handler,
    },
  },
  lifecycle_handlers = {
    doConfigure = doConfigure,
  },
  NAME = "vision contact sensor",
  can_handle = can_handle_vision_sensor
}

return vision_contact