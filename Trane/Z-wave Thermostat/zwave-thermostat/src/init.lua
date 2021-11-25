-- Author: philh30
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

local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({ version = 1 })
local ThermostatSetpoint = (require "st.zwave.CommandClass.ThermostatSetpoint")({ version = 1 })
local ThermostatMode = (require "st.zwave.CommandClass.ThermostatMode")({ version = 1 })
local ThermostatFanMode = (require "st.zwave.CommandClass.ThermostatFanMode")({ version = 1 })
local ThermostatOperatingState = (require "st.zwave.CommandClass.ThermostatOperatingState")({ version = 1 })
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 1 })
local Clock = (require "st.zwave.CommandClass.Clock")({ version = 1 })
local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local cc = require "st.zwave.CommandClass"
local log = require "log"
local zw = require "st.zwave"
local constants = require "st.zwave.constants"
local utils = require "st.utils"
local capdefs = require "capabilitydefs"
local socket = require "cosock.socket"
local delay_send = require "delay_send"

capabilities[capdefs.thermostatScheduleMode.name]  = capdefs.thermostatScheduleMode.capability

local ZWAVE_THERMOSTAT_FINGERPRINTS = {
  {mfr = 0x008B, prod = 0x5452, model = 0x5433} -- Trane TZEMT400BB3NX
}

local CONFIG_PARAMS = {}

