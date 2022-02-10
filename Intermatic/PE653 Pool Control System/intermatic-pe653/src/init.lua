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
local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local cc = require "st.zwave.CommandClass"
local log = require "log"
local capdefs = require "capabilitydefs"
local config_cmd_handlers = require "config_cmd_handlers"

local utilities = require "utilities"
local cc_handlers = require "cc_handlers"
local commands = require "commands"
local throttle_send = require "throttle_send"
local get = require "get_constants"
local map = require "cap_ep_map"

local ZWAVE_FINGERPRINTS = {
  {mfr = 0x0005, prod = 0x5045, model = 0x0653}, -- PE653
}

--local CONFIG_PARAMS = {}

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
        if map.CAP_MAP[component.id] then
          if map.CAP_MAP[component.id][capability.id] then 
            log.trace(utilities.pad(map.CAP_MAP[component.id][capability.id],25), '=', component.id .. '|' .. capability.id)
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

  if args.old_st_store.preferences.mode ~= device.preferences.mode then
    local mode = device.preferences.mode
    local pref=device.preferences.changeProfile
    local create_device_msg = {
      profile = (mode=='configuration') and 'configuration-mode' or (pref:sub(1,2) .. '-' .. pref:sub(3,7) .. '-' .. pref:sub(8,8) .. '-' .. pref:sub(9,9) .. '-' .. pref:sub(10,12)),
    }
    assert (device:try_update_metadata(create_device_msg), "Failed to change device")
    log.warn('Changed to new profile. App restart required.')
  end

  local water = (device.preferences.offsetWater < 0) and (256 + device.preferences.offsetWater) or device.preferences.offsetWater
  local air = (device.preferences.offsetAir < 0) and (256 + device.preferences.offsetAir) or device.preferences.offsetAir
  local solar = (device.preferences.offsetSolar < 0) and (256 + device.preferences.offsetSolar) or device.preferences.offsetSolar
  local cmds = commands.set_config(3,4,water*256^3+air*256^2+solar*256)
  local add_cmds = commands.get_config(3)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

--- Switch flipped in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_switch(driver,device,command)
  log.debug(string.format('%s %s flipped to %s',command.capability,command.component,command.command))
  local cmds = {}
  if map.CAP_MAP[command.component][command.capability] ~= 'poolSpaMode' then
    local instance = map.INSTANCE_KEY[map.CAP_MAP[command.component][command.capability]]
    cmds = commands.set_channel_state(instance,command.command)
  else
    cmds = commands.set_pool_spa_mode(device,command.command)
  end
  local add_cmds = commands.refresh_commands()
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	throttle_send(device,cmds)
end

--- Heating setpoint changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_heating_setpoint(driver,device,command)
  log.debug(string.format('%s %s flipped to %s',command.capability,command.component,command.args.setpoint))
  local cmds = {}
  if map.CAP_MAP[command.component][command.capability] == 'thermostatSetpointPool' then
    cmds = commands.set_pool_setpoint(device,command.args.setpoint)
  elseif map.CAP_MAP[command.component][command.capability] == 'thermostatSetpointSpa' then
    cmds = commands.set_spa_setpoint(device,command.args.setpoint)
  end
  local add_cmds = commands.refresh_commands()
  for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	throttle_send(device,cmds)
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
	throttle_send(device,cmds)
end

