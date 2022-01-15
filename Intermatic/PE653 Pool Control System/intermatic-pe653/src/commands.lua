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
local delay_send = require "delay_send"

local commands = {}

function commands.refresh_commands()
	local cmds = {}
	local cmd = {}
	local cmdclass = 0x91
	local cmdid = 0x00
	cmd = zw.Command(0x91, 0x00, '\x05\x40\x01\x02\x87\x03\x01')
	cmd.err = nil
	table.insert(cmds, cmd)
	cmd = zw.Command(0x91, 0x00, '\x05\x40\x01\x01\x83\x01\x01')
	cmd.err = nil
	table.insert(cmds, cmd)
-- try 91 00 05 41 01 01 00
--[[
	cmd = zw.Command(0x91, 0x00, '\x05\x41\x01\x01\x00')
	cmd.err = nil
	table.insert(cmds, cmd)
--]]
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
	delay_send(device,cmds,1)
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
		Configuration:Get({ parameter_number = 0x01 }), -- Operation Mode
		Configuration:Get({ parameter_number = 0x02 }), -- Fireman Timeout
		Configuration:Get({ parameter_number = 0x03 }), -- Temp Offsets
		Configuration:Get({ parameter_number = get.POOL_SPA_CONFIG }),
		ThermostatSetpoint:Get({ setpoint_type = get.POOL_SETPOINTTYPE }),
		ThermostatSetpoint:Get({ setpoint_type = get.SPA_SETPOINTTYPE }),
		Configuration:Get({ parameter_number = 0x20}),
		Configuration:Get({ parameter_number = 0x21}),
		Configuration:Get({ parameter_number = 0x22}),
		Configuration:Get({ parameter_number = 0x23}),
		Configuration:Get({ parameter_number = 0x31}),
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
		Version:Get({}),
		ManufacturerSpecific:Get({}),
		Configuration:Get({ parameter_number = 0x01 }), -- Operation Mode
		Configuration:Get({ parameter_number = 0x02 }), -- Fireman Timeout
		Configuration:Get({ parameter_number = 0x03 }), -- Temp Offsets
		Configuration:Get({ parameter_number = 0x32 }), -- Freeze Control
		Configuration:Get({ parameter_number = get.POOL_SPA_CONFIG }),
	}
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	local add_cmds = commands.set_clock(device)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	delay_send(device,cmds,1)
end

--- Refresh command
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function commands.configrefresh(driver,device)
	log.debug("~~~~~~~~~~~~~~~~~~~~ Config Refresh Command ~~~~~~~~~~~~~~~~~~~~")
	local cmds = {
		Version:Get({}),
		ManufacturerSpecific:Get({}),
		Configuration:Get({ parameter_number = 0x01 }), -- Operation Mode
		Configuration:Get({ parameter_number = 0x02 }), -- Fireman Timeout
		Configuration:Get({ parameter_number = 0x03 }), -- Temp Offsets
		Configuration:Get({ parameter_number = get.POOL_SPA_CONFIG }),
	}
	local add_cmds = commands.set_clock(device)
	for _, cmd in ipairs (add_cmds) do
		table.insert(cmds,cmd)
	end
	delay_send(device,cmds,1)
end

function commands.schedulerefresh(driver,device)
	local cmds = commands.get_all_schedules()
	delay_send(device,cmds,60)
end

---------------------------------------------LIGHTS---------------------------------------------

--[[

/** Light Color */
private List setLightColorInternal(col) {
	log("DEBUG", "+++++ setLightColorInternal ${col}")
	def cmds = []
	sendEvent(name: "lightColor", value: "${col}", isStateChange: true, displayed: true, descriptionText: "Color set to ${col}")
	getColorChgCmds("$col")
}

private List getColorChgCmds(colNo=0) {
	def cmds = []
	int blinkCnt = 1
	def col = colNo==0 ? device.currentValue("lightColor") : colNo
	if (col) blinkCnt = col.toInteger()
	if (blinkCnt > 14) blinkCnt = 14;
	if (state.lightCircuitsList) {
		cmds.addAll(blink(state.lightCircuitsList, blinkCnt))
	}
	cmds
}

// Return a list of the Light Circuits selected to have color set
def List getLightCircuits() {
	def lightCircuits = []
	if (C1ColorEnabled == "1") {lightCircuits << 1}
	if (C2ColorEnabled == "1") {lightCircuits << 2}
	if (C3ColorEnabled == "1") {lightCircuits << 3}
	if (C4ColorEnabled == "1") {lightCircuits << 4}
	if (C5ColorEnabled == "1") {lightCircuits << 5}
	// log("TRACE", "lightCircuits=${lightCircuits}  C3ColorEnabled=${C3ColorEnabled}")
	lightCircuits
}

// Alternately turn a switch off then on a fixed number of times. Used to control the color of Pentair pool lights.
private def blink(List switches, int cnt) {
	log("DEBUG", "+++++ blink switches=${switches} cnt=${cnt}")
	def cmds = []
	def dly = MIN_DELAY
	for (int i=1; i<=cnt; i++) {
		switches.each { sw ->
			if (cmds) {
				cmds << "delay ${dly}"
			}
			cmds.addAll(setChanState(sw, 0))
			dly = MIN_DELAY
		}
		dly = "${DELAY}"
		switches.each { sw ->
			cmds << "delay ${dly}"
			cmds.addAll(setChanState(sw, 0xFF))
			dly = MIN_DELAY
		}
		dly = "${DELAY}"
	}
	log("TRACE", "blink() cmds=${cmds}")
	cmds
}

]]

