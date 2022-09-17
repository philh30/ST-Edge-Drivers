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
--- @type st.utils
local utils = require "st.utils"
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
--- @type st.zwave.CommandClass.Meter
local Meter = (require "st.zwave.CommandClass.Meter")({version=3})
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version=1 })
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({version=4,strict=true})
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version=3 })
local config_handlers = require "inovelli-lzw36.config_handlers"
local fan_handlers = require "inovelli-lzw36.fan"
local call_parent_handler = require "call_parent"
local log = require "log"

local LZW36_FINGERPRINT = {
    {mfr = 0x031E, prod = 0x000E, model = 0x0001}, -- LZW36
}

local map_ep_component = {
    [0] = 'energy',
    [1] = 'main',
    [2] = 'fan',
}

local paramMap = {
    [18] = { comp = 'lightIndicator', handler = 'color_handler'     },
    [19] = { comp = 'lightIndicator', handler = 'intensity_handler' },
    [20] = { comp = 'fanIndicator',   handler = 'color_handler'     },
    [21] = { comp = 'fanIndicator',   handler = 'intensity_handler' },
    [24] = { comp = 'lightIndicator', handler = 'effect_handler'    },
    [25] = { comp = 'fanIndicator',   handler = 'effect_handler'    },
}

local map_scene = {
    [1] = { comp = 'fan',   type = 'pushed' },
    [2] = { comp = 'main', type = 'pushed' },
    [3] = { comp = 'main', type = 'up'     },
    [4] = { comp = 'main', type = 'down'   },
    [5] = { comp = 'fan',   type = 'up'     },
    [6] = { comp = 'fan',   type = 'down'   },
}

