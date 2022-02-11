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

local GE_MOTION = {
  PARAMETERS = {
    --assocBright       = {type = 'config', parameter_number = 2, size = 2},
    --associationMode   = {type = 'config', parameter_number = 4, size = 1},
    invertSwitch      = {type = 'config', parameter_number = 5, size = 1},
    enableMotion      = {type = 'config', parameter_number = 6, size = 1},
    dimStepsZwave     = {type = 'config', parameter_number = 7, size = 1},
    dimTimeZwave      = {type = 'config', parameter_number = 8, size = 2},
    dimStepsManual    = {type = 'config', parameter_number = 9, size = 1},
    dimTimeManual     = {type = 'config', parameter_number = 10, size = 2},
    dimStepsAll       = {type = 'config', parameter_number = 11, size = 1},
    dimTimeAll        = {type = 'config', parameter_number = 12, size = 2},
    resetCycle        = {type = 'config', parameter_number = 15, size = 2},
    switchMode        = {type = 'config', parameter_number = 16, size = 1},
    --switchLevel       = {type = 'config', parameter_number = 17, size = 1},
    dimRate           = {type = 'config', parameter_number = 18, size = 1},
    excludeProtect    = {type = 'config', parameter_number = 19, size = 1},
    assocGroup2       = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    assocGroup3       = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
  },
}

local devices = {
  GE_MOTIONSWITCH = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x494D},
      product_ids = {0x3031,0x3032},
    },
    PARAMETERS = GE_MOTION.PARAMETERS,
    BUTTONS = GE_MOTION.BUTTONS,
  },
  GE_MOTIONDIMMER = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x494D},
      product_ids = {0x3033,0x3034},
    },
    PARAMETERS = GE_MOTION.PARAMETERS,
    BUTTONS = GE_MOTION.BUTTONS,
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
