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
local config_handlers = require("inovelli-lzw45.config_handlers")
local cap_defs = require('inovelli-lzw45.cap_defs')
local commands = require('inovelli-lzw45.commands')
local paramMap = require('inovelli-lzw45.param_map')
local basic_refresh = require('inovelli-lzw45.basic_refresh')
local log = require "log"

local LZW45_FINGERPRINT = {
    {mfr = 0x031E, prod = 0x000A, model = 0x0001}, -- LZW45
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

local function can_handle_lzw45(opts, driver, device, ...)
    for _, fingerprint in ipairs(LZW45_FINGERPRINT) do
        if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
            return true
        end
    end
    return false
end

local function do_refresh(self, device)
    basic_refresh(device)
    device:send(Meter:Get({scale=Meter.scale.electric_meter.KILOWATT_HOURS}))
    device:send(Meter:Get({scale=Meter.scale.electric_meter.WATTS}))
    device:send(Meter:Get({scale=Meter.scale.electric_meter.VOLTS}))
    device:send(Meter:Get({scale=Meter.scale.electric_meter.AMPERES}))
    device:send(Version:Get({}))
end

--- 1 = Config Button (pushed only), 2 = Up, 3 = Down
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.CentralScene.Notification
local function central_scene_notification_handler(self, device, cmd)
    local button_number = cmd.args.scene_number
    local suffix = map_key_attribute_to_capability[cmd.args.key_attributes]
    local button_push = (button_number == 1 and ((suffix == '_hold') and ('held') or ('pushed' .. suffix))) or ((button_number == 2 and 'up' or 'down') .. suffix)
    if cmd.args.key_attributes ~= CentralScene.key_attributes.KEY_RELEASED then
        local evt = capabilities.button.button(button_push)
        evt.state_change = true
        device:emit_event(evt)
    end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Configuration.Report
local function configuration_report(driver,device,command)
    local param = command.args.parameter_number
    if (paramMap[param] or {}).handler then
        local str = command.payload
        local payload = {str:byte(1,#str)}
        config_handlers[paramMap[param].handler](device,payload)
        --device:emit_component_event(device.profile.components[paramMap[param].comp],paramMap[param].cap(paramMap[param].map[command.args.configuration_value]))
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
    do_refresh(driver,device)
end

--- Issue an RGB color set command to the specified device.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command table ST color control capability command
local function set_color(driver, device, command)
    log.debug("TEST")
  local duration = constants.DEFAULT_DIMMING_DURATION
  local r, g, b = utils.hsl_to_rgb(command.args.color.hue, command.args.color.saturation)
  device:set_field(CAP_CACHE_KEY, command)
  local set = SwitchColor:Set({
    color_components = {
      { color_component_id=SwitchColor.color_component_id.RED, value=r },
      { color_component_id=SwitchColor.color_component_id.GREEN, value=g },
      { color_component_id=SwitchColor.color_component_id.BLUE, value=b },
      { color_component_id=SwitchColor.color_component_id.WARM_WHITE, value=0 },
      { color_component_id=SwitchColor.color_component_id.COLD_WHITE, value=0 },
    },
    duration=duration
  })
  device:send_to_component(set, command.component)
  local query_color = function()
    -- Use a single RGB color key to trigger our callback to emit a color
    -- control capability update.
    device:send_to_component(
      SwitchColor:Get({ color_component_id=SwitchColor.color_component_id.RED }),
      command.component
    )
  end
  device.thread:call_with_delay(constants.DEFAULT_GET_STATUS_DELAY + duration, query_color)
end

local inovelli_lzw45 = {
    NAME = "Inovelli LZW45 Light Strip",
    zwave_handlers = {
        [cc.CENTRAL_SCENE] = {
            [CentralScene.NOTIFICATION] = central_scene_notification_handler,
        },
        [cc.CONFIGURATION] = {
            [Configuration.REPORT] = configuration_report,
        },
    },
    supported_capabilities = {
        capabilities.switch,
        capabilities.switchLevel,
        capabilities.colorControl,
        capabilities.colorTemperature,
        capabilities.colorMode,
        capabilities.powerMeter,
        capabilities.energyMeter,
        capabilities.button,
        capabilities.refresh,
    },
    capability_handlers = {
        [capabilities.switch.ID] = {
            [capabilities.switch.commands.on.NAME] = commands.set_switch,
            [capabilities.switch.commands.off.NAME] = commands.set_switch,
        },
        [capabilities.switchLevel.ID] = {
            [capabilities.switchLevel.commands.setLevel.NAME] = commands.set_switch_level
        },
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = do_refresh
        },
        [cap_defs.pixelEffect.ID] = {
            [cap_defs.pixelEffect.commands.setEffect.NAME] = commands.set_pixel_effect
        },
        [capabilities.colorControl.ID] = {
            [capabilities.colorControl.commands.setColor] = set_color
        }
    },
    lifecycle_handlers = {
        added = device_added,
    },
    can_handle = can_handle_lzw45,
}

return inovelli_lzw45
