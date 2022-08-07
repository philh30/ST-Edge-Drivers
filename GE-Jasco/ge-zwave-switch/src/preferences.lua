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

local GE_BASIC = {
  PARAMETERS = {
    ledIndicator    = {type = 'config', parameter_number = 3, size = 1},
    invertSwitch    = {type = 'config', parameter_number = 4, size = 1},
    dimStepsZwave   = {type = 'config', parameter_number = 7, size = 1},
    dimTimeZwave    = {type = 'config', parameter_number = 8, size = 2},
    dimStepsManual  = {type = 'config', parameter_number = 9, size = 1},
    dimTimeManual   = {type = 'config', parameter_number = 10, size = 2},
    dimStepsAll     = {type = 'config', parameter_number = 11, size = 1},
    dimTimeAll      = {type = 'config', parameter_number = 12, size = 2},
    assocGroup2     = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    assocGroup3     = {type = 'assoc', group = 3, maxnodes = 4, addhub = true},
  },
  BUTTONS = {
    count = 1,
    values = {'up_2x','down_2x','pushed_2x'},
  },
}

local GE_SCENE = {
  PARAMETERS = {
    powerReset      = {type = 'config', parameter_number = 1, size = 1},
    energyMode      = {type = 'config', parameter_number = 2, size = 1},
    energyFrequency = {type = 'config', parameter_number = 3, size = 1},
    ledIndicator    = {type = 'config', parameter_number = 3, size = 1},
    invertSwitch    = {type = 'config', parameter_number = 4, size = 1},
    dimRate         = {type = 'config', parameter_number = 6, size = 1},
    switchMode      = {type = 'config', parameter_number = 16, size = 1},
    excludeProtect  = {type = 'config', parameter_number = 19, size = 1},
    minDim          = {type = 'config', parameter_number = 30, size = 1},
    maxBright       = {type = 'config', parameter_number = 31, size = 1},
    defaultBright   = {type = 'config', parameter_number = 32, size = 1},
    assocGroup2     = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    assocGroup3     = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
  },
  BUTTONS = {
    count = 1,
    values = {'up','down','pushed','up_hold','down_hold','held','up_2x','down_2x','pushed_2x','up_3x','down_3x','pushed_3x'},
  },
}
local GE_MOTION = {
  PARAMETERS = {
    timeoutDuration   = {type = 'config', parameter_number = 1, size = 1},
    --assocBright       = {type = 'config', parameter_number = 2, size = 2},
    operationMode     = {type = 'config', parameter_number = 3, size = 1},
    --associationMode   = {type = 'config', parameter_number = 4, size = 1},
    invertSwitch      = {type = 'config', parameter_number = 5, size = 1},
    enableMotion      = {type = 'config', parameter_number = 6, size = 1},
    dimStepsZwave     = {type = 'config', parameter_number = 7, size = 1},
    dimTimeZwave      = {type = 'config', parameter_number = 8, size = 2},
    dimStepsManual    = {type = 'config', parameter_number = 9, size = 1},
    dimTimeManual     = {type = 'config', parameter_number = 10, size = 2},
    dimStepsAll       = {type = 'config', parameter_number = 11, size = 1},
    dimTimeAll        = {type = 'config', parameter_number = 12, size = 2},
    motionSensitivity = {type = 'config', parameter_number = 13, size = 1},
    lightSensing      = {type = 'config', parameter_number = 14, size = 1},
    resetCycle        = {type = 'config', parameter_number = 15, size = 2},
    switchMode        = {type = 'config', parameter_number = 16, size = 1},
    switchLevel       = {type = 'config', parameter_number = 17, size = 1},
    dimRate           = {type = 'config', parameter_number = 18, size = 1},
    excludeProtect    = {type = 'config', parameter_number = 19, size = 1},
    assocGroup2       = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    assocGroup3       = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
  },
  BUTTONS = {}
}

local devices = {
  GE_SWITCH_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952, 0x5257},
      product_ids = {0x3032, 0x3033, 0x3034, 0x3036, 0x3037, 0x3038, 0x3130, 0x3533},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_DIMMER_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4450, 0x4944},
      product_ids = {0x3030, 0x3031, 0x3032, 0x3033, 0x3035, 0x3036, 0x3037, 0x3038, 0x3039, 0x3130, 0x3233},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_FAN_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4944},
      product_ids = {0x3034, 0x3131},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_OUTLET_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952, 0x5252},
      product_ids = {0x3031, 0x3035, 0x3133, 0x3134, 0x3530},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_PLUGIN_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4F50, 0x5052},
      product_ids = {0x3031, 0x3032, 0x3033, 0x3038, 0x3130, 0x3132},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_PLUGDIM_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x5044},
      product_ids = {0x3031, 0x3033, 0x3038, 0x3130, 0x3132},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_SWITCH_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952},
      product_ids = {0x3135, 0x3136, 0x3137, 0x3139, 0x3231, 0x3237, 0x3238},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_DIMMER_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4944},
      product_ids = {0x3235, 0x3237, 0x3333, 0x3334, 0x3339},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_FAN_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4944},
      product_ids = {0x3337},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_OUTLET_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952},
      product_ids = {0x3233,0x3234,0x3235},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_PLUGIN_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4F50},
      product_ids = {0x3034},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_MOTIONSWITCH_ASSOC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x494D},
      product_ids = {0x3031,0x3032},
    },
    PARAMETERS = GE_MOTION.PARAMETERS,
    BUTTONS = GE_MOTION.BUTTONS,
  },
  GE_MOTIONDIMMER_ASSOC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x494D},
      product_ids = {0x3033,0x3034},
    },
    PARAMETERS = GE_MOTION.PARAMETERS,
    BUTTONS = GE_MOTION.BUTTONS,
  },
  GE_HEAVYSWITCH_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4F44},
      product_ids = {0x3032},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
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

preferences.get_buttons = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.BUTTONS
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
