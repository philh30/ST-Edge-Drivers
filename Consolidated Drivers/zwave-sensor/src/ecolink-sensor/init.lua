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

local LAST_BATTERY_REPORT_TIME = "lastBatteryReportTime"

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

local function call_parent_handler(handlers, self, device, event, args)
    if type(handlers) == "function" then
      handlers = { handlers }  -- wrap as table
    end
    for _, func in ipairs( handlers or {} ) do
        func(self, device, event, args)
    end
end

-- Request a battery update from the device.
-- This should only be called when the radio is known to be listening
-- (during initial inclusion/configuration and during Wakeup)
local function getBatteryUpdate(device, force)
    device.log.trace("getBatteryUpdate()")
    if not force then
        -- Calculate if its time
        local last = device:get_field(LAST_BATTERY_REPORT_TIME)
        if last then
            local now = os.time()
            local diffsec = os.difftime(now, last)
            device.log.debug("Last battery update: " .. os.date("%c", last) .. "(" .. diffsec .. " seconds ago)" )
            local wakeup_offset = 60 * 60 * 24  -- Assume 1 day preference

            if tonumber(device.preferences.batteryInterval) < 100 then
                -- interval is a multiple of our wakeup time (in seconds)
                wakeup_offset = tonumber(device.preferences.wakeUpInterval) * tonumber(device.preferences.batteryInterval)
            end

            if wakeup_offset > 0 then
                -- Adjust for about 5 minutes to cover waking up "early"
                wakeup_offset = wakeup_offset - (60 * 5)
                
                -- Has it been longer than our interval?
                force = diffsec >= wakeup_offset
            end
        else
            force = true -- No last battery report, get one now
        end
    end

    if not force then device.log.debug("No battery update needed") end

    if force then
        -- Request a battery update now
        device:send(Battery:Get({}))
    end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
    device.log.trace("wakeup_notification(ecolink-sensor)")

    call_parent_handler(self.zwave_handlers[cc.WAKE_UP][WakeUp.NOTIFICATION], self, device, cmd)

    -- When the cover is restored (tamper switch closed), the device wakes up.  Assume tamper is clear.
    device:emit_event(capabilities.tamperAlert.tamper.clear())

    -- We may need to request a battery update while we're woken up
    getBatteryUpdate(device)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Battery.Report
local function battery_report(self, device, cmd)
    -- Save the timestamp of the last battery report received.
    device:set_field(LAST_BATTERY_REPORT_TIME, os.time(), { persist = true } )
    if cmd.args.battery_level == 99 then cmd.args.battery_level = 100 end
    if cmd.args.battery_level == 0xFF then cmd.args.battery_level = 1 end

    -- Forward on to the default battery report handlers from the top level
    call_parent_handler(self.zwave_handlers[cc.BATTERY][Battery.REPORT], self, device, cmd)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function eco_doConfigure(self, device, event, args)
    device.log.trace("eco_doConfigure()")
    -- Call the topmost 'doConfigure' lifecycle hander to do the default work first
    call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, event, args)

    -- Force a battery update now
    getBatteryUpdate(device, true)
end

local ecolink_sensor = {
    NAME = "Ecolink Sensor",
    zwave_handlers = {
        [cc.WAKE_UP] = {
            [WakeUp.NOTIFICATION] = wakeup_notification,
        },
        [cc.BATTERY] = {
            [Battery.REPORT] = battery_report,
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