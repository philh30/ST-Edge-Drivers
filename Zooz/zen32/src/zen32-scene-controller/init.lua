-- Author: philh30
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
--- @type st.zwave.CommandClass.Indicator
local Indicator = (require "st.zwave.CommandClass.Indicator")({ version=1 })
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version=1 })
--- @type st.zwave.CommandClass.CentralScene
local CentralScene = (require "st.zwave.CommandClass.CentralScene")({ version=3 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version=1 })
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version=3 })
local ZoozLEDBrightness = capabilities['platinummassive43262.zoozLedBrightness']
local ZoozLEDColor = capabilities['platinummassive43262.zoozLedColor']
local ZoozLEDMode = capabilities['platinummassive43262.zoozLedMode']
local log = require "log"

local ZEN32_FINGERPRINT = {
    {mfr = 0x027A, prod = 0x7000, model = 0xA008}, -- ZEN32
}

local buttonMap = {
	topLeft =       { basicSetGroup = 4,    multilevelGroup = 5,    ledModeParamNum = 2,    ledColorParamNum = 7,   ledBrightnessParamNum = 12, name = "Button 1"},
	topRight =      { basicSetGroup = 6,    multilevelGroup = 7,    ledModeParamNum = 3,    ledColorParamNum = 8,   ledBrightnessParamNum = 13, name = "Button 2"},
	bottomLeft =    { basicSetGroup = 8,    multilevelGroup = 9,    ledModeParamNum = 4,    ledColorParamNum = 9,   ledBrightnessParamNum = 14, name = "Button 3"},
	bottomRight =   { basicSetGroup = 10,   multilevelGroup = 11,   ledModeParamNum = 5,    ledColorParamNum = 10,  ledBrightnessParamNum = 15, name = "Button 4"},
	main =          { basicSetGroup = 2,    multilevelGroup = 3,    ledModeParamNum = 1,    ledColorParamNum = 6,   ledBrightnessParamNum = 11, name = "Relay Button"},
}

local map_scene_to_component = {
    [1] = 'topLeft',
    [2] = 'topRight',
    [3] = 'bottomLeft',
    [4] = 'bottomRight',
    [5] = 'main',
}

local colorMap = { [0] = "white", [1] = "blue", [2] = "green", [3] = "red"}
local modeMap = { [0] = "onWhenOff", [1] = "onWhenOn", [2] = "alwaysOff", [3] = "alwaysOn" }
local brightnessMap = { [0] = "bright", [1] = "medium", [2] = "low" }

local paramMap = {
    [1] = { comp = 'main', cap = ZoozLEDMode.ledMode, map = modeMap },
    [2] = { comp = 'topLeft', cap = ZoozLEDMode.ledMode, map = modeMap },
    [3] = { comp = 'topRight', cap = ZoozLEDMode.ledMode, map = modeMap },
    [4] = { comp = 'bottomLeft', cap = ZoozLEDMode.ledMode, map = modeMap },
    [5] = { comp = 'bottomRight', cap = ZoozLEDMode.ledMode, map = modeMap },
    [6] = { comp = 'main', cap = ZoozLEDColor.ledColor, map = colorMap },
    [7] = { comp = 'topLeft', cap = ZoozLEDColor.ledColor, map = colorMap },
    [8] = { comp = 'topRight', cap = ZoozLEDColor.ledColor, map = colorMap },
    [9] = { comp = 'bottomLeft', cap = ZoozLEDColor.ledColor, map = colorMap },
    [10] = { comp = 'bottomRight', cap = ZoozLEDColor.ledColor, map = colorMap },
    [11] = { comp = 'main', cap = ZoozLEDBrightness.ledBrightness, map = brightnessMap },
    [12] = { comp = 'topLeft', cap = ZoozLEDBrightness.ledBrightness, map = brightnessMap },
    [13] = { comp = 'topRight', cap = ZoozLEDBrightness.ledBrightness, map = brightnessMap },
    [14] = { comp = 'bottomLeft', cap = ZoozLEDBrightness.ledBrightness, map = brightnessMap },
    [15] = { comp = 'bottomRight', cap = ZoozLEDBrightness.ledBrightness, map = brightnessMap },
}

