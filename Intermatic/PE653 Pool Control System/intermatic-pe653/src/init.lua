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

local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version = 1 })
local SwitchAll = (require "st.zwave.CommandClass.SwitchAll")({ version = 1 })
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({ version = 1 })
local ThermostatSetpoint = (require "st.zwave.CommandClass.ThermostatSetpoint")({ version = 1 })
local MultiInstance = (require "st.zwave.CommandClass.MultiInstance")({ version = 1 })
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 2 })
local ManufacturerSpecific = (require "st.zwave.CommandClass.ManufacturerSpecific")({ version = 1 })
local Powerlevel = (require "st.zwave.CommandClass.Powerlevel")({ version = 1 })
local Clock = (require "st.zwave.CommandClass.Clock")({ version = 1 })
local Association = (require "st.zwave.CommandClass.Association")({ version = 1 })
local Version = (require "st.zwave.CommandClass.Version")({ version = 1 })
local ManufacturerProprietary = (require "st.zwave.CommandClass.ManufacturerProprietary")({ version = 1 })
local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local cc = require "st.zwave.CommandClass"
local log = require "log"
local zw = require "st.zwave"
local constants = require "st.zwave.constants"
local utils = require "st.utils"
local capdefs = require "capabilitydefs"

capabilities[capdefs.firmwareVersion.name] = capdefs.firmwareVersion.capability
capabilities[capdefs.pumpSpeed.name] = capdefs.pumpSpeed.capability
capabilities[capdefs.schedule.name] = capdefs.schedule.capability
capabilities[capdefs.scheduleTime.name] = capdefs.scheduleTime.capability
capabilities[capdefs.poolSpaConfig.name] = capdefs.poolSpaConfig.capability
capabilities[capdefs.pumpTypeConfig.name] = capdefs.pumpTypeConfig.capability
capabilities[capdefs.firemanConfig.name] = capdefs.firemanConfig.capability
capabilities[capdefs.heaterSafetyConfig.name] = capdefs.heaterSafetyConfig.capability
capabilities[capdefs.circuit1FreezeControl.name] = capdefs.circuit1FreezeControl.capability
capabilities[capdefs.circuit2FreezeControl.name] = capdefs.circuit2FreezeControl.capability
capabilities[capdefs.circuit3FreezeControl.name] = capdefs.circuit3FreezeControl.capability
capabilities[capdefs.circuit4FreezeControl.name] = capdefs.circuit4FreezeControl.capability
capabilities[capdefs.circuit5FreezeControl.name] = capdefs.circuit5FreezeControl.capability

local socket = require "cosock.socket"
local utilities = require "utilities"
local cc_handlers = require "cc_handlers"
local commands = require "commands"
local delay_send = require "delay_send"
local get = require "get_constants"
local config = require "config"

local ZWAVE_FINGERPRINTS = {
  {mfr = 0x0005, prod = 0x5045, model = 0x0653}, -- PE653
}

local CONFIG_PARAMS = {}

