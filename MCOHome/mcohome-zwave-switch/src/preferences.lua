-- Copyright 2022 SmartThings
-- Modified 2022 philh30 - MCOHome devices
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
  MCOHOME_2_LEGACY = {
    MATCHING_MATRIX = {
      mfrs = 0x015F,
      product_types = 0x3121,
      product_ids = 0x1302
    },
    PARAMETERS = {
      assocGroup1       = {type = 'assoc', group = 1, maxnodes = 5, addhub = false},
      assocGroup2       = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    },
  },
  MCOHOME_4_LEGACY = {
    MATCHING_MATRIX = {
      mfrs = 0x015F,
      product_types = 0x3141,
      product_ids = 0x1302
    },
    PARAMETERS = {
      assocGroup1       = {type = 'assoc', group = 1, maxnodes = 5, addhub = false},
      assocGroup2       = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
      assocGroup3       = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
      assocGroup4       = {type = 'assoc', group = 4, maxnodes = 5, addhub = false},
    },
  },
  MCOHOME_4 = {
    MATCHING_MATRIX = {
      mfrs = 0x015F,
      product_types = 0x3141,
      product_ids = 0x5102
    },
    PARAMETERS = {
      assocGroup2       = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
      assocGroup5       = {type = 'assoc', group = 5, maxnodes = 5, addhub = false},
      assocGroup8       = {type = 'assoc', group = 8, maxnodes = 5, addhub = false},
      assocGroup11      = {type = 'assoc', group = 11, maxnodes = 5, addhub = false},
    },
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