--- Schedule selected in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function fetch_schedule(driver,device,command)
  local param_num = tonumber(command.args.schedule) - 100
  local friendly_name = get.CONFIG_PARAMS[param_num].friendlyname
  log.debug(string.format('Fetching parameter %s, schedule %s.',param_num,friendly_name))
  local comp = map.GET_COMP(device,'schedule')
  if comp then
    device:emit_component_event(device.profile.components[comp],map.EP_MAP['schedule'].cap({ value = command.args.schedule }))
    device:emit_component_event(device.profile.components[comp],capabilities[capdefs.scheduleTime.name].scheduleTime({ value = 'Querying schedule' }))
  end
  local cmd = commands.get_config(param_num)
  throttle_send(device,cmd)
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
    throttle_send(device,commands.set_schedule_by_param(param_num,times[1],times[2],times[3],times[4]),4)
  else
    log.debug(string.format('Erasing schedule %s',get.CONFIG_PARAMS[param_num].friendlyname))
    throttle_send(device,commands.reset_schedule_by_param(param_num),2)
  end
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
    capdefs.pumpSpeed.capability,
    capdefs.schedule.capability,
    capdefs.scheduleTime.capability,
    capdefs.poolSpaConfig.capability,
    capdefs.pumpTypeConfig.capability,
    capdefs.boosterPumpConfig.capability,
    capdefs.firemanConfig.capability,
    capdefs.heaterSafetyConfig.capability,
    capdefs.circuit1FreezeControl.capability,
    capdefs.circuit2FreezeControl.capability,
    capdefs.circuit3FreezeControl.capability,
    capdefs.circuit4FreezeControl.capability,
    capdefs.circuit5FreezeControl.capability,
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
      [capdefs.poolSpaConfig.capability.commands.setPoolSpaConfig.NAME] = config_cmd_handlers.set_pool_spa_config,
    },
    [capdefs.pumpTypeConfig.capability.ID] = {
      [capdefs.pumpTypeConfig.capability.commands.setPumpType.NAME] = config_cmd_handlers.set_pump_type_config,
    },
    [capdefs.boosterPumpConfig.capability.ID] = {
      [capdefs.boosterPumpConfig.capability.commands.setBoosterPumpConfig.NAME] = config_cmd_handlers.set_booster_pump_config,
    },
    [capdefs.firemanConfig.capability.ID] = {
      [capdefs.firemanConfig.capability.commands.setFiremanConfig.NAME] = config_cmd_handlers.set_fireman_config,
    },
    [capdefs.heaterSafetyConfig.capability.ID] = {
      [capdefs.heaterSafetyConfig.capability.commands.setHeaterSafetyConfig.NAME] = config_cmd_handlers.set_heatersafety_config,
    },
    [capdefs.vspSpeed1.capability.ID] = {
      [capdefs.vspSpeed1.capability.commands.setVspSpeedOne.NAME] = config_cmd_handlers.set_vsp_speed_config,
    },
    [capdefs.vspSpeed2.capability.ID] = {
      [capdefs.vspSpeed2.capability.commands.setVspSpeedTwo.NAME] = config_cmd_handlers.set_vsp_speed_config,
    },
    [capdefs.vspSpeed3.capability.ID] = {
      [capdefs.vspSpeed3.capability.commands.setVspSpeedThree.NAME] = config_cmd_handlers.set_vsp_speed_config,
    },
    [capdefs.vspSpeed4.capability.ID] = {
      [capdefs.vspSpeed4.capability.commands.setVspSpeedFour.NAME] = config_cmd_handlers.set_vsp_speed_config,
    },
    [capdefs.vspSpeedMax.capability.ID] = {
      [capdefs.vspSpeedMax.capability.commands.setVspSpeedMax.NAME] = config_cmd_handlers.set_vsp_speed_config,
    },
    [capdefs.tempFreezeControl.capability.ID] = {
      [capdefs.tempFreezeControl.capability.commands.setFreezeTemperature.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.circuit1FreezeControl.capability.ID] = {
      [capdefs.circuit1FreezeControl.capability.commands.setFreezeCircuitOne.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.circuit2FreezeControl.capability.ID] = {
      [capdefs.circuit2FreezeControl.capability.commands.setFreezeCircuitTwo.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.circuit3FreezeControl.capability.ID] = {
      [capdefs.circuit3FreezeControl.capability.commands.setFreezeCircuitThree.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.circuit4FreezeControl.capability.ID] = {
      [capdefs.circuit4FreezeControl.capability.commands.setFreezeCircuitFour.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.circuit5FreezeControl.capability.ID] = {
      [capdefs.circuit5FreezeControl.capability.commands.setFreezeCircuitFive.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.vspFreezeControl.capability.ID] = {
      [capdefs.vspFreezeControl.capability.commands.setVspFreeze.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.heaterFreezeControl.capability.ID] = {
      [capdefs.heaterFreezeControl.capability.commands.setHeaterFreeze.NAME] = config_cmd_handlers.set_freeze_config,
    },
    [capdefs.poolSpaFreezeControl.capability.ID] = {
      [capdefs.poolSpaFreezeControl.capability.commands.setPoolSpaFreezeCycle.NAME] = config_cmd_handlers.set_freeze_config,
    },
  },
  NAME = "intermatic-pe653",
  can_handle = can_handle_zwave,
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local poolcontrol = ZwaveDriver("intermatic-pe653", driver_template)
poolcontrol:run()