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
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version=2 })
local splitAssocString = require "split_assoc_string"

local preferences = {}

preferences.hours_to_seconds = function(hours)
  local seconds = tonumber(hours) * 60 * 60
  return seconds
end

preferences.temp_multiplier = function(temp)
  return tonumber(temp) * 10
end

local devices = {
  ZOOZ_4_IN_1_SENSOR = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x2021,
      product_ids = 0x2101
    },
    PARAMETERS = {
      temperatureScale     = {type = 'config', parameter_number = 1, size = 1},
      temperatureChange    = {type = 'config', parameter_number = 2, size = 1},
      humidityChange       = {type = 'config', parameter_number = 3, size = 1},
      illuminanceChange    = {type = 'config', parameter_number = 4, size = 1},
      motionInterval       = {type = 'config', parameter_number = 5, size = 1},
      motionSensitivity    = {type = 'config', parameter_number = 6, size = 1},
      ledMode              = {type = 'config', parameter_number = 7, size = 1}
    }
  },
  ZOOZ_Q_SENSOR = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = {0x0200, 0x0201, 0x0202},
      product_ids = 0x0006
    },
    PARAMETERS = {
      motionSensitivity    = {type = 'config', parameter_number = 12, size = 1},
      motionInterval       = {type = 'config', parameter_number = 13, size = 2},
      ledMode              = {type = 'config', parameter_number = 19, size = 1},
      reportFrequency      = {type = 'config', oarameter_number = 172, size = 2},
      temperatureChange    = {type = 'config', parameter_number = 183, size = 2},
      humidityChange       = {type = 'config', parameter_number = 184, size = 1},
      illuminanceChange    = {type = 'config', parameter_number = 185, size = 2},
    }
  },
  ZOOZ_ZSE41 = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x7000,
      product_ids = 0xE001
    },
    PARAMETERS = {
      ledMode              = {type = 'config',parameter_number = 1, size = 1},
      batteryReporting     = {type = 'config',parameter_number = 3, size = 1},
      lowBatteryReporting  = {type = 'config',parameter_number = 4, size = 1},
      statusReporting      = {type = 'config',parameter_number = 5, size = 1},
      assocOnDelay         = {type = 'config',parameter_number = 6, size = 4},
      assocOffDelay        = {type = 'config',parameter_number = 7, size = 4},
      
      assocGroup2          = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    }
  },
  HOMESEER_LS100PLUS = {
    MATCHING_MATRIX = {
      mfrs = 0x000C,
      product_types = 0x0201,
      product_ids = 0x000A
    },
    PARAMETERS = {
      basicSetCommand      = { type = 'config', parameter_number = 14, size = 1 },  -- P14: BasicSet enabled/disabled
      leakReportInterval   = { type = 'config', parameter_number = 17, size = 1 },  -- P17: Leak reporting interval
      shockSensor          = { type = 'config', parameter_number = 18, size = 1 },  -- P18: Enable Shock Sensor
      tempReportInterval   = { type = 'config', parameter_number = 19, size = 1 },  -- P19: Temperature reporting interval
      tempTriggerHighValue = { type = 'config', parameter_number = 20, size = 2, conversion = preferences.temp_multiplier },  -- P20:
      tempTriggerLowValue  = { type = 'config', parameter_number = 22, size = 2, conversion = preferences.temp_multiplier },  -- P22:
      blinkLEDAlarm        = { type = 'config', parameter_number = 24, size = 1 },  -- P24: Blink LED with alarm

      wakeUpInterval       = { type = 'wakeup', conversion = preferences.hours_to_seconds }, -- Wake up interval, is in hours (0-744)

      assocGroup2          = { type = 'assoc', group = 2, maxnodes = 5, addhub = false }
    }
  },
  ECOLINK_TILT25 = {  -- Ecolink Tilt Sensor TILT-ZWAVE2.5-ECO
    MATCHING_MATRIX = {
      mfrs          = 0x014A,
      product_types = 0x0004,
      product_ids   = 0x0003
    }, 
    PARAMETERS = {
      basicSetCommand      = { type = 'config', parameter_number = 1, size = 1 }, -- P1: BasicSet enabled/disabled for association group 2
      sensorBinary         = { type = 'config', parameter_number = 2, size = 1 }, -- P2: Disable Binary Reports

      wakeUpInterval       = { type = 'wakeup' }, -- Wake up interval, preference is in seconds

      assocGroup2          = { type = 'assoc', group = 2, maxnodes = 5, addhub = false }
    }
  },
}

preferences.update_preferences = function(driver, device, args)
  local get_params = {}
  local prefs = preferences.get_device_parameters(device)
  if prefs ~= nil then
    for id, value in pairs(device.preferences) do
      -- If the device.preferences id is in our preferences table
      --  AND 
      --     we have no previous preferences to compare to
      --     OR the previous preference value is different than the current preference value
      -- THEN update the device 
      if prefs[id] and (not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value)) then
        device.log.trace("update_preferences(): updating id: ".. id)
        if prefs[id].type == 'config' then
          local new_parameter_value = preferences.to_numeric_value(device.preferences[id])
          if type(prefs[id].conversion) == "function" then
            new_parameter_value = prefs[id].conversion(new_parameter_value)
          end
          local size = prefs[id].size
          -- Handle unsigned int
          new_parameter_value = ((new_parameter_value >= (256^size)/2) and (new_parameter_value < 256^size)) and (new_parameter_value-256^size) or new_parameter_value
          device:send(Configuration:Set({parameter_number = prefs[id].parameter_number, size = size, configuration_value = new_parameter_value}))
          table.insert(get_params, prefs[id].parameter_number)
        elseif prefs[id].type == 'wakeup' then
          local wakeUpInterval = preferences.to_numeric_value(device.preferences[id])
          if type(prefs[id].conversion) == "function" then
            wakeUpInterval = prefs[id].conversion(wakeUpInterval)
          end
          device:send(WakeUp:IntervalSet({node_id = driver.environment_info.hub_zwave_id, seconds = wakeUpInterval}))
          device:send(WakeUp:IntervalGet({}))
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
  -- Get any parameters we set
  for _, param_number in pairs(get_params) do
    device:send(Configuration:Get({parameter_number = param_number }))
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
