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

local devices = {
  ZEN51 = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x0104,
      product_ids = 0x0201
    },
    PARAMETERS = {
      ledIndicator            = {type = 'config', parameter_number = 1, size = 1},
      autoTurnOff             = {type = 'config', parameter_number = 2, size = 2},
      autoTurnOn              = {type = 'config', parameter_number = 3, size = 2},
      powerFailure            = {type = 'config', parameter_number = 4, size = 1},
      sceneControl            = {type = 'config', parameter_number = 5, size = 1},
      smartBulbMode           = {type = 'config', parameter_number = 6, size = 1},
      externalSwitchType      = {type = 'config', parameter_number = 7, size = 1},
      associationReports      = {type = 'config', parameter_number = 8, size = 1},
      relayTypeBehavior       = {type = 'config', parameter_number = 9, size = 1},
      timerUnit               = {type = 'config', parameter_number = 10, size = 1},
      impulseDuration         = {type = 'config', parameter_number = 11, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    }
  },
}

local preferences = {}

preferences.get_device_parameters = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.PARAMETERS
    end
  end
  return nil
end

preferences.to_numeric_value = function(new_value)
  local numeric = tonumber(new_value)
  if numeric == nil then -- in case the value is boolean
    numeric = new_value and 1 or 0
  end
  return numeric
end

return preferences