local map_key_attribute_to_capability = {
    [CentralScene.key_attributes.KEY_PRESSED_1_TIME] = 'pushed',
    [CentralScene.key_attributes.KEY_RELEASED] = 'released', -- released doesn't exist on button capability, so don't emit this event
    [CentralScene.key_attributes.KEY_HELD_DOWN] = 'held',
    [CentralScene.key_attributes.KEY_PRESSED_2_TIMES] = 'pushed_2x',
    [CentralScene.key_attributes.KEY_PRESSED_3_TIMES] = 'pushed_3x',
    [CentralScene.key_attributes.KEY_PRESSED_4_TIMES] = 'pushed_4x',
    [CentralScene.key_attributes.KEY_PRESSED_5_TIMES] = 'pushed_5x',
}

-- Return the first index with the given value (or nil if not found).
local function indexOf(array, value)
    for i, v in pairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

local function do_refresh(self, device)
    device:send(SwitchBinary:Get({}))
    for param=1,15,1 do
        device:send(Configuration:Get({parameter_number = param}))
    end
    device:send(Version:Get({}))
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local function zooz_led_handler(self, device, command)
    local handler_map = {
        setLedColor = { map = colorMap, param = 'ledColorParamNum' },
        setLedBrightness = { map = brightnessMap, param = 'ledBrightnessParamNum' },
        setLedMode = { map = modeMap, param = 'ledModeParamNum' },
    }
    local config_value = indexOf(handler_map[command.command].map,command.args.value)
    local button_param = buttonMap[command.component][handler_map[command.command].param]
    device:send(Configuration:Set({parameter_number = button_param, size = 1, configuration_value = config_value}))
    device:send(Configuration:Get({parameter_number = button_param}))
end

local function can_handle_zen32_scene_controller(opts, driver, device, ...)
    for _, fingerprint in ipairs(ZEN32_FINGERPRINT) do
        if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
            return true
        end
    end
    return false
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.CentralScene.Notification
local function central_scene_notification_handler(self, device, cmd)
    if ( cmd.args.scene_number ~= nil and cmd.args.scene_number >= 1 and cmd.args.scene_number <= 5 ) then
        local button_component = map_scene_to_component[cmd.args.scene_number]
        local button_push = map_key_attribute_to_capability[cmd.args.key_attributes]
        if button_push ~= 'released' then
            device:emit_component_event(device.profile.components[button_component],capabilities.button.button(button_push))
        end
    end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Configuration.Report
local function configuration_report(driver,device,command)
    local param = command.args.parameter_number
    if paramMap[param] then
        device:emit_component_event(device.profile.components[paramMap[param].comp],paramMap[param].cap(paramMap[param].map[command.args.configuration_value]))
    end
  end

--- Added device
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function device_added(driver, device)
    local button_count = 1
    local supported_button_values = {'pushed','held','pushed_2x','pushed_3x','pushed_4x','pushed_5x'}
    for _,comp in pairs(device.profile.components) do
        device:emit_component_event(comp,capabilities.button.numberOfButtons(button_count))
        device:emit_component_event(comp,capabilities.button.supportedButtonValues(supported_button_values))
    end
end

local zen32_scene_controller = {
    NAME = "Zooz ZEN32 Scene Controller",
    zwave_handlers = {
        [cc.CENTRAL_SCENE] = {
        [CentralScene.NOTIFICATION] = central_scene_notification_handler,
        },
        [cc.CONFIGURATION] = {
          [Configuration.REPORT] = configuration_report,
        },
--[[
        [cc.INDICATOR] = {
            [Indicator.REPORT] = zwave_handlers_indicator_report
        },
--]]
    },
    capability_handlers = {
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = do_refresh
        },
        [ZoozLEDColor.ID] = {
            [ZoozLEDColor.commands.setLedColor.NAME] = zooz_led_handler
        },
        [ZoozLEDBrightness.ID] = {
            [ZoozLEDBrightness.commands.setLedBrightness.NAME] = zooz_led_handler
        },
        [ZoozLEDMode.ID] = {
            [ZoozLEDMode.commands.setLedMode.NAME] = zooz_led_handler
        },
    },
    lifecycle_handlers = {
        added = device_added,
    },
    can_handle = can_handle_zen32_scene_controller,
}

return zen32_scene_controller
