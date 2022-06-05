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

--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })
local splitAssocString = require "split_assoc_string"

local devices = {
  ZOOZ_4_IN_1_SENSOR = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x2021,
      product_ids = 0x2101
    },
    PARAMETERS = {
      temperatureScale = {type = 'config', parameter_number = 1, size = 1},
      temperatureChange = {type = 'config', parameter_number = 2, size = 1},
      humidityChange = {type = 'config', parameter_number = 3, size = 1},
      illuminanceChange = {type = 'config', parameter_number = 4, size = 1},
      motionInterval = {type = 'config', parameter_number = 5, size = 1},
      motionSensitivity = {type = 'config', parameter_number = 6, size = 1},
      ledMode = {type = 'config', parameter_number = 7, size = 1}
    }
  },
  ZOOZ_Q_SENSOR = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = {0x0200, 0x0201, 0x0202},
      product_ids = 0x0006
    },
    PARAMETERS = {
      motionSensitivity = {type = 'config', parameter_number = 12, size = 1},
      motionInterval = {type = 'config', parameter_number = 13, size = 2},
      ledMode = {type = 'config', parameter_number = 19, size = 1},
      reportFrequency = {type = 'config', oarameter_number = 172, size = 2},
      temperatureChange = {type = 'config', parameter_number = 183, size = 2},
      humidityChange = {type = 'config', parameter_number = 184, size = 1},
      illuminanceChange = {type = 'config', parameter_number = 185, size = 2},
    }
  },
  ZOOZ_ZSE41 = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x7000,
      product_ids = 0xE001
    },
    PARAMETERS = {
      ledMode = {type = 'config',parameter_number = 1, size = 1},
      batteryReporting = {type = 'config',parameter_number = 3, size = 1},
      lowBatteryReporting = {type = 'config',parameter_number = 4, size = 1},
      statusReporting = {type = 'config',parameter_number = 5, size = 1},
      assocOnDelay = {type = 'config',parameter_number = 6, size = 4},
      assocOffDelay = {type = 'config',parameter_number = 7, size = 4},
      assocGroup2 = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    }
  },
}
local preferences = {}

preferences.update_preferences = function(driver, device, args)
  local prefs = preferences.get_device_parameters(device)
  if prefs ~= nil then
    for id, value in pairs(device.preferences) do
      if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value and prefs and prefs[id]) then
        if prefs[id].type == 'config' then
          local new_parameter_value = preferencesMap.to_numeric_value(device.preferences[id])
          device:send(Configuration:Set({parameter_number = prefs[id].parameter_number, size = prefs[id].size, configuration_value = new_parameter_value}))
          device:send(Configuration:Get({parameter_number = prefs[id].parameter_number}))
        elseif prefs[id].type == 'assoc' then
          local group = prefs[id].group
          local maxnodes = prefs[id].maxnodes
          local addhub = prefs[id].addhub
          local nodes = splitAssocString(value,',',maxnodes,addhub)
          local hubnode = device.driver.environment_info.hub_zwave_id
          device:send(Association:Remove({grouping_identifier = group, node_ids = {}}))
          if addhub then device:send(Association:Set({grouping_identifier = group, node_ids = {hubnode}})) end
          if #nodes > 0 then
            device:send(Association:Set({grouping_identifier = group, node_ids = nodes}))
          end
          device:send(Association:Get({grouping_identifier = group}))
        end
      end
    end
  end
end

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
