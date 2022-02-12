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

local get = require "get_constants"
local evt = require "events"
local map = require "cap_ep_map"
local active = require "active_mode"

local man_prop = {}

--- Handler for ManufacturerProprietary:Report 0x84 Event
---
--- @param device st.zwave.Device
--- @param payload st.zwave.Command.payload
function man_prop.process84Event(device,payload)
	local vspmap = { [0] = 0, [1] = 1, [2] = 2, [4] = 3, [8] = 4 }
	local vspSpeed = vspmap[payload[get.VSP_SPEED_84(device)]]
	local vspRPM = (vspSpeed == 0) and 0 or (device:get_field("VSP_SPD_SETTING_" .. vspSpeed) or 0)
	local poolSpa = get.EXPANSION_5043(device) and (((payload[get.POOL_SPA_MODE_84(device)] & 0x01) == 0) and 'on' or 'off') or (((payload[get.SWITCHES_84(device)] & 0x08) ~= 0) and 'on' or 'off')
	local pool_comp = map.GET_COMP(device,'thermostatSetpointPool')
	local spa_comp = map.GET_COMP(device,'thermostatSetpointSpa')
	local pool_setpoint = pool_comp and device:get_latest_state(pool_comp,'thermostatHeatingSetpoint','heatingSetpoint') or 0
	local spa_setpoint = spa_comp and device:get_latest_state(spa_comp,'thermostatHeatingSetpoint','heatingSetpoint') or 0
	local switch1 = ((payload[get.SWITCHES_84(device)] & 1) ~= 0) and 'on' or 'off'
	local switch2 = ((payload[get.SWITCHES_84(device)] & 2) ~= 0) and 'on' or 'off'
	local cooldown = (payload[get.COOLDOWN_ACTIVE_84(device)] ~= 0) and 'on' or 'off'
	local cooldownTimer = {raw=payload[get.COOLDOWN_TIMER_L_84(device)] * 256 + payload[get.COOLDOWN_TIMER_S_84(device)]}
	cooldownTimer.minutes = math.floor(cooldownTimer.raw / 60)
	cooldownTimer.seconds = cooldownTimer.raw - cooldownTimer.minutes * 60
	cooldownTimer.formatted = cooldownTimer.minutes and (cooldownTimer.minutes .. ':' .. ((cooldownTimer.seconds < 10) and '0' or '') .. cooldownTimer.seconds) or nil
	local update = {
		{ type = 'firmwareVersion', state = payload[get.VER_MAIN_MAJOR_84(device)] .. '.' .. payload[get.VER_MAIN_MINOR_84(device)]},
		{ type = 'switch1', state = ((payload[get.SWITCHES_84(device)] & 1) ~= 0) and 'on' or 'off'},
		{ type = 'switch2', state = ((payload[get.SWITCHES_84(device)] & 2) ~= 0) and 'on' or 'off'},
		{ type = 'switch3', state = ((payload[get.SWITCHES_84(device)] & 4) ~= 0) and 'on' or 'off'},
		{ type = 'switch4', state = ((payload[get.SWITCHES_84(device)] & 8) ~= 0) and 'on' or 'off'},
		{ type = 'switch5', state = ((payload[get.SWITCHES_84(device)] & 16) ~= 0) and 'on' or 'off'},
		{ type = 'vsp1', state = ((payload[get.VSP_SPEED_84(device)] & 1) ~= 0) and 'on' or 'off'},
		{ type = 'vsp2', state = ((payload[get.VSP_SPEED_84(device)] & 2) ~= 0) and 'on' or 'off'},
		{ type = 'vsp3', state = ((payload[get.VSP_SPEED_84(device)] & 4) ~= 0) and 'on' or 'off'},
		{ type = 'vsp4', state = ((payload[get.VSP_SPEED_84(device)] & 8) ~= 0) and 'on' or 'off'},
		{ type = 'vspSpeed', state = vspSpeed},
		{ type = 'vspRPM', state = vspRPM},
		{ type = 'poolSpaMode', state = poolSpa},
		active.mode(device,{ poolSpa = (poolSpa == 'on') and 'spa' or 'pool', switch1 = switch1, switch2 = switch2, vsp = vspSpeed, cooldown = cooldown }),
		{ type = 'activeSetpoint', state = (poolSpa == 'off' and pool_setpoint or spa_setpoint) },
		{ type = 'heater', state = (not get.EXPANSION_5043(device)) and (((payload[get.SWITCHES_84(device)] & 0x10) ~= 0) and 'on' or 'off') or nil},
		{ type = 'heaterCooldown', state = cooldown},
		{ type = 'heaterCooldownTimer', state = cooldownTimer.formatted},
		{ type = 'waterTemp', state = (payload[get.WATER_TEMP_84(device)] >= 0) and payload[get.WATER_TEMP_84(device)] or payload[get.WATER_TEMP_84(device)] + 255},
		{ type = 'airTemp', state = (payload[get.AIR_TEMP_FREEZE_84(device)] >= 0) and payload[get.AIR_TEMP_FREEZE_84(device)] or payload[get.AIR_TEMP_FREEZE_84(device)] + 255},
		{ type = 'solarTemp', state = (payload[get.AIR_TEMP_SOLAR_84(device)] >= 0) and payload[get.AIR_TEMP_SOLAR_84(device)] or payload[get.AIR_TEMP_SOLAR_84(device)] + 255},
		{ type = 'clock', state = string.format('%02d',payload[get.CLOCK_HOUR_84(device)]) .. ':' .. string.format('%02d',payload[get.CLOCK_MINUTE_84(device)])},
	}
	evt.post_event(device,0x91,0x84,update)
end

--- Handler for ManufacturerProprietary:Report 0x87 Event
---
--- @param device st.zwave.Device
--- @param payload st.zwave.Command.payload
function man_prop.process87Event(device,payload)
	local update = {
		{ type = 'expansionVersion', state = payload[get.VER_EXP_MAJOR_87] .. '.' .. payload[get.VER_EXP_MINOR_87]},
		{ type = 'heater', state = get.EXPANSION_5043(device) and (((payload[get.HEATER_87] & 0x04) ~= 0) and 'on' or 'off') or nil},
	}
	evt.post_event(device,0x91,0x87,update)
end

return man_prop