local function can_handle_zwave(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZWAVE_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function dev_init(driver, device)
  log.trace('Device initializing...')
  log.trace('Checking endpoint mappings to components|capabilities:')
  for _, component in pairs(device.profile.components) do
    for _, capability in pairs(component.capabilities) do
      if capability.id == 'refresh' then
        log.trace(component.id .. '|' .. capability.id .. ' mapping not required.')
      else
        if config.CAP_MAP[component.id] then
          if config.CAP_MAP[component.id][capability.id] then 
            log.trace(utilities.pad(config.CAP_MAP[component.id][capability.id],25), '=', component.id .. '|' .. capability.id)
          else
            log.error(component.id .. '.' .. capability.id .. ' failed to map. Report this error.')
          end
        else
          log.error(component.id .. ' not found in component/capability map. Report this error.')
        end
      end
    end
  end
  local basic_refresh = function()
    log.warn('BASIC REFRESH')
    commands.refresh(driver,device)
  end
  local basic_poll_freq = 600
  log.trace(string.format('Setting up basic polling every %s minutes.',basic_poll_freq/60))
  device.thread:call_on_schedule(basic_poll_freq,basic_refresh,'basicRefresh')
  local full_config_poll_offset = 300
  local full_config_poll_freq = 7200
  local full_config_refresh = function()
    log.warn('FULL CONFIG REFRESH')
    commands.configrefresh(driver,device)
  end
  local full_config_startup = function()
    log.warn(string.format('Setting up full configuration polling every %s hours.',full_config_poll_freq/3600))
    device.thread:call_on_schedule(full_config_poll_freq,full_config_refresh,'configRefresh')
  end
  log.trace(string.format('Full configuration polling will be set up in %s minutes, and will run every %s hours.',full_config_poll_offset/60,full_config_poll_freq/3600))
  device.thread:call_with_delay(full_config_poll_offset,full_config_startup,'configStartup')
  log.trace('Device initialized.')
end

local function dev_added(driver, device)
  log.debug('Device added.')
end

--- Handle changes to settings
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function infoChanged_handler(driver, device, event, args)
  log.info(device.id .. ": " .. device.device_network_id .. " > INFO CHANGED")

  if (args.old_st_store.preferences.changeProfile ~= device.preferences.changeProfile) and device.preferences.changeProfile ~= 'none' then
    local pref=device.preferences.changeProfile
    local create_device_msg = {
      profile = (pref=='config') and 'configuration-mode' or (pref:sub(1,2) .. '-' .. pref:sub(3,7) .. '-' .. pref:sub(8,8) .. '-' .. pref:sub(9,9) .. '-' .. pref:sub(10,12)),
    }
    assert (device:try_update_metadata(create_device_msg), "Failed to change device")
    log.warn('Changed to new profile. App restart required.')
  end

--[[
  if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value and preferences and preferences[id]) then
    local new_parameter_value = preferencesMap.to_numeric_value(device.preferences[id])
    device:send(Configuration:Set({parameter_number = preferences[id].parameter_number, size = preferences[id].size, configuration_value = new_parameter_value}))
  end
]]
end

--- Switch flipped in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_switch(driver,device,command)
  log.debug(string.format('%s %s flipped to %s',command.capability,command.component,command.command))
  local cmds = {}
  if config.CAP_MAP[command.component][command.capability] ~= 'poolSpaMode' then
    local instance = config.INSTANCE_KEY[config.CAP_MAP[command.component][command.capability]]
    cmds = commands.set_channel_state(instance,command.command)
  else
    cmds = commands.set_pool_spa_mode(device,command.command)
  end
  local add_cmds = commands.refresh_commands()
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	delay_send(device,cmds,1)
end

--- Heating setpoint changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_heating_setpoint(driver,device,command)
  log.debug(string.format('%s %s flipped to %s',command.capability,command.component,command.args.setpoint))
  local cmds = {}
  if config.CAP_MAP[command.component][command.capability] == 'thermostatSetpointPool' then
    cmds = commands.set_pool_setpoint(device,command.args.setpoint)
  elseif config.CAP_MAP[command.component][command.capability] == 'thermostatSetpointSpa' then
    cmds = commands.set_spa_setpoint(device,command.args.setpoint)
  end
  local add_cmds = commands.refresh_commands()
  for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	delay_send(device,cmds,1)
end

--- VSP speed changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_vsp(driver,device,command)
  log.debug(string.format('%s %s set to %s',command.capability,command.component,command.args.vspSpeed))
  local cmds = {}
  local channel = tonumber(command.args.vspSpeed)
  if channel == 0 then
    cmds = commands.set_channel_state(get.VSP_CHAN_NO(1), 'off')
  else
    cmds = commands.set_channel_state(get.VSP_CHAN_NO(channel), 'on')
  end
  local add_cmds = commands.refresh_commands()
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	delay_send(device,cmds,1)
end

