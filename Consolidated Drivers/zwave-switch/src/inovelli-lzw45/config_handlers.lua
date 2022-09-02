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

--- @type st.capabilities
local capabilities = require "st.capabilities"
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
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
local log = require "log"

local handlers = {}

--- @param device st.zwave.Device
function handlers.pixel_effect(device,payload)
    local configValue1 = payload[3]
    local configValue2 = payload[4] .. ''
    device:emit_component_event(device.profile.components.pixelEffect,capabilities.switch.switch(configValue1==0 and 'off' or 'on'))
    if configValue1 ~= 0 then
        device:emit_component_event(device.profile.components.pixelEffect,capabilities.switchLevel.level(configValue1==99 and 100 or configValue1))
    end
    if configValue2 ~= '0' then
        device:emit_component_event(device.profile.components.pixelEffect,cap_defs.pixelEffect.pixelEffect(configValue2))
    end
end

--- @param device st.zwave.Device
function handlers.quick_effect(device,payload)

    local effect = payload[3] & ~192
    local colorMode = (payload[3] & 64) == 0 and 'color' or 'colorTemperature'
    local level = (payload[5] & 128) == 0 and payload[5] * 10 or payload[5] & ~128
    local color = colorMode=='color' and payload[6]/255*360 or payload[6]/255*(6500-2700)+2700
    local duration = payload[4]
    --local cap = colorMode == 'color' and capabilities.colorMode.
    log.warn(string.format('Effect %s ColorMode %s Level %s Color %s Duration %s',effect,colorMode,level,color,duration))

    device:emit_component_event(device.profile.components.quickEffect,capabilities.switch.switch(effect==0 and 'off' or 'on'))
    if level ~= 0 then
        device:emit_component_event(device.profile.components.quickEffect,capabilities.switchLevel.level(level==99 and 100 or level))
    end
    --device:emit_component_event(device.profile.components.quickEffect,capabilities[colorMode=='color' and 'colorControl' or 'colorTemperature'])
    --[[
    device:emit_component_event(device.profile.components.pixelEffect,capabilities.switch.switch(configValue1==0 and 'off' or 'on'))
    if configValue1 ~= 0 then
        device:emit_component_event(device.profile.components.pixelEffect,capabilities.switchLevel.level(configValue1==99 and 100 or configValue1))
    end
    --]]
    device:emit_component_event(device.profile.components.quickEffect,cap_defs.quickEffect.quickEffect(effect .. ''))
end

return handlers