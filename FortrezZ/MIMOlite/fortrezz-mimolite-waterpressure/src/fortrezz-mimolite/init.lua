-- Copyright 2022 philh30
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
local cc = require "st.zwave.CommandClass"
local log = require "log"
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
--- @type st.zwave.CommandClass.Alarm
local Alarm = (require "st.zwave.CommandClass.Alarm")({version=1})
--- @type st.zwave.CommandClass.SensorBinary
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({version=1})
--- @type st.zwave.CommandClass.SensorMultilevel
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({version=5})
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2})
local update_preferences = require "update_preferences"
local utils = require "st.utils"

local MIMOLITE_FINGERPRINTS = {
  {mfr = 0x0084, prod = 0x0453, model = 0x0111},
}

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @return boolean true
local function can_handle_mimolite(opts, driver, device, ...)
  for _, fingerprint in ipairs(MIMOLITE_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function info_changed(driver, device, event, args)
  update_preferences(driver, device, args)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  device:refresh()
  update_preferences(driver, device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added(driver, device)
  device:refresh()
  update_preferences(driver, device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function basic_set(driver, device, cmd)
  local evt = (cmd.args.value == 0) and capabilities.contactSensor.contact.closed() or capabilities.contactSensor.contact.open()
  device:emit_event(evt)
  device:emit_event(capabilities.powerSource.powerSource.dc())
  device:send(SensorMultilevel:Get({}))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function sensor_binary_report(driver, device, cmd)
  local evt = (cmd.args.sensor_value == 0) and capabilities.contactSensor.contact.closed() or capabilities.contactSensor.contact.open()
  device:emit_event(evt)
  device:emit_event(capabilities.powerSource.powerSource.dc())
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function switch_binary_report(driver, device, cmd)
  local evt = (cmd.args.value == 0) and capabilities.switch.switch.off() or capabilities.switch.switch.on()
  device:emit_event(evt)
  device:emit_event(capabilities.powerSource.powerSource.dc())
end

local function calc_voltage(ADCvalue)
  local volt = (((1.5338*(10^-16))*(ADCvalue^5)) - ((1.2630*(10^-12))*(ADCvalue^4)) + ((3.8111*(10^-9))*(ADCvalue^3)) - ((4.7739*(10^-6))*(ADCvalue^2)) + ((2.8558*(10^-3))*(ADCvalue)) - (2.2721*(10^-2)))
  return volt
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function sensor_multilevel_report(driver, device, cmd)
  local volt = calc_voltage(cmd.args.sensor_value)
  local water_pressure = utils.round(volt*28.1-28.1)
  local humidity = utils.clamp_value(water_pressure,0,100)
  local evt = capabilities.voltageMeasurement.voltage({value=volt,unit="V"})
  device:emit_event(evt)
  device:emit_event(capabilities['platinummassive43262.waterPressure'].waterPressure({value=water_pressure,unit="PSI"}))
  device:emit_event(capabilities.relativeHumidityMeasurement.humidity({value=humidity,unit="%"}))
  device:emit_event(capabilities.powerSource.powerSource.dc())
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function alarm_report(driver, device, cmd)
  device:emit_event(capabilities.powerSource.powerSource.unknown())
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function on(driver, device, cmd)
  device:send(Basic:Set({value = 0xFF}))
  device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function off(driver, device, cmd)
  device:send(Basic:Set({value = 0x00}))
  device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_refresh(driver, device, cmd)
  device:send(SwitchBinary:Get({}))
  device:send(SensorMultilevel:Get({}))
  device:send(SensorBinary:Get({}))
end

local mimolite = {
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.SET] = basic_set,
    },
    [cc.SENSOR_BINARY] = {
      [SensorBinary.REPORT] = sensor_binary_report,
    },
    [cc.SENSOR_MULTILEVEL] = {
      [SensorMultilevel.REPORT] = sensor_multilevel_report,
    },
    [cc.SWITCH_BINARY] = {
      [SwitchBinary.REPORT] = switch_binary_report,
    },
    [cc.ALARM] = {
      [Alarm.REPORT] = alarm_report,
    },
  },
  supported_capabilities = {
    capabilities.switch,
    capabilities.contactSensor,
    capabilities.voltageMeasurement,
    capabilities.refresh,
  },
  lifecycle_handlers = {
    infoChanged = info_changed,
    doConfigure = do_configure,
    added = added,
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = do_refresh
    },
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on,
      [capabilities.switch.commands.off.NAME] = off,
    },
  },
  NAME = "mimolite",
  can_handle = can_handle_mimolite,
}

return mimolite