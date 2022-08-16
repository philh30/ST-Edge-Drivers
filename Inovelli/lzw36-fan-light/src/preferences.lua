-- Author: philh30
--
-- Copyright 2021 SmartThings
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
  LZW36 = {
    MATCHING_MATRIX = {
      mfrs = 0x031E,
      product_types = 0x000E,
      product_ids = 0x0001
    },
    PARAMETERS = {
      dimmingSpeed            = {type = 'config', parameter_number = 1, size = 1},
      dimmingSpeedSwitch      = {type = 'config', parameter_number = 2, size = 1},
      rampRate                = {type = 'config', parameter_number = 3, size = 1},
      rampRateSwitch          = {type = 'config', parameter_number = 4, size = 1},
      lightMinLevel           = {type = 'config', parameter_number = 5, size = 1},
      lightMaxLevel           = {type = 'config', parameter_number = 6, size = 1},
      fanMinLevel             = {type = 'config', parameter_number = 7, size = 1},
      fanMaxLevel             = {type = 'config', parameter_number = 8, size = 1},
      lightAutoOffTimer       = {type = 'config', parameter_number = 10, size = 2},
      fanAutoOffTimer         = {type = 'config', parameter_number = 11, size = 2},
      lightDefaultLocal       = {type = 'config', parameter_number = 12, size = 2},
      lightDefaultZwave       = {type = 'config', parameter_number = 13, size = 1},
      fanDefaultLocal         = {type = 'config', parameter_number = 14, size = 1},
      fanDefaultZwave         = {type = 'config', parameter_number = 15, size = 1},
      lightPowerRestore       = {type = 'config', parameter_number = 16, size = 1},
      fanPowerRestore         = {type = 'config', parameter_number = 17, size = 1},
      lightLEDIntensityOff    = {type = 'config', parameter_number = 22, size = 1},
      fanLEDIntensityOff      = {type = 'config', parameter_number = 23, size = 1},
      lightLEDTimeout         = {type = 'config', parameter_number = 26, size = 1},
      fanLEDTimeout           = {type = 'config', parameter_number = 27, size = 1},
      powerReports            = {type = 'config', parameter_number = 28, size = 1},
      periodicPowerEnergy     = {type = 'config', parameter_number = 29, size = 2},
      energyReports           = {type = 'config', parameter_number = 30, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
      assocGroup3             = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
      assocGroup4             = {type = 'assoc', group = 4, maxnodes = 5, addhub = false},
      assocGroup5             = {type = 'assoc', group = 5, maxnodes = 5, addhub = false},
      assocGroup6             = {type = 'assoc', group = 6, maxnodes = 5, addhub = false},
      assocGroup7             = {type = 'assoc', group = 7, maxnodes = 5, addhub = false},
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
