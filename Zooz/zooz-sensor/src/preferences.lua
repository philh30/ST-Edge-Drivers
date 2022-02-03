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
  ZOOZ_4_IN_1_SENSOR = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x2021,
      product_ids = 0x2101
    },
    PARAMETERS = {
      temperatureScale = {parameter_number = 1, size = 1},
      temperatureChange = {parameter_number = 2, size = 1},
      humidityChange = {parameter_number = 3, size = 1},
      illuminanceChange = {parameter_number = 4, size = 1},
      motionInterval = {parameter_number = 5, size = 1},
      motionSensitivity = {parameter_number = 6, size = 1},
      ledMode = {parameter_number = 7, size = 1}
    }
  },
  ZOOZ_Q_SENSOR = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = {0x0200, 0x0201, 0x0202},
      product_ids = 0x0006
    },
    PARAMETERS = {
      motionSensitivity = {parameter_number = 12, size = 1},
      motionInterval = {parameter_number = 13, size = 2},
      ledMode = {parameter_number = 19, size = 1},
      reportFrequency = {oarameter_number = 172, size = 2},
      temperatureChange = {parameter_number = 183, size = 2},
      humidityChange = {parameter_number = 184, size = 1},
      illuminanceChange = {parameter_number = 185, size = 2},
    }
  }
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