--- Schedule selected in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function fetch_schedule(driver,device,command)
  local param_num = tonumber(command.args.schedule) - 100
  local friendly_name = get.CONFIG_PARAMS[param_num].friendlyname
  log.debug(string.format('Fetching parameter %s, schedule %s.',param_num,friendly_name))
  local comp = config.GET_COMP(device,'schedule')
  if comp then
    device:emit_component_event(device.profile.components[comp],config.EP_MAP['schedule'].cap({ value = command.args.schedule }))
    device:emit_component_event(device.profile.components[comp],capabilities[capdefs.scheduleTime.name].scheduleTime({ value = 'Querying schedule' }))
  end
  local cmd = commands.get_config(param_num)
  delay_send(device,cmd,1)
end

--- Schedule run time entered in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_schedule_time(driver,device,command)
  local param_num = device.state_cache.schedules[capdefs.schedule.name].schedule.value - 100
  local times = { utilities.splitTime(command.args.scheduleTime) }
  if times[1] then
    log.debug(string.format('Setting schedule %s to %s:%s-%s:%s',get.CONFIG_PARAMS[param_num].friendlyname,times[1],times[2],times[3],times[4]))
    delay_send(device,commands.set_schedule_by_param(param_num,times[1],times[2],times[3],times[4]),4)
  else
    log.debug(string.format('Erasing schedule %s',get.CONFIG_PARAMS[param_num].friendlyname))
    delay_send(device,commands.reset_schedule_by_param(param_num),2)
  end
end

--- Pool/spa config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_pool_spa_config(driver,device,command)
  local param_num = get.POOL_SPA_CONFIG
  local config_value = tonumber(command.args.poolSpaConfig)
  log.debug(string.format('Setting Pool/Spa Configuration to %s',config_value))
  local cmds = commands.set_config(param_num,1,config_value)
  commands.add_config_refresh_and_send(device,cmds)
  --[[
  local add_cmds = commands.get_config(param_num)
  for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  delay_send(device,cmds,3)
  --]]
end

--- Pump type changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_pump_type_config(driver,device,command)
  local param_num = get.OPERATION_MODE_CONFIG
  local booster_setting = device.state_cache.main[capdefs.boosterPumpConfig.name].boosterPumpConfig.value
  local cmds = {}
  if booster_setting then
    booster_setting = tonumber(booster_setting)
    local config_value1 = booster_setting
    local config_value2 = tonumber(command.args.pumpType) + ((booster_setting == 1) and 0 or 1)
    local config_value = config_value1 * 256 + config_value2
    log.debug(string.format('Setting Pump Type to %s',config_value))
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Booster configuration unknown. Refresh required before setting pump type.')
  end
  commands.add_config_refresh_and_send(device,cmds)
end

--- Booster pump config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_booster_pump_config(driver,device,command)
  local param_num = get.OPERATION_MODE_CONFIG
  local pump_setting = device.state_cache.main[capdefs.pumpTypeConfig.name].pumpType.value
  local cmds = {}
  if pump_setting then
    pump_setting = tonumber(pump_setting)
    local config_value1 = tonumber(command.args.boosterPumpConfig)
    local config_value2 = pump_setting + tonumber(command.args.boosterPumpConfig) + ((tonumber(command.args.boosterPumpConfig) == 1) and 0 or 1)
    local config_value = config_value1 * 256 + config_value2
    log.debug(string.format('Setting Booster Pump Type to %s',config_value))
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Pump Type configuration unknown. Refresh required before setting pump type.')
  end
  commands.add_config_refresh_and_send(device,cmds)
end

--- Fireman config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_fireman_config(driver,device,command)
  local param_num = get.FIREMAN_CONFIG
  local heatersafety_setting = device.state_cache.heater[capdefs.heaterSafetyConfig.name].heaterSafetyConfig.value
  local cmds = {}
  if heatersafety_setting then
    heatersafety_setting = tonumber(heatersafety_setting)
    local config_value1 = tonumber(command.args.firemanConfig) - 100
    local config_value2 = heatersafety_setting
    local config_value = config_value1 * 256 + config_value2
    log.debug(string.format('Setting Fireman/Heater Safety to %s',config_value))
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Heater safety configuration unknown. Refresh required before setting fireman.')
  end
  commands.add_config_refresh_and_send(device,cmds)
