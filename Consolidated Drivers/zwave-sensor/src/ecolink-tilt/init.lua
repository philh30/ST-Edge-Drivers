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

local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
local battery_defaults = require "st.zwave.defaults.battery"
local capabilities = require "st.capabilities"
local cc = require "st.zwave.CommandClass"

local ECOLINK_TILT_FINGERPRINTS = {
    {mfr = 0x014A, prod = 0x0004, model = 0x0003} -- Ecolink Tilt Sensor
}

local function can_handle_ecolink_tilt(opts, driver, device, ...)
    for _, fingerprint in ipairs(ECOLINK_TILT_FINGERPRINTS) do
        if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
            return true
        end
    end
    return false
end

local function wakeup_notification(driver, device, cmd)
    device:emit_event(capabilities.tamperAlert.tamper.clear())
end

local function battery_report(driver, device, cmd)
    if cmd.args.battery_level == 99 then cmd.args.battery_level = 100 end
    battery_defaults.zwave_handlers[cc.BATTERY][Battery.REPORT](driver,device,cmd)
end

local ecolink_tilt = {
    NAME = "Ecolink Tilt Sensor",
    zwave_handlers = {
        [cc.WAKE_UP] = {
            [WakeUp.NOTIFICATION] = wakeup_notification,
        },
        [cc.BATTERY] = {
            [Battery.REPORT] = battery_report,
        },
    },
    can_handle = can_handle_ecolink_tilt,
}

return ecolink_tilt