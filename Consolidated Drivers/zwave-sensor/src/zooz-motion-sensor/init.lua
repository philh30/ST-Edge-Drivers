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
--- @type st.zwave.CommandClass.Battery
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 3 })
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 2 })
--- @type st.zwave.CommandClass.SensorMultilevel
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({ version = 5 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
--- @type st.utils
local utils = require "st.utils"

local LAST_BATTERY_REPORT_TIME = "lastBatteryReportTime"

local ZOOZ_FINGERPRINTS = {
  { manufacturerId = 0x027A, productType = 0x2021, productId = 0x2101 }, -- Zooz 4-in-1 sensor
  { manufacturerId = 0x0109, productType = 0x2021, productId = 0x2101 }, -- Monoprice 4-in-1 sensor
  { manufacturerId = 0x027A, productType = 0x0200, productId = 0x0006 }, -- Zooz Q Sensor - EU Version
  { manufacturerId = 0x027A, productType = 0x0201, productId = 0x0006 }, -- Zooz Q Sensor - US Version
  { manufacturerId = 0x027A, productType = 0x0202, productId = 0x0006 }, -- Zooz Q Sensor - AU Version
}

--- Determine whether the passed device is zooz_4_in_1_sensor
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true if the device proper, else false
local function can_handle_zooz_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZOOZ_FINGERPRINTS) do
    if device:id_match(fingerprint.manufacturerId, fingerprint.productType, fingerprint.productId) then
      return true
    end
  end
  return false
end

local function call_parent_handler(handlers, self, device, event, args)
  if type(handlers) == "function" then
    handlers = { handlers }  -- wrap as table
  end
  for _, func in ipairs( handlers or {} ) do
      func(self, device, event, args)
  end
end

--- Handler for notification report command class
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Notification.Report
local function notification_report_handler(self, device, cmd)
  local event
  if cmd.args.notification_type == Notification.notification_type.HOME_SECURITY then
    if cmd.args.event == Notification.event.home_security.MOTION_DETECTION then
      event = cmd.args.notification_status == 0 and capabilities.motionSensor.motion.inactive() or capabilities.motionSensor.motion.active()
    end
    if cmd.args.event == Notification.event.home_security.TAMPERING_PRODUCT_COVER_REMOVED then
      event = capabilities.tamperAlert.tamper.detected()
      device.thread:call_with_delay(10, function(d)
        device:emit_event(capabilities.tamperAlert.tamper.clear())
      end)
    end
    if cmd.args.event == Notification.event.home_security.STATE_IDLE then
      if #cmd.args.event_parameter >= 1 and string.byte(cmd.args.event_parameter, 1) == 8 then
        event = capabilities.motionSensor.motion.inactive()
      else
        event = capabilities.tamperAlert.tamper.clear()
      end
    end
  end
  if (event ~= nil) then
    device:emit_event(event)
  end
end

local function get_lux_from_percentage(percentage_value)
  local conversion_table = {
    {min = 1, max = 9.99, multiplier = 3.843},
    {min = 10, max = 19.99, multiplier = 5.231},
    {min = 20, max = 29.99, multiplier = 4.999},
    {min = 30, max = 39.99, multiplier = 4.981},
    {min = 40, max = 49.99, multiplier = 5.194},
    {min = 50, max = 59.99, multiplier = 6.016},
    {min = 60, max = 69.99, multiplier = 4.852},
    {min = 70, max = 79.99, multiplier = 4.836},
    {min = 80, max = 89.99, multiplier = 4.613},
    {min = 90, max = 100, multiplier = 4.5}
  }
  for _, tables in ipairs(conversion_table) do
    if percentage_value >= tables.min and percentage_value <= tables.max then
      return utils.round(percentage_value * tables.multiplier)
    end
  end
  return utils.round(percentage_value * 5.312)
end

--- Handler for sensor multilevel report command class
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SensorMultilevel.Report
local function sensor_multilevel_report_handler(self, device, cmd)
  if cmd.args.sensor_type == SensorMultilevel.sensor_type.LUMINANCE then
    local value = cmd.args.scale == SensorMultilevel.scale.luminance.PERCENTAGE and get_lux_from_percentage(cmd.args.sensor_value) or cmd.args.sensor_value
    device:emit_event(capabilities.illuminanceMeasurement.illuminance({value = value, unit = "lux"}))
  elseif cmd.args.sensor_type == SensorMultilevel.sensor_type.RELATIVE_HUMIDITY then
    device:emit_event(capabilities.relativeHumidityMeasurement.humidity({value = utils.round(cmd.args.sensor_value)}))
  elseif cmd.args.sensor_type == SensorMultilevel.sensor_type.TEMPERATURE then
    local scale = cmd.args.scale == SensorMultilevel.scale.temperature.FAHRENHEIT and 'F' or 'C'
    device:emit_event(capabilities.temperatureMeasurement.temperature({value = cmd.args.sensor_value, unit = scale}))
  end
end

-- Request a battery update from the device.
-- This should only be called when the radio is known to be listening
-- (during initial inclusion/configuration and during Wakeup)
local function getBatteryUpdate(device, force)
  device.log.trace("getBatteryUpdate()")
  if not force then
      -- Calculate if its time
      local last = device:get_field(LAST_BATTERY_REPORT_TIME)
      if last then
          local now = os.time()
          local diffsec = os.difftime(now, last)
          device.log.debug("Last battery update: " .. os.date("%c", last) .. "(" .. diffsec .. " seconds ago)" )
          local wakeup_offset = 60 * 60 * 24  -- Assume 1 day preference

          if tonumber(device.preferences.batteryInterval) < 100 then
              -- interval is a multiple of our wakeup time (in seconds)
              wakeup_offset = tonumber(device.preferences.wakeUpInterval) * tonumber(device.preferences.batteryInterval)
          end

          if wakeup_offset > 0 then
              -- Adjust for about 5 minutes to cover waking up "early"
              wakeup_offset = wakeup_offset - (60 * 5)
              
              -- Has it been longer than our interval?
              force = diffsec >= wakeup_offset
          end
      else
          force = true -- No last battery report, get one now
      end
  end

  if not force then device.log.debug("No battery update needed") end

  if force then
      -- Request a battery update now
      device:send(Battery:Get({}))
  end

end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
  device.log.trace("wakeup_notification()")

  -- Check the motion sensor if it's currently tripped
  if device:get_latest_state('main',capabilities.motionSensor.ID,'motion','active') == 'active' then
    if device:is_cc_supported(cc.SENSOR_BINARY) then
      device:send(SensorBinary:Get({sensor_type = SensorBinary.sensor_type.MOTION}))
    else
      device:send(Notification:Get({v1_alarm_type=7,notification_type=Notification.notification_type.HOME_SECURITY,event=Notification.event.home_security.MOTION_DETECTION}))
    end
  end

  -- We may need to request a battery update while we're woken up
  getBatteryUpdate(device)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Battery.Report
local function battery_report(self, device, cmd)
  -- Save the timestamp of the last battery report received.
  device:set_field(LAST_BATTERY_REPORT_TIME, os.time(), { persist = true } )
  if cmd.args.battery_level == 99 then cmd.args.battery_level = 100 end
  if cmd.args.battery_level == 0xFF then cmd.args.battery_level = 1 end
  -- Forward on to the default battery report handlers from the top level
  call_parent_handler(self.zwave_handlers[cc.BATTERY][Battery.REPORT], self, device, cmd)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function device_added(self, device, event, args)
  if device:is_cc_supported(cc.BATTERY) then
    if device:supports_capability(capabilities.powerSource) then
      device:emit_event(capabilities.powerSource.powerSource.battery())
    end
  else
    if device:supports_capability(capabilities.powerSource) then
      device:emit_event(capabilities.powerSource.powerSource.dc())
    end
    device:emit_event(capabilities.battery.battery({value=100,unit="%"}))
  end
  call_parent_handler(self.lifecycle_handlers.added, self, device, event, args)
end

local zooz_sensor = {
  zwave_handlers = {
    [cc.WAKE_UP] = {
        [WakeUp.NOTIFICATION] = wakeup_notification,
    },
    [cc.BATTERY] = {
        [Battery.REPORT] = battery_report,
    },
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = notification_report_handler
    },
    [cc.SENSOR_MULTILEVEL] = {
      [SensorMultilevel.REPORT] = sensor_multilevel_report_handler
    }
  },
  lifecycle_handlers = {
    added = device_added,
  },
  NAME = "zooz motion sensor",
  can_handle = can_handle_zooz_sensor
}

return zooz_sensor