end

--- Heater safety config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_heatersafety_config(driver,device,command)
  utilities.disptable(command,'  ')
  local param_num = get.FIREMAN_CONFIG
  local fireman_setting = device.state_cache.heater[capdefs.firemanConfig.name].firemanConfig.value
  local cmds = {}
  if fireman_setting then
    fireman_setting = tonumber(fireman_setting) - 100
    local config_value1 = fireman_setting
    local config_value2 = tonumber(command.args.heaterSafetyConfig)
    local config_value = config_value1 * 256 + config_value2
    log.debug(string.format('Setting Fireman/Heater Safety to %s',config_value))
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Fireman configuration unknown. Refresh required before setting heater safety.')
  end
  commands.add_config_refresh_and_send(device,cmds)
end

--- Circuit freeze control changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_freeze_config(driver,device,command)
  log.debug("Freeze flipped")
  local curr_sw = command.command
  local curr_set = command.args.freezeControl
  log.debug(curr_sw,curr_set)
  local freeze_settings = {
    [0x01] = (curr_sw == 'setFreezeCircuitOne') and curr_set or device.state_cache.freezeControl[capdefs.circuit1FreezeControl.name].freezeControl.value,
    [0x02] = (curr_sw == 'setFreezeCircuitTwo') and curr_set or device.state_cache.freezeControl[capdefs.circuit2FreezeControl.name].freezeControl.value,
    [0x04] = (curr_sw == 'setFreezeCircuitThree') and curr_set or device.state_cache.freezeControl[capdefs.circuit3FreezeControl.name].freezeControl.value,
    [0x08] = (curr_sw == 'setFreezeCircuitFour') and curr_set or device.state_cache.freezeControl[capdefs.circuit4FreezeControl.name].freezeControl.value,
    [0x10] = (curr_sw == 'setFreezeCircuitFive') and curr_set or device.state_cache.freezeControl[capdefs.circuit5FreezeControl.name].freezeControl.value,
  }
  local config_value1 = 0
  local config_value2 = 0
  local config_value3 = 0
  local config_value4 = 0
  for value, status in pairs(freeze_settings) do
    log.debug(value,status)
    if status == 'on' then config_value2 = config_value2 + value end
  end
  local config_value = config_value1 * 256^3 + config_value2 * 256^2 + config_value3 * 256 + config_value4
  local cmds = commands.set_config(0x32,4,config_value)
  local add_cmds = commands.get_config(0x32)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  delay_send(device,cmds,1)
end

