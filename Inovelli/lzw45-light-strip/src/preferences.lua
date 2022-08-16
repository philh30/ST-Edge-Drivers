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
  lzw45 = {
    MATCHING_MATRIX = {
      mfrs = 0x031E,
      product_types = 0x000A,
      product_ids = 0x0001
    },
    PARAMETERS = {
      parameter001            = {type = 'config', parameter_number = 1, size = 1},
      parameter002            = {type = 'config', parameter_number = 2, size = 1},
      parameter003            = {type = 'config', parameter_number = 3, size = 1},
      parameter004            = {type = 'config', parameter_number = 4, size = 1},
      parameter005            = {type = 'config', parameter_number = 5, size = 1},
      parameter006            = {type = 'config', parameter_number = 6, size = 2},
      parameter007            = {type = 'config', parameter_number = 7, size = 1},
      parameter008            = {type = 'config', parameter_number = 8, size = 1},
      parameter009            = {type = 'config', parameter_number = 9, size = 4},
      parameter010            = {type = 'config', parameter_number = 10, size = 1},
      parameter017            = {type = 'config', parameter_number = 17, size = 1},
      parameter018            = {type = 'config', parameter_number = 18, size = 2},
      parameter019            = {type = 'config', parameter_number = 19, size = 1},
      parameter051            = {type = 'config', parameter_number = 51, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
      assocGroup3             = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
      assocGroup4             = {type = 'assoc', group = 4, maxnodes = 5, addhub = false},
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
