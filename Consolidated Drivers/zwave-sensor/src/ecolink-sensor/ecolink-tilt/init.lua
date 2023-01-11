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

-- Ecolink garage door tilt sensor TLT-ZWAVE2.5ECO (Zwave Plus)
-- Wake up Interval
-- Device defaults to 12 hour wake up interval.  This value is adjustable from 3600 seconds (1 hour) to 604800 seconds (1 week) in 200 second increments.
-- It rounds down to the nearest 3600 + 200 second interval (entering 3605 == 3600, 3799 = 3600, 3805 = 3800, etc)
-- This driver offers its parameter in minutes to make the input easier.

-- Parameters:
-- Parameter 1 configures the sensor to send or not send Basic Set commands of 0x00 to nodes in Association group 2
-- turning the devices off when the sensor is in a restored state i.e. the door is closed. 
-- By default the sensor does NOT send Basic Set commands to Association Group 2.

-- Parameter 2 configures the sensor to either to send or not to send Sensor Binary Report commands to Association Group 1 when the sensor is faulted and
-- restored.  This is in addition to the Notification events sent as well.
-- Having the dual messages for each state change may be a feature to reduce the chances of a lost message at the cost of slightly more battery usage 
-- and traffic.     
--
-- Association
-- This sensor has TWO Association groups of 5 nodes each. 
--
-- Group 1 is a lifeline group who will receive unsolicited messages relating to door/window open/close notifications 
--  (because there is no association group for tilt switches), case tampering notifications, low-battery notifications, and sensor binary reports. 
-- 
-- Group 2 is intended for devices that are to be controlled i.e. turned on or off (on only by default) with a Basic Set.
--
-- On inclusion the controller is added to group 1 (lifeline).
--
--  Cluster and versions supported
--      0x20: 1,   // Basic V1 
--      0x30: 2,   // Sensor Binary V2 (spec says V1 but device supports V2)
--      0x59: 1,   // Association Group Info V1
--      0x5E: 1,   // Zwave Plus Info V1
--      0x70: 1,   // Configuration V1
--      0x71: 4,   // Notification V4
--      0x72: 1,   // Manufacturer Specific V1
--      0x73: 1,   // Powerlevel V1
--      0x80: 1,   // Battery V1
--      0x84: 1,   // Wakeup V1
--      0x85: 1,   // Association V1
--      0x86: 1,   // Version V1

local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 2})
local cc = require "st.zwave.CommandClass"

local ECOLINK_TILT_FINGERPRINTS = {
    { mfr = 0x014A, prod = 0x0001, model = 0x0003 }, -- Ecolink Tilt Sensor 2 (zwave)
    { mfr = 0x014A, prod = 0x0004, model = 0x0002 }, -- Ecolink Door/Window Sensor 2.5 (zwave plus)
    { mfr = 0x014A, prod = 0x0004, model = 0x0003 }, -- Ecolink Tilt Sensor 2.5 (zwave plus)
}

local function can_handle_ecolink_tilt(opts, driver, device, ...)
    for _, fingerprint in ipairs(ECOLINK_TILT_FINGERPRINTS) do
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

---  Handler for binary sensor command class reports
---
--- This converts Ecolink binary sensor reports to contact open/closed events 
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SensorBinary.Report
local function sensor_binary_report_handler(self, device, cmd)
  -- The WAVE2 version sends a BINARY REPORT V1, which does not contain the sensor type.
  -- The WAVE2.5 version sends a BINARY REPORT V2 which contains the sensor type "FIRST"
  if (cmd.args.sensor_type == nil) or (cmd.args.sensor_type == SensorBinary.sensor_type.FIRST) then   -- Sends sensor type of 0xFF
    -- Change to a door/window sensor and call default handers
    cmd.args.sensor_type = SensorBinary.sensor_type.DOOR_WINDOW
    call_parent_handler(self.zwave_handlers[cc.SENSOR_BINARY][SensorBinary.REPORT], self, device, cmd)
  end
end

local ecolink_tilt = {
    NAME = "Ecolink Tilt Sensor",
    zwave_handlers = {
        [cc.SENSOR_BINARY] = {
            [SensorBinary.REPORT] = sensor_binary_report_handler
        },
    },
    can_handle = can_handle_ecolink_tilt,
}

return ecolink_tilt