---------------------------------------------CONFIG---------------------------------------------

--- @param param integer
--- @param size integer
--- @param config_value integer
function commands.set_config(param,size,config_value)
	config_value = ((config_value >= (256^size)/2) and (config_value < 256^size)) and (config_value-256^size) or config_value
	return { Configuration:Set({ parameter_number = param, size = size, configuration_value = config_value }) }
end

--- @param param integer
function commands.get_config(param)
	return { Configuration:Get({ parameter_number = param }) }
end

function commands.get_clock()
	return {
		Clock:Get({})
	}
end

--[[
--- @param rpm1 integer
--- @param rpm2 integer
--- @param rpm3 integer
--- @param rpm4 integer
--- @param rpmMax integer
function commands.set_vsp_speeds(rpm1, rpm2, rpm3, rpm4, rpmMax)
	return {
		Configuration:Set({ parameter_number = get.VSP_RPM_SCHED_PARAM(1), size = 2, configuration_value = rpm1 }),
		Configuration:Set({ parameter_number = get.VSP_RPM_SCHED_PARAM(2), size = 2, configuration_value = rpm2 }),
		Configuration:Set({ parameter_number = get.VSP_RPM_SCHED_PARAM(3), size = 2, configuration_value = rpm3 }),
		Configuration:Set({ parameter_number = get.VSP_RPM_SCHED_PARAM(4), size = 2, configuration_value = rpm4 }),
		Configuration:Set({ parameter_number = get.VSP_RPMMAX_SCHED_PARAM, size = 2, configuration_value = rpmMax }),
	}
end
--]]

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
		Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value }),
		Configuration:Get({ parameter_number = param }),
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
		Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value }),
		Configuration:Get({ parameter_number = param }),
	}
end

--- @param endpoint integer
--- @param sched integer
function commands.reset_schedule(endpoint,sched)
	local param = get.ENDPOINT_SCHEDULES[endpoint][sched]
	local config_value = -1
	return {
		Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value }),
		Configuration:Get({ parameter_number = param }),
	}
end

--- @param param integer
function commands.reset_schedule_by_param(param)
	local config_value = -1
	return {
		Configuration:Set({ parameter_number = param, size = 4, configuration_value = config_value }),
		Configuration:Get({ parameter_number = param }),
	}
end

--- @param endpoint integer
function commands.get_schedules_endpoint(endpoint)
	return {
		Configuration:Get({ parameter_number = get.ENDPOINT_SCHEDULES[endpoint][1] }),
		Configuration:Get({ parameter_number = get.ENDPOINT_SCHEDULES[endpoint][2] }),
		Configuration:Get({ parameter_number = get.ENDPOINT_SCHEDULES[endpoint][3] }),
	}
end

function commands.get_all_schedules()
	local cmds = {}
	for x,scheds in pairs(get.ENDPOINT_SCHEDULES) do
		for y,sched in ipairs(scheds) do
			table.insert(cmds,Configuration:Get({ parameter_number = sched }))
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
		Clock:Set({ weekday = 0, hour = now_hour, minute = now.min }), -- PE653 ignores if weekday is other than 0x00
	}
end

---------------------------------------------TEMPERATURES---------------------------------------------

--- @param degrees integer
--- @param setpoint_type integer
function commands.set_pool_or_spa_setpoint(device, degrees, setpoint_type)
	local device_scale = device.preferences['setpointScale'] and tonumber(device.preferences['setpointScale']) or 0
	return {
		ThermostatSetpoint:Set({ precision=0, size = 1, scale = device_scale, setpoint_type = setpoint_type, value = degrees }),
		ThermostatSetpoint:Get({ setpoint_type = setpoint_type })
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
		ThermostatSetpoint:Get({ setpoint_type = setpoint_type })
	}
end

function commands.get_water_temp()
	return { SensorMultilevel:Get() }
end

function commands.toggle_pool_spa_mode(_,device,command)
	local cmds = {}
	cmds = commands.set_pool_spa_mode(command.args.value)
	delay_send(device,cmds,1)
end

---------------------------------------------POOL/SPA MODE---------------------------------------------

function commands.set_pool_mode(device)
	return commands.set_pool_spa_mode(device,'off')
end

function commands.set_spa_mode(device)
	return commands.set_pool_spa_mode(device,'on')
end

--- @param val string
function commands.set_pool_spa_mode(device,val)
	local cmd = commands.set_channel_state(get.POOL_SPA_CHAN(device),val)
	table.insert(cmd,commands.get_channel_state(get.POOL_SPA_CHAN(device)))
	return cmd
end

---------------------------------------------SWITCHES---------------------------------------------

--- @param device st.zwave.Device
function commands.on(_, device ,_)
	local cmds = {
		Basic:Set({ value = 0xFF }),
		Basic:Get({}),
	}
	delay_send(device, cmds, 1)
end

--- @param device st.zwave.Device
function commands.off(_, device, _)
	local cmds = {
		Basic:Set({ value = 0x00 }),
		Basic:Get({}),
	}
	delay_send(device, cmds, 1)
end

--- @param ch integer
function commands.get_channel_state(ch)
	return { MultiInstance:MultiInstanceCmdEncap({ instance = ch, command_class = 0x25, command = 0x02 }) }
end

--- @param ch integer
--- @param on string
function commands.set_channel_state(ch, on)
	return { MultiInstance:MultiInstanceCmdEncap({ instance = ch, command_class = 0x25, command = 0x01, parameter = ( (on == 'on') and '\xFF' or '\x00' ) }) }
end

return commands