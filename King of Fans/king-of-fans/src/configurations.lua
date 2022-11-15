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

local clusters = require "st.zigbee.zcl.clusters"
local constants = require "st.zigbee.constants"

local OnOff = clusters.OnOff
local Level = clusters.Level
local FanControl = clusters.FanControl

local devices = {
  KING_OF_FANS = {
    FINGERPRINTS = {
      { mfr = "King Of Fans,  Inc.", model = "HDC52EastwindFan" },
      { mfr = "King Of Fans,  Inc.", model = "HBUniversalCFRemote" },
      { mfr = "King Of Fans, Inc.", model = "HDC52EastwindFan" },
      { mfr = "King Of Fans, Inc.", model = "HBUniversalCFRemote" },
    },
    CONFIGURATION = {
      {
        cluster = OnOff.ID,
        attribute = OnOff.attributes.OnOff.ID,
        minimum_interval = 0,
        maximum_interval = 600,
        data_type = OnOff.attributes.OnOff.base_type
      },
      {
        cluster = Level.ID,
        attribute = Level.attributes.CurrentLevel.ID,
        minimum_interval = 1,
        maximum_interval = 600,
        data_type = Level.attributes.CurrentLevel.base_type,
        reportable_change = 1
      },
      {
        cluster = FanControl.ID,
        attribute = FanControl.attributes.FanMode.ID,
        minimum_interval = 1,
        maximum_interval = 600,
        data_type = FanControl.attributes.FanMode.base_type
      }
    }
  },
}

local configurations = {}

configurations.get_device_configuration = function(zigbee_device)
  for _, device in pairs(devices) do
    for _, fingerprint in pairs(device.FINGERPRINTS) do
      if zigbee_device:get_manufacturer() == fingerprint.mfr and zigbee_device:get_model() == fingerprint.model then
        return device.CONFIGURATION
      end
    end
  end
  return nil
end

configurations.get_ias_zone_config_method = function(zigbee_device)
  for _, device in pairs(devices) do
    for _, fingerprint in pairs(device.FINGERPRINTS) do
      if zigbee_device:get_manufacturer() == fingerprint.mfr and zigbee_device:get_model() == fingerprint.model then
        return device.IAS_ZONE_CONFIG_METHOD
      end
    end
  end
  return nil
end

return configurations
