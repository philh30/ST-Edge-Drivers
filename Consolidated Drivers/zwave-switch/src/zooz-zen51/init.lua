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
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({ version=1 })
local switch_defaults = require "st.zwave.defaults.switch"
local update_preferences = require "update_preferences"
local log = require "log"


local ZEN51_FINGERPRINT = {
    {mfr = 0x027A, prod = 0x0104, model = 0x0201}, -- ZEN51
}

local function can_handle_zen51_relay(opts, driver, device, ...)
    for _, fingerprint in ipairs(ZEN51_FINGERPRINT) do
        if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
            return true
        end
    end
    return false
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver,device,cmd)
    device:send(SwitchBinary:Get({}))
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function device_added(driver, device)
    local button_count = 1
    local supported_button_values = {'pushed','held','pushed_2x','pushed_3x','pushed_4x','pushed_5x'}
    for _,comp in pairs(device.profile.components) do
        device:emit_component_event(comp,capabilities.button.numberOfButtons(button_count))
        device:emit_component_event(comp,capabilities.button.supportedButtonValues(supported_button_values))
    end
    device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function info_changed(driver, device, event, args)
    update_preferences(driver, device, args)
    if args.old_st_store.preferences.deviceProfile ~= device.preferences.deviceProfile then
        log.warn("Changing profile")
        local create_device_msg = {
            profile =  device.preferences.deviceProfile,
        }
        assert (device:try_update_metadata(create_device_msg), "Failed to change device")
    end
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function switch_binary_report(driver,device,cmd)
    local event
    if device:supports_capability_by_id('smokeDetector') then
        if cmd.args.value == SwitchBinary.value.OFF_DISABLE then
            event = capabilities.smokeDetector.smoke.clear()
        else
            event = capabilities.smokeDetector.smoke.detected()
        end
        device:emit_event(event)
    end
    if device:supports_capability_by_id('carbonMonoxideDetector') then
        if cmd.args.value == SwitchBinary.value.OFF_DISABLE then
            event = capabilities.carbonMonoxideDetector.carbonMonoxide.clear()
        else
            event = capabilities.carbonMonoxideDetector.carbonMonoxide.detected()
        end
        device:emit_event(event)
    end
    if device:supports_capability_by_id('switch') then
        switch_defaults.zwave_handlers[cc.SWITCH_BINARY][SwitchBinary.REPORT](driver,device,cmd)
    end
end

local zen51_relay = {
    NAME = "Zooz ZEN51 Dry Contact Relay",
    zwave_handlers = {
        [cc.SWITCH_BINARY] = {
            [SwitchBinary.REPORT] = switch_binary_report
        },
    },
    supported_capabilities = {
      capabilities.switch,
      capabilities.refresh,
      capabilities.button,
    },
    capability_handlers = {
        [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
          },
    },
    lifecycle_handlers = {
        infoChanged = info_changed,
        added = device_added,
    },
    can_handle = can_handle_zen51_relay,
}

return zen51_relay
