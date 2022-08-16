-- Copyright 2022 philh30
-- Handlers for switch and switchLevel based on default ST handlers
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

--- @type st.capabilities
local capabilities = require "st.capabilities"
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.utils
local utils = require "st.utils"
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version=2 })
--- @type st.zwave.CommandClass.CentralScene
local CentralScene = (require "st.zwave.CommandClass.CentralScene")({ version=3 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.Meter
local Meter = (require "st.zwave.CommandClass.Meter")({ version=3 })
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version=1 })
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({ version=4 })
--- @type st.zwave.CommandClass.SwitchColor
local SwitchColor = (require "st.zwave.CommandClass.SwitchColor")({ version=3 })
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version=3 })
local cap_defs = require('inovelli-lzw45.cap_defs')
local basic_refresh = require('inovelli-lzw45.basic_refresh')
local log = require "log"

local command_handlers = {}

local function send_pixel_effect(device,effect,level)
    local query_pixel_effect = function()
        basic_refresh(device)
    end
    level = utils.clamp_value(level,0,99)
    device:send(Configuration:Set({ parameter_number = 31, size = 2, configuration_value = level*256+effect }))
    device.thread:call_with_delay(2,query_pixel_effect)
end

local function send_quick_effect(device,effect,level,duration,color,colorMode)
    local query_quick_effect = function()
        basic_refresh(device)
    end
    level = utils.clamp_value(level,0,99)
    local config1 = effect + (colorMode == 'color' and 0 or 64)
    local config2 = duration
    local config3 = level + 128
    local config4 = colorMode=='color' and color/360*255 or (color-2700)*255/(6500-2700)
    device:send(Configuration:Set({ parameter_number = 21, size = 4, configuration_value = ((config1*256+config2)*256+config3)*256+config4}))
    device.thread:call_with_delay(2,query_quick_effect)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function command_handlers.set_pixel_effect(driver,device,cmd)
    local effect = cmd.args.pixelEffect
    local level = device:get_latest_state('pixelEffect','switchLevel','level',99)
    level = level == 0 and 99 or level
    send_pixel_effect(device,effect,level)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function command_handlers.set_switch(driver, device, command)
    local switch_state = command.command
    local query_device = function()
        device:send(SwitchMultilevel:Get({}))
    end
    if command.component == 'main' then
        device:send(SwitchMultilevel:Set({value = switch_state == 'on' and SwitchBinary.value.ON_ENABLE or SwitchBinary.value.OFF_DISABLE,duration = constants.DEFAULT_DIMMING_DURATION}))
        device.thread:call_with_delay(constants.MIN_DIMMING_GET_STATUS_DELAY, query_device)
    elseif command.component == 'pixelEffect' then
        local effect = switch_state == 'on' and device:get_latest_state('pixelEffect',cap_defs.pixelEffect.ID,'pixelEffect','0') or '0'
        local level = switch_state == 'on' and device:get_latest_state('pixelEffect','switchLevel','level',0) or 0
        send_pixel_effect(device,effect,level)
    elseif command.component == 'quickEffect' then
        local query_quick_effect = function()
            basic_refresh(device)
        end
        if switch_state == 'on' then
            --local effect = device:get_latest_state('quickEffect',cap_defs.quickEffect.ID,'quickEffect','0')
            local level = device:get_latest_state('quickEffect','switchLevel','level',0)
            --local duration =
            --local colorMode =
            --local color = colorMode == 'color' and device:get_latest_state() or device:get_latest_state()
            device:send(Configuration:Set({ parameter_number = 21, size = 4, configuration_value = 94177379}))
        else
            --device:send(Configuration:Set({ parameter_number = 21, size = 4, configuration_value = 10291299}))
            device:send(Configuration:Set({ parameter_number = 21, size = 4, configuration_value = 85853354}))
        end
        device.thread:call_with_delay(2,query_quick_effect)
    end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
function command_handlers.set_switch_level(driver, device, command)
    local level = utils.round(command.args.level)
    level = utils.clamp_value(level, 1, 99)
    local dimmingDuration = command.args.rate or constants.DEFAULT_DIMMING_DURATION
    local query_level = function()
        device:send_to_component(SwitchMultilevel:Get({}), command.component)
    end
    if command.component == 'main' then
        device:send_to_component(SwitchMultilevel:Set({ value=level, duration=dimmingDuration }), command.component)
        local delay = math.max(dimmingDuration + constants.DEFAULT_POST_DIMMING_DELAY , constants.MIN_DIMMING_GET_STATUS_DELAY)
        device.thread:call_with_delay(delay, query_level)
    elseif command.component == 'pixelEffect' then
        local effect = device:get_latest_state('pixelEffect',cap_defs.pixelEffect.ID,'pixelEffect','0')
        effect = tonumber(effect)
        send_pixel_effect(device,effect,level)
    end
end

return command_handlers