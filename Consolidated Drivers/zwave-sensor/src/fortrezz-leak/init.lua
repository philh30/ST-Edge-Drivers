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

local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 1 })
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({ version = 1 })
local capabilities = require "st.capabilities"
local cc = require "st.zwave.CommandClass"

local LAST_BATTERY_REPORT_TIME = "lastBatteryReportTime"

local ZWAVE_TEMP_LEAK_SENSOR_FINGERPRINTS = {
  {mfr = 0x0084, prod = 0x0053, model = 0x0216} -- FortrezZ Temperature and Leak Sensor
}

local function can_handle_zwave_temp_leak_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZWAVE_TEMP_LEAK_SENSOR_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
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

  -- We may need to request a battery update while we're woken up
  getBatteryUpdate(device)

  -- Request a temperature report
  if device.preferences.requestTemperature then
    device:send(SensorMultilevel:Get({}))
  end
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

local function basic_set(driver,device,cmd)
  device:emit_event(capabilities.waterSensor.water({ value = cmd.args.value == 0 and "dry" or "wet" }))
end

local function sensor_binary_report(driver,device,cmd)
  -- Freeze alarm triggers at 39F (not configurable)
  device:emit_event(capabilities.temperatureAlarm.temperatureAlarm({ value = cmd.args.value == 0 and "cleared" or "freeze" }))
end

local function temperature_report(self, device, cmd)
  if (cmd.args.sensor_type == SensorMultilevel.sensor_type.TEMPERATURE) then
    local scale = 'C'
    if (cmd.args.scale == SensorMultilevel.scale.temperature.FAHRENHEIT) then scale = 'F' end
    local evt = capabilities.temperatureMeasurement.temperature({value = cmd.args.sensor_value, unit = scale})
    device:emit_event_for_endpoint(cmd.src_channel, evt)
  end
end

local fortrezz_leak = {
  zwave_handlers = {
    [cc.WAKE_UP] = {
      [WakeUp.NOTIFICATION] = wakeup_notification,
    },
    [cc.BASIC] = {
      [Basic.SET] = basic_set,
    },
    [cc.BATTERY] = {
        [Battery.REPORT] = battery_report,
    },
    [cc.SENSOR_BINARY] = {
      [SensorBinary.REPORT] = sensor_binary_report,
    },
    [cc.SENSOR_MULTILEVEL] = {
      [SensorMultilevel.REPORT] = temperature_report,
    },
  },
  lifecycle_handlers = {
    --added = dev_added
  },
  NAME = "zwave fortrezz temp leak sensor",
  can_handle = can_handle_zwave_temp_leak_sensor,
}

return fortrezz_leak