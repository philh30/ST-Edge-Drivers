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

--
-- Support subdriver for zwave battery devices.
-- 
local capabilities = require "st.capabilities"
--- @type st.zwave.CommandClass.Battery
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
local cc = require "st.zwave.CommandClass"

local call_parent_handler = require "call_parent"
local battery = require "battery"

-- If we have a battery capability and we support the BATTERY CC 
local function can_handle_battery_device(opts, driver, device, ...)
  return device:supports_capability_by_id(capabilities.battery.ID) and device:is_cc_supported(cc.BATTERY)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Battery.Report
local function battery_report(self, device, cmd)
  -- Save the timestamp of the last battery report received.
  battery.on_battery_report(self, device)
  if cmd.args.battery_level == 99 then cmd.args.battery_level = 100 end
  if cmd.args.battery_level == 0xFF then cmd.args.battery_level = 1 end
  -- Forward on to the default battery report handlers from the top level
  call_parent_handler(self.zwave_handlers[cc.BATTERY][Battery.REPORT], self, device, cmd)
end

local battery_device = {
    NAME = "Battery",
    zwave_handlers = {
        [cc.BATTERY] = {
          [Battery.REPORT] = battery_report,
        },
    },
    can_handle = can_handle_battery_device,
}

return battery_device