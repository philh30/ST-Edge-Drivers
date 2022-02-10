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

local log = require "log"
local commands = require "commands"
local throttle_send = require "throttle_send"
local get = require "get_constants"
local map = require "cap_ep_map"
local capdefs = require "capabilitydefs"
local utilities = require "utilities"

local config_cmd_handlers = {}

--- Pool/spa config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function config_cmd_handlers.set_pool_spa_config(driver,device,command)
  local param_num = get.POOL_SPA_CONFIG
  local config_value = tonumber(command.args.poolSpaConfig)
  local cmds = commands.set_config(param_num,1,config_value)
  local add_cmds = commands.get_config(param_num)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

--- Pump type changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function config_cmd_handlers.set_pump_type_config(driver,device,command)
  local param_num = get.OPERATION_MODE_CONFIG
  local booster_setting = device.state_cache.main[capdefs.boosterPumpConfig.name].boosterPumpConfig.value
  local cmds = {}
  if booster_setting then
    booster_setting = tonumber(booster_setting)
    local config_value1 = booster_setting
    local config_value2 = tonumber(command.args.pumpType) + ((booster_setting == 1) and 0 or 1)
    local config_value = config_value1 * 256 + config_value2
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Booster configuration unknown. Refresh required before setting pump type.')
  end
  local add_cmds = commands.get_config(param_num)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

--- Booster pump config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function config_cmd_handlers.set_booster_pump_config(driver,device,command)
  local param_num = get.OPERATION_MODE_CONFIG
  local pump_setting = device.state_cache.main[capdefs.pumpTypeConfig.name].pumpType.value
  local cmds = {}
  if pump_setting then
    pump_setting = tonumber(pump_setting)
    local config_value1 = tonumber(command.args.boosterPumpConfig)
    local config_value2 = pump_setting + ((tonumber(command.args.boosterPumpConfig) == 1) and 0 or 1)
    local config_value = config_value1 * 256 + config_value2
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Pump Type configuration unknown. Refresh required before setting pump type.')
  end
  local add_cmds = commands.get_config(param_num)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

--- Fireman config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function config_cmd_handlers.set_fireman_config(driver,device,command)
  local param_num = get.FIREMAN_CONFIG
  local heatersafety_setting = device.state_cache.heater[capdefs.heaterSafetyConfig.name].heaterSafetyConfig.value
  local cmds = {}
  if heatersafety_setting then
    heatersafety_setting = tonumber(heatersafety_setting)
    local config_value1 = tonumber(command.args.firemanConfig) - 100
    local config_value2 = heatersafety_setting
    local config_value = config_value1 * 256 + config_value2
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Heater safety configuration unknown. Refresh required before setting fireman.')
  end
	local add_cmds = commands.get_config(param_num)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

--- Heater safety config changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function config_cmd_handlers.set_heatersafety_config(driver,device,command)
  local param_num = get.FIREMAN_CONFIG
  local fireman_setting = device.state_cache.heater[capdefs.firemanConfig.name].firemanConfig.value
  local cmds = {}
  if fireman_setting then
    fireman_setting = tonumber(fireman_setting) - 100
    local config_value1 = fireman_setting
    local config_value2 = tonumber(command.args.heaterSafetyConfig)
    local config_value = config_value1 * 256 + config_value2
    cmds = commands.set_config(param_num,2,config_value)
  else
    log.error('Fireman configuration unknown. Refresh required before setting heater safety.')
  end
  local add_cmds = commands.get_config(param_num)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

--- Circuit freeze control changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function config_cmd_handlers.set_freeze_config(driver,device,command)
  local param_num = get.FREEZE_CONFIG
  local curr_sw = command.command
  local curr_set = command.args.freezeControl or command.args.vspFreeze or command.args.freezeTemperature or command.args.heaterFreeze or command.args.poolSpaFreezeCycle
  local freeze_settings = {
    [0x01] = (curr_sw == 'setFreezeCircuitOne') and curr_set or device.state_cache.freezeControl[capdefs.circuit1FreezeControl.name].freezeControl.value,
    [0x02] = (curr_sw == 'setFreezeCircuitTwo') and curr_set or device.state_cache.freezeControl[capdefs.circuit2FreezeControl.name].freezeControl.value,
    [0x04] = (curr_sw == 'setFreezeCircuitThree') and curr_set or device.state_cache.freezeControl[capdefs.circuit3FreezeControl.name].freezeControl.value,
    [0x08] = (curr_sw == 'setFreezeCircuitFour') and curr_set or device.state_cache.freezeControl[capdefs.circuit4FreezeControl.name].freezeControl.value,
    [0x10] = (curr_sw == 'setFreezeCircuitFive') and curr_set or device.state_cache.freezeControl[capdefs.circuit5FreezeControl.name].freezeControl.value,
  }
  local config_value1 = curr_sw == 'setFreezeTemperature' and curr_set or device.state_cache.freezeControl[capdefs.tempFreezeControl.name].freezeTemperature.value
  local config_value2 = 0
  for value, status in pairs(freeze_settings) do
    if status == 'on' then config_value2 = config_value2 + value end
  end
  local config_value3 = curr_sw == 'setVspFreeze' and curr_set or device.state_cache.freezeControl[capdefs.vspFreezeControl.name].vspFreeze.value
  local heater = (tonumber(curr_sw == 'setHeaterFreeze' and curr_set or device.state_cache.freezeControl[capdefs.heaterFreezeControl.name].heaterFreeze.value) == 0) and 0x00 or 0x80
  local poolspa = curr_sw == 'setPoolSpaFreezeCycle' and curr_set or device.state_cache.freezeControl[capdefs.poolSpaFreezeControl.name].poolSpaFreezeCycle.value
  local config_value4 = heater + poolspa
  local config_value = config_value1 * 256^3 + config_value2 * 256^2 + config_value3 * 256 + config_value4
  local cmds = commands.set_config(param_num,4,config_value)
  local add_cmds = commands.get_config(param_num)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

--- Variable Speed Pump RPM configuration changed in app
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function config_cmd_handlers.set_vsp_speed_config(driver,device,command)
  local param_map = {
    setVspSpeed = 0x20,
    setVspSpeedOne = 0x20,
    setVspSpeedTwo = 0x21,
    setVspSpeedThree = 0x22,
    setVspSpeedFour = 0x23,
    setVspSpeedMax = 0x31,
  }
  local param_num = param_map[command.command]
  local config_value = command.args.vspSpeed
  local cmds = commands.set_config(param_num,2,config_value)
  local add_cmds = commands.get_config(param_num)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
  throttle_send(device,cmds)
end

return config_cmd_handlers