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
local capabilities = require "st.capabilities"
local cc = require "st.zwave.CommandClass"
local call_parent_handler = require "call_parent"
local battery = require "battery"

local ECOLINK_FINGERPRINTS = {
    { mfr = 0x014A, prod = 0x0001, model = 0x0003 }, -- Ecolink Tilt Sensor 2 (zwave)
    { mfr = 0x014A, prod = 0x0004, model = 0x0002 }, -- Ecolink Door/Window Sensor 2.5 (zwave plus)
    { mfr = 0x014A, prod = 0x0004, model = 0x0003 }, -- Ecolink Tilt Sensor 2.5 (zwave plus)
    { mfr = 0x014A, prod = 0x0005, model = 0x0010 }, -- Ecolink Flood/Freeze Sensor 5 (zwave plus)
    { mfr = 0x014A, prod = 0x0005, model = 0x000F }, -- Ecolink Flood/Freeze Sensor 5 (zwave plus)
}

local function can_handle_ecolink(opts, driver, device, ...)
    for _, fingerprint in ipairs(ECOLINK_FINGERPRINTS) do
        if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
            return true
        end
    end
    return false
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
    device.log.trace("wakeup_notification(ecolink-sensor)")

    -- When the cover is restored (tamper switch closed), the device wakes up.  Assume tamper is clear.
    device:emit_event(capabilities.tamperAlert.tamper.clear())

    -- We may need to request a battery update while we're woken up
    if battery.getBatteryUpdate(self, device) then
        -- Request a battery update now
        device:send(Battery:Get({}))
    end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function eco_doConfigure(self, device, event, args)
    device.log.trace("eco_doConfigure()")
    -- Call the topmost 'doConfigure' lifecycle hander to do the default work first
    call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, event, args)

    -- Send the default refresh commands for the capabilities of this device
    -- This includes SENSOR_BINARY GET and BATTERY GET.
    device:default_refresh()
end

local ecolink_sensor = {
    NAME = "Ecolink Sensor",
    zwave_handlers = {
        [cc.WAKE_UP] = {
            [WakeUp.NOTIFICATION] = wakeup_notification,
        },
    },
    lifecycle_handlers = {
        doConfigure = eco_doConfigure,
    },
    sub_drivers = {
        require("ecolink-sensor/ecolink-flood"),
        require("ecolink-sensor/ecolink-tilt")
    },
    can_handle = can_handle_ecolink,
}

return ecolink_sensor