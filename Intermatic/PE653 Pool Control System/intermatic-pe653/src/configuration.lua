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
local sched = require "schedules"

local config = {}

function config.operation_mode_handler(device,payload)
    local configValue1 = payload[3]
    local configValue2 = payload[4]
    local curr_opmode2 = device:get_field('OP_MODE_2')
    if curr_opmode2 ~= tonumber(configValue2) then
        log.debug('Storing operation mode 2 config ' .. configValue2)
        device:set_field('OP_MODE_2', tonumber(configValue2), {persist = true})
    end
    return {
        { type = 'pumpTypeConfig', desc = get.CONFIG_INSTALLED_PUMP_TYPE[configValue2 & 0x02], state = configValue2 & 0x02 },
        { type = 'boosterCleanerInstalled', state = get.CONFIG_BOOSTER_CLEANER_INSTALLED[configValue2 & 0x01] },
        { type = 'boosterPumpConfig', desc = get.CONFIG_BOOSTER_CIRCUIT[configValue1], state = configValue1 },
    }
end

function config.fireman_handler(device,payload)
    local configValue1 = payload[3]
    local configValue2 = payload[4]
    local curr_fireman = device:get_field('FIREMAN')
    if curr_fireman ~= tonumber(configValue1) then
        log.debug('Storing fireman config ' .. configValue1)
        device:set_field('FIREMAN', tonumber(configValue1), {persist = true})
    end
    return {
        { type = 'firemanConfig', desc = get.CONFIG_FIREMAN_TIMEOUT[configValue1], state = configValue1 + 100 },
        { type = 'heaterSafetyConfig', desc = get.CONFIG_HEATER_SAFETY[configValue2], state = configValue2 },
    }
end

function config.temp_offset_handler(device,payload)
    local configValue1 = payload[3]
    local configValue2 = payload[4]
    local configValue3 = payload[5]
    return {
        { type = 'waterTempOffset', state = (configValue1 > 100) and (configValue1 - 256) or configValue1 },
        { type = 'airTempOffset', state = (configValue2 > 100) and (configValue2 - 256) or configValue2 },
        { type = 'solarTempOffset', state = (configValue3 > 100) and (configValue3 - 256) or configValue3 },
    }
end

function config.pool_spa_handler(device,payload)
    local configValue1 = payload[3]
    local curr_poolspa = device:get_field('POOL_SPA')
    if curr_poolspa ~= tonumber(configValue1) then
        log.debug('Storing pool/spa config ' .. configValue1)
        device:set_field('POOL_SPA', tonumber(configValue1), {persist = true})
    end
    return {
        { type = 'poolSpaConfig', desc = get.CONFIG_POOL_SPA[configValue1], state = configValue1 },
    }
end

function config.schedule_handler(device,payload)
    local configValue1 = payload[3]
    local configValue2 = payload[4]
    local configValue3 = payload[5]
    local configValue4 = payload[6]
    local on_time = (configValue2 or 0) * 256 + (configValue1 or 0)
    local on = {}
    if on_time ~= 65535 then
        on.hours = math.floor(on_time / 60)
        on.mins = on_time - on.hours * 60
    end
    local off_time = (configValue4 or 0) * 256 + (configValue3 or 0)
    local off = {}
    if off_time ~= 65535 then
        off.hours = math.floor(off_time / 60)
        off.mins = off_time - off.hours * 60
    end
    local on_str = on.hours and (on.hours .. ':' .. ((on.mins < 10) and '0' or '') .. on.mins) or nil
    local off_str = off.hours and (off.hours .. ':' .. ((off.mins < 10) and '0' or '') .. off.mins) or nil
    local str = ((on_str and off_str) and on_str .. '-' .. off_str) or nil
    sched.update_sched(device,{ name = get.CONFIG_PARAMS[payload[1]].shortname, start = on_str, stop = off_str})
    return {
        { type = 'scheduleTime', desc = get.CONFIG_PARAMS[payload[1]].friendlyname, param = payload[1], state = str }
    }
end

function config.pump_speed_handler(device,payload)
    local configValue1 = payload[3]
    local configValue2 = payload[4]
    local param = payload[1]
    local evtType = get.CONFIG_PARAMS[param].description
    local speed = configValue1 * 256 + configValue2
    if param ~= 0x31 then
        local curr_speed = device:get_field(evtType)
        if curr_speed ~= speed then
            log.debug('Storing pump speed ' .. speed)
            device:set_field(evtType, speed, {persist = true})
        end
    end
    return {
        { type = evtType, state = speed },
    }
end

function config.freeze_control_handler(device,payload)
    local configValue1 = payload[3]
    local configValue2 = payload[4]
    local configValue3 = payload[5]
    local configValue4 = payload[6]
    return {
        { type = 'freezeThreshold', state = configValue1 },
        { type = 'freezeSwitch1', state = (configValue2 & 0x01 ~= 0) and 'on' or 'off' },
        { type = 'freezeSwitch2', state = (configValue2 & 0x02 ~= 0) and 'on' or 'off' },
        { type = 'freezeSwitch3', state = (configValue2 & 0x04 ~= 0) and 'on' or 'off' },
        { type = 'freezeSwitch4', state = (configValue2 & 0x08 ~= 0) and 'on' or 'off' },
        { type = 'freezeSwitch5', state = (configValue2 & 0x10 ~= 0) and 'on' or 'off' },
        { type = 'freezeVsp', desc = get.CONFIG_FREEZE_CONTROL_VSP_SPD[configValue3], state = configValue3 },
        { type = 'freezeHeater', desc = (configValue4 & 0x80 ~=0) and 'enabled' or 'disabled', state = (configValue4 & 0x80 == 0) and 0 or 1 },
        { type = 'freezePoolSpaCycle', desc = configValue4 & 0x7F, state = configValue4 & 0x7F }
    }
end

return config