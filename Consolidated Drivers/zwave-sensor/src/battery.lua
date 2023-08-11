-- Copyright 2022 csstup
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

-- Functions to track battery updates from devices.
-- Stores the last date/time a battery update was received.
-- Uses the device.preferences.batteryInterval value to determine if its time to request
--  a battery update.

local LAST_BATTERY_REPORT_TIME = "lastBatteryReportTime"
local battery = {}

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
function battery.on_battery_report(self, device)
  -- Save the timestamp of the last battery report received.
  device:set_field(LAST_BATTERY_REPORT_TIME, os.time(), { persist = true } )
end

-- Request a battery update from the device.
-- This should only be called when the radio is known to be listening
-- (during initial inclusion/configuration and during Wakeup)
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
function battery.getBatteryUpdate(self, device, force)
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

  if not force then 
    device.log.debug("No battery update needed")
  end

  return force
end

return battery