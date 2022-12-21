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

-- Ecolink Flood/Freeze sensor FLF-ZWAVE5R1 (Zwave Plus)
-- Wake up Interval
-- Device defaults to 12 hour wake up interval.  This value is adjustable from 3600 seconds (1 hour) to 604800 seconds (1 week) in 200 second increments.
-- It rounds down to the nearest 3600 + 200 second interval (entering 3605 == 3600, 3799 = 3600, 3805 = 3800, etc)
-- This driver offers its parameter in minutes to make the input easier.

-- Association
-- This sensor has ONE Association groups of 5 nodes. 
--
-- Group 1 is a lifeline group who will receive unsolicited messages
--
-- On inclusion the controller is added to group 1 (lifeline).
--
--  Cluster and versions supported
--      0x20: 1,   // Basic V1 
--      0x30: 2,   // Sensor Binary V2
--      0x59: 1,   // Association Group Info V1
--      0x5A: 1,   // Device Reset Locally V1
--      0x5E: 2,   // Zwave Plus Info V2
--      0x71: 5,   // Notification V5
--      0x72: 2,   // Manufacturer Specific V2
--      0x73: 1,   // Powerlevel V1
--      0x80: 1,   // Battery V1
--      0x84: 2,   // Wakeup V2
--      0x85: 2,   // Association V2
--      0x86: 2,   // Version V2

local Notification = (require "st.zwave.CommandClass.Notification")({ version = 5})
local capabilities = require "st.capabilities"
local cc = require "st.zwave.CommandClass"

local ECOLINK_FLOOD_FINGERPRINTS = {
    { mfr = 0x014A, prod = 0x0005, model = 0x0010 }, -- Ecolink Flood/Freeze Sensor 5 (zwave plus)
    { mfr = 0x014A, prod = 0x0005, model = 0x000F }, -- Ecolink Flood/Freeze Sensor 5 (zwave plus)
}

local function can_handle_ecolink_flood(opts, driver, device, ...)
    for _, fingerprint in ipairs(ECOLINK_FLOOD_FINGERPRINTS) do
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

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Notification.Report
local function notification_report(self, device, cmd)
    local water_notification_events_map = {
        [Notification.event.water.LEAK_DETECTED_LOCATION_PROVIDED] = capabilities.waterSensor.water.wet(),
        [Notification.event.water.LEAK_DETECTED] = capabilities.waterSensor.water.wet(), -- Wet report per manual
        [Notification.event.water.LEVEL_DROPPED] = capabilities.waterSensor.water.dry(), -- Dry report per manual
        [Notification.event.water.STATE_IDLE] = capabilities.waterSensor.water.dry(),
        [Notification.event.water.UNKNOWN_EVENT_STATE] = capabilities.waterSensor.water.dry(),
    }
    if (cmd.args.notification_type == Notification.notification_type.WATER) then
        local event
        event = water_notification_events_map[cmd.args.event]
        if (event ~= nil) then device:emit_event_for_endpoint(cmd.src_channel, event) end
    else
        -- Forward on to the default notification report handlers from the top level
        call_parent_handler(self.zwave_handlers[cc.NOTIFICATION][Notification.REPORT], self, device, cmd)
    end
end

local ecolink_flood = {
    NAME = "Ecolink Flood Sensor",
    zwave_handlers = {
        [cc.NOTIFICATION] = {
          [Notification.REPORT] = notification_report
        },
    },
    can_handle = can_handle_ecolink_flood,
}

return ecolink_flood