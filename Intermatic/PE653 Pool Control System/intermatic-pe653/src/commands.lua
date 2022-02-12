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
local socket = require "cosock.socket"
local utilities = require "utilities"
local get = require "get_constants"
local throttle_send = require "throttle_send"

local commands = {}

function commands.refresh_commands()
	local cmds = {}
	local cmd = {}
	local cmdclass = 0x91
	local cmdid = 0x00
	cmd = zw.Command(0x91, 0x00, '\x05\x40\x01\x02\x87\x03\x01')
	cmd.err = nil
	table.insert(cmds, { msg = cmd })
	cmd = zw.Command(0x91, 0x00, '\x05\x40\x01\x01\x83\x01\x01')
	cmd.err = nil
	table.insert(cmds, { msg = cmd })
	return cmds
end

--- Append refresh commands before sending z-wave commands
---
--- @param device st.zwave.Device
function commands.add_refresh_and_send(device,cmds)
	local add_cmds = commands.refresh_commands()
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	throttle_send(device,cmds)
end

--- Refresh command
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function commands.refresh(driver,device)
	log.debug("~~~~~~~~~~~~~~~~~~~~ Refresh Command ~~~~~~~~~~~~~~~~~~~~")
	local cmds = {
		--Version:Get({}),
		--ManufacturerSpecific:Get({}),
		{ msg = Configuration:Get({ parameter_number = 0x01 })}, -- Operation Mode
		{ msg = Configuration:Get({ parameter_number = 0x02 })}, -- Fireman Timeout
		{ msg = Configuration:Get({ parameter_number = 0x03 })}, -- Temp Offsets
		{ msg = Configuration:Get({ parameter_number = 0x32 })}, -- Freeze Control
		{ msg = Configuration:Get({ parameter_number = get.POOL_SPA_CONFIG })},
		{ msg = ThermostatSetpoint:Get({ setpoint_type = get.POOL_SETPOINTTYPE })},
		{ msg = ThermostatSetpoint:Get({ setpoint_type = get.SPA_SETPOINTTYPE })},
		{ msg = Configuration:Get({ parameter_number = 0x20})},
		{ msg = Configuration:Get({ parameter_number = 0x21})},
		{ msg = Configuration:Get({ parameter_number = 0x22})},
		{ msg = Configuration:Get({ parameter_number = 0x23})},
		{ msg = Configuration:Get({ parameter_number = 0x31})},
		{ msg = Configuration:Get({ parameter_number = 0x32})},
	}
	--local add_cmds = commands.set_clock(device)
	--for _, cmd in ipairs (add_cmds) do
	--	table.insert(cmds,cmd)
	--end
	--add_cmds = commands.get_all_schedules()
	--for _, cmd in ipairs (add_cmds) do
	--	table.insert(cmds,cmd)
	--end
	commands.add_refresh_and_send(device,cmds)
end

--- Append config refresh commands before sending z-wave commands
---
--- @param device st.zwave.Device
function commands.add_config_refresh_and_send(device,cmds)
	local add_cmds = {
		{ msg = Version:Get({})},
		{ msg = ManufacturerSpecific:Get({})},
		{ msg = Configuration:Get({ parameter_number = 0x01 })}, -- Operation Mode
		{ msg = Configuration:Get({ parameter_number = 0x02 })}, -- Fireman Timeout
		{ msg = Configuration:Get({ parameter_number = 0x03 })}, -- Temp Offsets
		{ msg = Configuration:Get({ parameter_number = 0x32 })}, -- Freeze Control
		{ msg = Configuration:Get({ parameter_number = get.POOL_SPA_CONFIG })},
	}
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	local add_cmds = commands.set_clock(device)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	throttle_send(device,cmds)
end