---------------------------
-- Driver template
local driver_template = {
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.REPORT] = cc_handlers.basic_report,
    },
    [cc.SWITCH_BINARY] = {
      [SwitchBinary.REPORT] = cc_handlers.switch_binary_report,
    },
    [cc.SWITCH_ALL] = {
      [SwitchAll.REPORT] = cc_handlers.switch_all_report,
    },
    [cc.SENSOR_MULTILEVEL] = {
      [SensorMultilevel.REPORT] = cc_handlers.sensor_multilevel_report,
    },
    [cc.THERMOSTAT_SETPOINT] = {
      [ThermostatSetpoint.REPORT] = cc_handlers.thermostat_setpoint_report,
      [ThermostatSetpoint.SUPPORTED_REPORT] = cc_handlers.thermostat_setpoint_supported_report,
    },
    [cc.MULTI_INSTANCE] = {
      [MultiInstance.MULTI_INSTANCE_CMD_ENCAP] = cc_handlers.multi_instance_encap,
    },
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = cc_handlers.configuration_report,
    },
    [cc.MANUFACTURER_SPECIFIC] = {
      [ManufacturerSpecific.REPORT] = cc_handlers.manufacturer_specific_report,
    },
    [cc.POWERLEVEL] = {
      [Powerlevel.REPORT] = cc_handlers.power_level_report,
    },
    [cc.CLOCK] = {
      [Clock.REPORT] = cc_handlers.clock_report,
    },
    [cc.ASSOCIATION] = {
      [Association.REPORT] = cc_handlers.association_report,
    },
    [cc.VERSION] = {
      [Version.REPORT] = cc_handlers.version_report,
      [Version.COMMAND_CLASS_REPORT] = cc_handlers.version_cc_report
    },
    [cc.MANUFACTURER_PROPRIETARY] = {
      [0x00] = cc_handlers.manufacturer_proprietary_report,
    },
  },
  supported_capabilities = {
    capabilities.temperatureMeasurement,
    capabilities.switch,
    capabilities.refresh,
    capabilities.thermostatHeatingSetpoint,
  },
  lifecycle_handlers = {
    init = dev_init,
    added = dev_added,
    infoChanged = infoChanged_handler,
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = set_switch,
      [capabilities.switch.commands.off.NAME] = set_switch,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = commands.refresh,
    },
    [capabilities.thermostatHeatingSetpoint.ID] = {
      [capabilities.thermostatHeatingSetpoint.commands.setHeatingSetpoint.NAME] = set_heating_setpoint,
    },
    [capdefs.pumpSpeed.capability.ID] = {
      [capdefs.pumpSpeed.capability.commands.setVSPSpeed.NAME] = set_vsp,
    },
    [capdefs.schedule.capability.ID] = {
      [capdefs.schedule.capability.commands.fetchSchedule.NAME] = fetch_schedule,
    },
    [capdefs.scheduleTime.capability.ID] = {
      [capdefs.scheduleTime.capability.commands.setScheduleTime.NAME] = set_schedule_time,
    },
    [capdefs.poolSpaConfig.capability.ID] = {
      [capdefs.poolSpaConfig.capability.commands.setPoolSpaConfig.NAME] = set_pool_spa_config,
    },
    [capdefs.pumpTypeConfig.capability.ID] = {
      [capdefs.pumpTypeConfig.capability.commands.setPumpType.NAME] = set_pump_type_config,
    },
    [capdefs.boosterPumpConfig.capability.ID] = {
      [capdefs.boosterPumpConfig.capability.commands.setBoosterPumpConfig.NAME] = set_booster_pump_config,
    },
    [capdefs.firemanConfig.capability.ID] = {
      [capdefs.firemanConfig.capability.commands.setFiremanConfig.NAME] = set_fireman_config,
    },
    [capdefs.heaterSafetyConfig.capability.ID] = {
      [capdefs.heaterSafetyConfig.capability.commands.setHeaterSafetyConfig.NAME] = set_heatersafety_config,
    },
    [capdefs.circuit1FreezeControl.capability.ID] = {
      [capdefs.circuit1FreezeControl.capability.commands.setFreezeCircuitOne.NAME] = set_freeze_config,
    },
    [capdefs.circuit2FreezeControl.capability.ID] = {
      [capdefs.circuit2FreezeControl.capability.commands.setFreezeCircuitTwo.NAME] = set_freeze_config,
    },
    [capdefs.circuit3FreezeControl.capability.ID] = {
      [capdefs.circuit3FreezeControl.capability.commands.setFreezeCircuitThree.NAME] = set_freeze_config,
    },
    [capdefs.circuit4FreezeControl.capability.ID] = {
      [capdefs.circuit4FreezeControl.capability.commands.setFreezeCircuitFour.NAME] = set_freeze_config,
    },
    [capdefs.circuit5FreezeControl.capability.ID] = {
      [capdefs.circuit5FreezeControl.capability.commands.setFreezeCircuitFive.NAME] = set_freeze_config,
    },
  },
  NAME = "intermatic-pe653",
  can_handle = can_handle_zwave,
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local poolcontrol = ZwaveDriver("intermatic-pe653", driver_template)
poolcontrol:run()