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
local capabilities = require "st.capabilities"
local map = require "cap_ep_map"
local capdefs = require "capabilitydefs"

local events = {}

local event_types = {
    [0x20] = {
        [0x03] = 'BASIC REPORT: ',
    },
    [0x31] = {
        [0x05] = 'SENSOR MULTILEVEL REPORT: ',
    },
    [0x43] = {
        [0x03] = 'THERMOSTAT SETPOINT REPORT: ',
        [0x05] = 'THERMOSTAT SETPOINT SUPPORTED REPORT: ',
        [0x0A] = 'THERMOSTAT SETPOINT CAPABILITIES REPORT: ',
    },
    [0x60] = {
        [0x06] = 'MULTI CHANNEL CMD ENCAP',
    },
    [0x70] = {
        [0x06] = 'CONFIGURATION REPORT: ',
    },
    [0x72] = {
        [0x05] = 'MANUFACTURER SPECIFIC REPORT: ',
        [0x07] = 'MANUFACTURER DEVICE SPECIFIC REPORT: ',
    },
    [0x85] = {
        [0x03] = 'ASSOCIATION REPORT: ',
        [0x06] = 'ASSOCIATION GROUPINGS REPORT: ',
        [0x0C] = 'ASSOCIATION SPECIFIC GROUP REPORT: ',
    },
    [0x86] = {
        [0x12] = 'VERSION REPORT: ',
        [0x16] = 'CAPABILITIES REPORT: ',
    },
    [0x91] = {
        [0x84] = 'MANUFACTURER PROPRIETARY 84 REPORT: ',
        [0x87] = 'MANUFACTURER PROPRIETARY 87 REPORT: ',
    },
}

--- @param device st.zwave.Device
function events.firmware_event(device,event)
    local curr_fw = device:get_field('FIRMWARE')
    if curr_fw ~= event.state then
        log.debug('Storing firmware version ' .. event.state)
        device:set_field('FIRMWARE', event.state, {persist = true})
    end
    local comp = map.GET_COMP(device,event.type)
    if comp then
        device:emit_component_event(device.profile.components[comp],map.EP_MAP[event.type].cap({ value = event.state .. '' }))
    end
end

--- @param device st.zwave.Device
function events.expansion_version_event(device,event)
    local curr_fw = device:get_field('EXP_VERSION')
    if curr_fw ~= event.state then
        log.debug('Storing expansion version ' .. event.state)
        device:set_field('EXP_VERSION', event.state, {persist = true})
    end
end

--- @param device st.zwave.Device
function events.basic_event(device,event)
    local comp = map.GET_COMP(device,event.type)
    if comp then
        device:emit_component_event(device.profile.components[comp],map.EP_MAP[event.type].cap({ value = map.EP_MAP[event.type][event.state] }))
    end
end

--- @param device st.zwave.Device
function events.unit_event(device,event)
    local comp = map.GET_COMP(device,event.type)
    if comp then
        device:emit_component_event(device.profile.components[comp],map.EP_MAP[event.type].cap({ value = event.state, unit = map.EP_MAP[event.type].unit }))
    end
end

--- @param device st.zwave.Device
function events.raw_event(device,event)
    local comp = map.GET_COMP(device,event.type)
    if comp then
        device:emit_component_event(device.profile.components[comp],map.EP_MAP[event.type].cap({ value = event.state }))
    end
end

--- @param device st.zwave.Device
function events.string_event(device,event)
    local comp = map.GET_COMP(device,event.type)
    if comp then
        device:emit_component_event(device.profile.components[comp],map.EP_MAP[event.type].cap({ value = event.state .. '' }))
    end
end

--- @param device st.zwave.Device
function events.schedule_event(device,event)
    local comp = map.GET_COMP(device,'scheduleTime')
    local curr_param = device:get_latest_state(comp,capdefs.schedule.name,'schedule') - 100
    if comp then
        if curr_param == event.param then
            device:emit_component_event(device.profile.components[comp],map.EP_MAP['scheduleTime'].cap({ value = (event.state or '99:99-99:99') }))
            device:emit_component_event(device.profile.components[comp],capdefs.scheduleTime.capability.parameter({ value = event.param }))
        end
    end
end

--- @param device st.zwave.Device
function events.no_action_event(device,event)

end

--- @param device st.zwave.Device
function events.post_event(device,cmd_cls,cmd_id,update)
    log.trace(event_types[cmd_cls][cmd_id])
    if update then
        for _, event in ipairs(update) do
            if event.type == 'scheduleTime' then
                log.trace('---------- ' .. event.type .. ' ' .. event.desc .. ' : ' .. (event.state or 'Not scheduled'))
                if map.EP_MAP[event.type] then events[map.EP_MAP[event.type].handler](device,event) end
            elseif event.state then
                log.trace('---------- ' .. event.type .. ' : ' .. (event.desc or event.state))
                if map.EP_MAP[event.type] then events[map.EP_MAP[event.type].handler](device,event) end
            else
                log.trace('---------- ' .. event.type .. ' : Nil state reported')
            end
        end
    else
        log.trace('---------- No events reported')
    end
end

return events