--- Refresh command
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function commands.configrefresh(driver,device)
	log.debug("~~~~~~~~~~~~~~~~~~~~ Config Refresh Command ~~~~~~~~~~~~~~~~~~~~")
	local cmds = {
		{ msg = Version:Get({})},
		{ msg = ManufacturerSpecific:Get({})},
		{ msg = Configuration:Get({ parameter_number = 0x01 })}, -- Operation Mode
		{ msg = Configuration:Get({ parameter_number = 0x02 })}, -- Fireman Timeout
		{ msg = Configuration:Get({ parameter_number = 0x03 })}, -- Temp Offsets
		{ msg = Configuration:Get({ parameter_number = get.POOL_SPA_CONFIG })},
	}
	local add_cmds = commands.set_clock(device)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	throttle_send(device,cmds)
end

function commands.schedulerefresh(driver,device)
	local cmds = commands.get_all_schedules()
	throttle_send(device,cmds)
end

---------------------------------------------CONFIG---------------------------------------------

--- @param param integer
--- @param size integer
--- @param config_value integer
function commands.set_config(param,size,config_value)
	config_value = ((config_value >= (256^size)/2) and (config_value < 256^size)) and (config_value-256^size) or config_value
	return {{ msg = Configuration:Set({ parameter_number = param, size = size, configuration_value = config_value }) }}
end

--- @param param integer
--- @param size integer
--- @param config_value string
function commands.set_config_string(param,size,config_value)
	return {{ msg = Configuration:Set({ parameter_number = param, size = size, configuration_value = config_value }) }}
end

--- @param param integer
function commands.get_config(param)
	return {{ msg = Configuration:Get({ parameter_number = param }) }}
end

function commands.get_clock()
	return {
		{ msg = Clock:Get({}) }
	}
end

---------------------------------------------SCHEDULES---------------------------------------------

--- @param endpoint integer
--- @param sched integer
--- @param start_hour integer
--- @param start_min integer
--- @param stop_hour integer
--- @param stop_min integer
function commands.set_schedule(endpoint, sched, start_hour, start_min, stop_hour, stop_min)
	local param = get.ENDPOINT_SCHEDULES[endpoint][sched]
	local start = start_hour * 60 + start_min
	local stop = stop_hour * 60 + stop_min
	local config_value = (start%256)*256^3 + math.floor(start/256)*256^2 + (stop%256)*256^1 + math.floor(stop/256)*256^0
	config_value = (config_value >= 256^4/2) and config_value-256^4 or config_value
	return {
		{ msg = Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value })},
		{ msg = Configuration:Get({ parameter_number = param })},
	}
end

--- @param param integer
--- @param start_hour integer
--- @param start_min integer
--- @param stop_hour integer
--- @param stop_min integer
function commands.set_schedule_by_param(param, start_hour, start_min, stop_hour, stop_min)
	local start = start_hour * 60 + start_min
	local stop = stop_hour * 60 + stop_min
	local config_value = (start%256)*256^3 + math.floor(start/256)*256^2 + (stop%256)*256^1 + math.floor(stop/256)*256^0
	config_value = (config_value > 256^4/2) and config_value-256^4 or config_value
	return {
		{ msg = Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value })},
		{ msg = Configuration:Get({ parameter_number = param })},
	}
end

--- @param endpoint integer
--- @param sched integer
function commands.reset_schedule(endpoint,sched)
	local param = get.ENDPOINT_SCHEDULES[endpoint][sched]
	local config_value = -1
	return {
		{ msg = Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value })},
		{ msg = Configuration:Get({ parameter_number = param })},
	}
end

--- @param param integer
function commands.reset_schedule_by_param(param)
	local config_value = -1
	return {
		{ msg = Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value })},
		{ msg = Configuration:Get({ parameter_number = param })},
	}
end

--- @param endpoint integer
function commands.get_schedules_endpoint(endpoint)
	return {
		{ msg = Configuration:Get({ parameter_number = get.ENDPOINT_SCHEDULES[endpoint][1] })},
		{ msg = Configuration:Get({ parameter_number = get.ENDPOINT_SCHEDULES[endpoint][2] })},
		{ msg = Configuration:Get({ parameter_number = get.ENDPOINT_SCHEDULES[endpoint][3] })},
	}
end

