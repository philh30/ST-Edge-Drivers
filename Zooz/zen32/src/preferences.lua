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
  ZEN32 = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x7000,
      product_ids = 0xA008
    },
    PARAMETERS = {
      relayAutoTurnOff        = {type = 'config', parameter_number = 16, size = 4},
      relayAutoTurnOn         = {type = 'config', parameter_number = 17, size = 4},
      stateAfterPowerFailure  = {type = 'config', parameter_number = 18, size = 1},
      relayControl            = {type = 'config', parameter_number = 19, size = 1},
      disabledRelayReporting  = {type = 'config', parameter_number = 20, size = 1},
      threeWaySwitchType      = {type = 'config', parameter_number = 21, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 10, addhub = false},
      assocGroup3             = {type = 'assoc', group = 3, maxnodes = 10, addhub = false},
      assocGroup4             = {type = 'assoc', group = 4, maxnodes = 10, addhub = false},
      assocGroup5             = {type = 'assoc', group = 5, maxnodes = 10, addhub = false},
      assocGroup6             = {type = 'assoc', group = 6, maxnodes = 10, addhub = false},
      assocGroup7             = {type = 'assoc', group = 7, maxnodes = 10, addhub = false},
      assocGroup8             = {type = 'assoc', group = 8, maxnodes = 10, addhub = false},
      assocGroup9             = {type = 'assoc', group = 9, maxnodes = 10, addhub = false},
      assocGroup10            = {type = 'assoc', group = 10, maxnodes = 10, addhub = false},
      assocGroup11            = {type = 'assoc', group = 11, maxnodes = 10, addhub = false},
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
