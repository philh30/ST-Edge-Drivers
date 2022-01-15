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
local get = require "get_constants"
local utilities = require "utilities"
local evt = require "events"
local utils = require "st.utils"

local vspmap = { [0] = 0, [1] = 1, [2] = 2, [4] = 3, [8] = 4 }

local man_prop = {}

function man_prop.process84Event(device,payload)
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
		{ type = 'vspSpeed', state = vspmap[payload[get.VSP_SPEED_84(device)]]},
		{ type = 'poolSpaMode', state = get.EXPANSION_5043(device) and (((payload[get.POOL_SPA_MODE_84(device)] & 0x01) == 0) and 'on' or 'off') or (((payload[get.SWITCHES_84(device)] & 0x08) ~= 0) and 'on' or 'off')},
		{ type = 'heater', state = (not get.EXPANSION_5043(device)) and (((payload[get.SWITCHES_84(device)] & 0x10) ~= 0) and 'on' or 'off') or nil},
		{ type = 'waterTemp', state = (payload[get.WATER_TEMP_84(device)] >= 0) and payload[get.WATER_TEMP_84(device)] or payload[get.WATER_TEMP_84(device)] + 255},
		{ type = 'airTemp', state = (payload[get.AIR_TEMP_FREEZE_84(device)] >= 0) and payload[get.AIR_TEMP_FREEZE_84(device)] or payload[get.AIR_TEMP_FREEZE_84(device)] + 255},
		{ type = 'solarTemp', state = (payload[get.AIR_TEMP_SOLAR_84(device)] >= 0) and payload[get.AIR_TEMP_SOLAR_84(device)] or payload[get.AIR_TEMP_SOLAR_84(device)] + 255},
		{ type = 'clock', state = string.format('%02d',payload[get.CLOCK_HOUR_84(device)]) .. ':' .. string.format('%02d',payload[get.CLOCK_MINUTE_84(device)])},
	}
	evt.post_event(device,0x91,0x84,update)
end

function man_prop.process87Event(device,payload)
	local update = {
		{ type = 'expansionVersion', state = payload[get.VER_EXP_MAJOR_87] .. '.' .. payload[get.VER_EXP_MINOR_87]},
		{ type = 'heater', state = get.EXPANSION_5043(device) and (((payload[get.HEATER_87] & 0x04) ~= 0) and 'on' or 'off') or nil},
	}
	for _, event in ipairs(update) do
		if event.state then log.trace('---------- ' .. event.type .. ' : ' .. event.state) end
	end
	evt.post_event(device,0x91,0x87,update)
end

return man_prop