function commands.get_all_schedules()
	local cmds = {}
	for x,scheds in pairs(get.ENDPOINT_SCHEDULES) do
		for y,sched in ipairs(scheds) do
			table.insert(cmds,{ msg = Configuration:Get({ parameter_number = sched }), delay = 60})
		end
	end
	return cmds
end

---------------------------------------------CLOCK---------------------------------------------

function commands.set_clock(device) -- Time zone offset from UTC set in preferences since local time is not available to driver.
	local now = os.date('*t')
	local offset = (device.preferences['timezoneUTC'] or 0) + (device.preferences['timezoneDST'] or 0)
	local now_hour = (now.hour + offset > 0) and ((now.hour + offset < 24) and (now.hour + offset) or (now.hour - 24 + offset)) or (now.hour + 24 + offset)
	return {
		{ msg = Clock:Set({ weekday = 0, hour = now_hour, minute = now.min })}, -- PE653 ignores if weekday is other than 0x00
	}
end

---------------------------------------------TEMPERATURES---------------------------------------------

--- @param degrees integer
--- @param setpoint_type integer
function commands.set_pool_or_spa_setpoint(device, degrees, setpoint_type)
	local device_scale = device.preferences['setpointScale'] and tonumber(device.preferences['setpointScale']) or 0
	return {
		{ msg = ThermostatSetpoint:Set({ precision=0, size = 1, scale = device_scale, setpoint_type = setpoint_type, value = degrees })},
		{ msg = ThermostatSetpoint:Get({ setpoint_type = setpoint_type })}
	}
end

--- @param degrees integer
function commands.set_pool_setpoint(device, degrees)
	return commands.set_pool_or_spa_setpoint(device, degrees, get.POOL_SETPOINTTYPE)
end

--- @param degrees integer
function commands.set_spa_setpoint(device, degrees)
	return commands.set_pool_or_spa_setpoint(device, degrees, get.SPA_SETPOINTTYPE)
end

--- @param setpoint_type integer
function commands.get_pool_or_spa_setpoint(setpoint_type)
	return {
		{ msg = ThermostatSetpoint:Get({ setpoint_type = setpoint_type })}
	}
end

function commands.get_water_temp()
	return {{ msg = SensorMultilevel:Get() }}
end

function commands.toggle_pool_spa_mode(_,device,command)
	local cmds = {}
	cmds = commands.set_pool_spa_mode(command.args.value)
	throttle_send(device,cmds)
end

---------------------------------------------POOL/SPA MODE---------------------------------------------

function commands.set_pool_mode(device)
	return commands.set_pool_spa_mode(device,'off')
end

function commands.set_spa_mode(device)
	return commands.set_pool_spa_mode(device,'on')
end

--- @param device st.zwave.Device
--- @param val string
function commands.set_pool_spa_mode(device,val)
	local pool_spa_channel = get.POOL_SPA_CHAN(device)
	local cmds = commands.set_channel_state(pool_spa_channel,val)
	local add_cmds = commands.get_channel_state(pool_spa_channel)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	return cmds
end

---------------------------------------------SWITCHES---------------------------------------------

--- @param device st.zwave.Device
function commands.on(_, device ,_)
	local cmds = {
		{ msg = Basic:Set({ value = 0xFF }) },
		{ msg = Basic:Get({}) },
	}
	throttle_send(device, cmds)
end

--- @param device st.zwave.Device
function commands.off(_, device, _)
	local cmds = {
		{ msg = Basic:Set({ value = 0x00 }) },
		{ msg = Basic:Get({}) },
	}
	throttle_send(device, cmds)
end

--- @param ch integer
function commands.get_channel_state(ch)
	return {{ msg = MultiInstance:MultiInstanceCmdEncap({ instance = ch, command_class = 0x25, command = 0x02 }) }}
end

--- @param ch integer
--- @param on string
function commands.set_channel_state(ch, on)
	return {{ msg = MultiInstance:MultiInstanceCmdEncap({ instance = ch, command_class = 0x25, command = 0x01, parameter = ( (on == 'on') and '\xFF' or '\x00' ) }) }}
end

return commands