local map_key_attribute_to_capability = {
    [CentralScene.key_attributes.KEY_PRESSED_1_TIME] = '',
    [CentralScene.key_attributes.KEY_RELEASED] = '_released', -- released doesn't exist on button capability, so don't emit this event
    [CentralScene.key_attributes.KEY_HELD_DOWN] = '_hold',
    [CentralScene.key_attributes.KEY_PRESSED_2_TIMES] = '_2x',
    [CentralScene.key_attributes.KEY_PRESSED_3_TIMES] = '_3x',
    [CentralScene.key_attributes.KEY_PRESSED_4_TIMES] = '_4x',
    [CentralScene.key_attributes.KEY_PRESSED_5_TIMES] = '_5x',
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

local function set_color(driver, device, cmd)
    local comp_map = { lightIndicator = 18, fanIndicator = 20 }
    local param = comp_map[cmd.component]
    local value = utils.round(cmd.args.color.hue / 100 * 255)
    local config = Configuration:Set({ parameter_number=param, configuration_value=value, size=2 })
    device:send(config)
    local query_configuration = function()
        device:send(Configuration:Get({ parameter_number=param }))
    end
    device.thread:call_with_delay(constants.DEFAULT_GET_STATUS_DELAY + constants.DEFAULT_DIMMING_DURATION, query_configuration)
end

local function do_refresh(self, device)
    device:send(SwitchBinary:Get({}, {dst_channels = {1}}))
    device:send(SwitchBinary:Get({}, {dst_channels = {2}}))
    device:send(SwitchMultilevel:Get({}, {dst_channels = {1}}))
    device:send(SwitchMultilevel:Get({}, {dst_channels = {2}}))
    device:send(Meter:Get({scale = Meter.scale.electric_meter.KILOWATT_HOURS}))
    device:send(Meter:Get({scale = Meter.scale.electric_meter.WATTS}))
    for param, _ in pairs(paramMap) do
        device:send(Configuration:Get({parameter_number = param}))
    end
    device:send(Version:Get({}))
end

local function can_handle_lzw36_fan_light(opts, driver, device, ...)
    for _, fingerprint in ipairs(LZW36_FINGERPRINT) do
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
    if ( cmd.args.scene_number ~= nil and cmd.args.scene_number ~= 0 ) then
        local button_component = map_scene[cmd.args.scene_number].comp
        local button_type = map_scene[cmd.args.scene_number].type
        local suffix = map_key_attribute_to_capability[cmd.args.key_attributes]
        local button_push = (button_type == 'pushed') and ((suffix == '_hold') and ('held') or ('pushed' .. suffix)) or (button_type .. suffix)
        if suffix ~= 'released' then
            local evt = capabilities.button.button(button_push)
            evt.state_change = true
            device:emit_component_event(device.profile.components[button_component],evt)
        end
    end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Configuration.Report
local function configuration_report(driver,device,command)
    local param = command.args.parameter_number
    if paramMap[param] then
        config_handlers[paramMap[param].handler](device,paramMap[param].comp,command.args.configuration_value)
    end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.SwitchMultilevel.Report | st.zwave.CommandClass.Basic.Report
local function level_report(driver,device,command)
    if map_ep_component[command.src_channel] == 'fan' then
        fan_handlers.fan_multilevel_report(driver,device,command)
    elseif map_ep_component[command.src_channel] == 'main' then
        call_parent_handler(driver.zwave_handlers[cc.SWITCH_MULTILEVEL][SwitchMultilevel.REPORT], driver, device, command)
    end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function set_level(driver, device, command)
    local comp_type = { main = 'SwitchMultiLevel', energy = 'None', fan = 'SwitchMultiLevel', lightIndicator = 'Configuration', fanIndicator = 'Configuration'}
    local comp_map = { lightIndicator = 19, fanIndicator = 21 }
    local set
    local get
    local delay = constants.MIN_DIMMING_GET_STATUS_DELAY -- delay in seconds

    if comp_type[command.component] == 'SwitchMultiLevel' then
        local level = utils.round(command.args.level)
        level = utils.clamp_value(level, 1, 99)

        local dimmingDuration = command.args.rate or constants.DEFAULT_DIMMING_DURATION -- dimming duration in seconds
        -- delay shall be at least 5 sec.
        delay = math.max(dimmingDuration + constants.DEFAULT_POST_DIMMING_DELAY, delay) -- delay in seconds
        get = SwitchMultilevel:Get({})
        set = SwitchMultilevel:Set({ value=level, duration=dimmingDuration })
    elseif comp_type[command.component] == 'Configuration' then
        local param = comp_map[command.component]
        local level = utils.round(command.args.level/10)
        level = utils.clamp_value(level, 0, 10)
        get = Configuration:Get({parameter_number = param})
        set = Configuration:Set({ parameter_number=param, configuration_value=level, size=1 })
    else
        return
    end
    device:send_to_component(set, command.component)
    local query_level = function()
        device:send_to_component(get, command.component)
    end
    device.thread:call_with_delay(delay, query_level)
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
    do_refresh(driver,device)
end

--- Map component to end_points
---
--- @param device st.zwave.Device
--- @param component_id string ID
--- @return table dst_channels destination channels e.g. {2} for Z-Wave channel 2 or {} for unencapsulated
local function component_to_endpoint(device, component_id)
    local ep_num = indexOf(map_ep_component,component_id)
    return { ep_num and tonumber(ep_num) } 
end

--- Map end_point to Z-Wave endpoint
---
--- @param device st.zwave.Device
--- @param ep number the endpoint(Z-Wave channel) ID to find the component for
--- @return string the component ID the endpoint matches to
local function endpoint_to_component(device, ep)
    local switch_comp = map_ep_component[ep]
    if device.profile.components[switch_comp] ~= nil then
        return switch_comp
    else
        return "energy"
    end
end

--- Initialize device
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local device_init = function(self, device)
    device:set_component_to_endpoint_fn(component_to_endpoint)
    device:set_endpoint_to_component_fn(endpoint_to_component)
end

local lzw36_fan_light = {
    NAME = "Inovelli LZW36 Fan Light",
    zwave_handlers = {
        [cc.CENTRAL_SCENE] = {
            [CentralScene.NOTIFICATION] = central_scene_notification_handler,
        },
        [cc.CONFIGURATION] = {
            [Configuration.REPORT] = configuration_report,
        },
        [cc.SWITCH_MULTILEVEL] = {
          [SwitchMultilevel.REPORT] = level_report
        },
        [cc.BASIC] = {
          [Basic.REPORT] = level_report
        }
    },
    capability_handlers = {
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = do_refresh
        },
        [capabilities.colorControl.ID] = {
            [capabilities.colorControl.commands.setColor.NAME] = set_color,
        },
        [capabilities.switchLevel.ID] = {
            [capabilities.switchLevel.commands.setLevel.NAME] = set_level,
        },
        [capabilities.fanSpeed.ID] = {
            [capabilities.fanSpeed.commands.setFanSpeed.NAME] = fan_handlers.fan_speed_set
        },
    },
    lifecycle_handlers = {
        init = device_init,
        added = device_added,
    },
    can_handle = can_handle_lzw36_fan_light,
}

return lzw36_fan_light
