-- Copyright 2022 SmartThings
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

local capabilities = require "st.capabilities"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local log = require "log"

local PowerConfiguration = zcl_clusters.PowerConfiguration

local LINKIND_WATER_LEAK_SENSOR_FINGERPRINTS = {
  { mfr = "LK", model = "A001082"},
}

local function can_handle_linkind_reality_water_leak_sensor(opts, driver, device)
  for _, fingerprint in ipairs(LINKIND_WATER_LEAK_SENSOR_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end


local function battery_voltage_handler(driver, device, value, zb_rx)
  device:emit_event(capabilities.voltageMeasurement.voltage({value = value.value/10, unit = 'V'}))
end

local linkind_water_leak_sensor = {
  NAME = "Linkind water leak sensor",
  zigbee_handlers = {
    attr = {
      [PowerConfiguration.ID] = {
        [PowerConfiguration.attributes.BatteryVoltage.ID] = battery_voltage_handler
      }
    }
  },
  can_handle = can_handle_linkind_reality_water_leak_sensor
}

return linkind_water_leak_sensor