local function can_handle_zwave_thermostat(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZWAVE_THERMOSTAT_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

local function refresh(driver,device)
  log.debug('Refresh')
  
  local now = os.date('*t')
	local offset = -5                 -- Currently EST. Update when local time is available.
	local now_hour = (now.hour + offset > 0) and ((now.hour + offset < 24) and (now.hour + offset) or (now.hour - 24 + offset)) or (now.hour + 24 + offset)

  local cmds = {
    Clock:Set({ weekday = (now.wday + 5) % 7, hour = now_hour, minute = now.min }),
    Clock:Get({}),
    ThermostatFanMode:SupportedGet({}),
    ThermostatMode:SupportedGet({}),
    Configuration:Get({ parameter_number = 132 }),  -- Hold = 0, Run Schedule = 1
    Configuration:Get({ parameter_number = 25 }),   -- Energy save on = 2, off = 0
    ThermostatFanMode:Get({}),
    ThermostatMode:Get({}),
    ThermostatOperatingState:Get({}),
    ThermostatSetpoint:Get({setpoint_type = ThermostatSetpoint.setpoint_type.HEATING_1}),
    ThermostatSetpoint:Get({setpoint_type = ThermostatSetpoint.setpoint_type.COOLING_1}),
    SensorMultilevel:Get({}),
  }
  delay_send(device,cmds,1)
end

local function dev_init(driver, device)
  log.debug('Device Init')
  refresh(driver,device)
end

local function dev_added(driver, device)
  log.debug('Device added - getting supported modes')
  device:emit_event(capabilities[capdefs.thermostatScheduleMode.name].supportedThermostatScheduleModes({ value = {'run','hold','esm'} }))
end

---------------------------
-- Delete these next two functions if the default capability handlers are fixed to send the right Fahrenheit temp
local function set_cooling_setpoint(driver, device, command)
  local scale = device:get_field(constants.TEMPERATURE_SCALE)
  local loc_scale = device.state_cache.main.thermostatCoolingSetpoint.coolingSetpoint.unit
  local value = command.args.setpoint
  if (scale == ThermostatSetpoint.scale.FAHRENHEIT) and loc_scale == 'C' then
    value = utils.c_to_f(value) -- the device has reported using F, so set using F
  end
  if (scale == ThermostatSetpoint.scale.CELSIUS) and loc_scale == 'F' then
    value = utils.f_to_c(value) -- the device has reported using C, so set using C
  end

  local set = ThermostatSetpoint:Set({
    setpoint_type = ThermostatSetpoint.setpoint_type.COOLING_1,
    scale = scale,
    value = value
  })
  device:send_to_component(set, command.component)

  local follow_up_poll = function()
    device:send_to_component(ThermostatSetpoint:Get({setpoint_type = ThermostatSetpoint.setpoint_type.COOLING_1}), command.component)
  end

  device.thread:call_with_delay(1, follow_up_poll)
end

local function set_heating_setpoint(driver, device, command)
  local scale = device:get_field(constants.TEMPERATURE_SCALE)
  local loc_scale = device.state_cache.main.thermostatHeatingSetpoint.heatingSetpoint.unit
  local value = command.args.setpoint
  if (scale == ThermostatSetpoint.scale.FAHRENHEIT) and loc_scale == 'C' then
    value = utils.c_to_f(value) -- the device has reported using F, so set using F
  end
  if (scale == ThermostatSetpoint.scale.CELSIUS) and loc_scale == 'F' then
    value = utils.f_to_c(value) -- the device has reported using C, so set using C
  end

  local set = ThermostatSetpoint:Set({
    setpoint_type = ThermostatSetpoint.setpoint_type.HEATING_1,
    scale = scale,
    value = value
  })
  device:send_to_component(set, command.component)

  local follow_up_poll = function()
    device:send_to_component(
      ThermostatSetpoint:Get({setpoint_type = ThermostatSetpoint.setpoint_type.HEATING_1}),
      command.component
    )
  end

  device.thread:call_with_delay(1, follow_up_poll)
end

---------------------------
-- Functions to handle Schedule Mode (run/hold/energy save)
local function set_schedule_mode(driver,device,command)
  local par25 = (command.args.mode == 'esm') and 2 or 0
  local par132 = (command.args.mode == 'run') and 1 or 0
  device:send(Configuration:Set({parameter_number = 132, configuration_value = par132, size = 1, default = false}))
  device:send(Configuration:Set({parameter_number = 25, configuration_value = par25, size = 1, default = false}))
  local follow_up_poll = function()
    device:send(Configuration:Get({parameter_number = 132}))
    device:send(Configuration:Get({parameter_number = 25}))
  end
  device.thread:call_with_delay(1, follow_up_poll)
end

local function configuration_report(driver, device, command)
  CONFIG_PARAMS[command.args.parameter_number] = command.args.configuration_value
  if CONFIG_PARAMS[25] and CONFIG_PARAMS[132] then
    local schedule_mode = ((CONFIG_PARAMS[25] == 2) and 'esm') or (((CONFIG_PARAMS[132] == 0) and 'hold') or 'run')
    device:emit_event(capabilities[capdefs.thermostatScheduleMode.name].thermostatScheduleMode({ value = schedule_mode }))
  end
end

---------------------------
-- Driver template
local driver_template = {
  zwave_handlers = {
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = configuration_report,
    },
  },
  supported_capabilities = {
    capabilities.temperatureMeasurement,
    capabilities.thermostatCoolingSetpoint,
    capabilities.thermostatFanMode,
    capabilities.thermostatHeatingSetpoint,
    capabilities.thermostatMode,
    capabilities.thermostatOperatingState,
  },
  lifecycle_handlers = {
    init = dev_init,
    added = dev_added,
  },
  -- Override the default handlers for heating and cooling set points. As of 10/2021, defaults are not handling
  -- locations set to Fahrenheit properly. Remove in future if defaults are fixed.
  capability_handlers = {
    [capabilities.thermostatHeatingSetpoint.ID] = {
          [capabilities.thermostatHeatingSetpoint.commands.setHeatingSetpoint.NAME] = set_heating_setpoint,
        },
    [capabilities.thermostatCoolingSetpoint.ID] = {
          [capabilities.thermostatCoolingSetpoint.commands.setCoolingSetpoint.NAME] = set_cooling_setpoint,
        },
    [capdefs.thermostatScheduleMode.capability.ID] = {
          [capdefs.thermostatScheduleMode.capability.commands.setThermostatScheduleMode.NAME] = set_schedule_mode,
        },
    [capabilities.refresh.ID] = {
          [capabilities.refresh.commands.refresh.NAME] = refresh,
        }
  },
  NAME = "zwave thermostat",
  can_handle = can_handle_zwave_thermostat,
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local thermostat = ZwaveDriver("zwave-thermostat", driver_template)
thermostat:run()