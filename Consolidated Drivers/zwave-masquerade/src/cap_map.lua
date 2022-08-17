-- Copyright 2022 philh30
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

local capabilities = require "st.capabilities"

local waterLevel = "platinummassive43262.waterLevel"
local waterLevelCap = capabilities[waterLevel]

local function cap_map(device)
    local map= {
        [capabilities.carbonMonoxideDetector.ID] = {
            [0] = capabilities.carbonMonoxideDetector.carbonMonoxide.clear(),
            [1] = capabilities.carbonMonoxideDetector.carbonMonoxide.detected(),
        },
        [capabilities.contactSensor.ID] = {
            [0] = capabilities.contactSensor.contact.closed(),
            [1] = capabilities.contactSensor.contact.open(),
        },
        [capabilities.motionSensor.ID] = {
            [0] = capabilities.motionSensor.motion.inactive(),
            [1] = capabilities.motionSensor.motion.active(),
        },
        [capabilities.smokeDetector.ID] = {
            [0] = capabilities.smokeDetector.smoke.clear(),
            [1] = capabilities.smokeDetector.smoke.detected(),
        },
        [capabilities.waterSensor.ID] = {
            [0] = capabilities.waterSensor.water.dry(),
            [1] = capabilities.waterSensor.water.wet(),
        },
        [waterLevel] = {
            [0] = capabilities[waterLevel].waterLevel({value = device.preferences.waterLevel1 or 'normal'}),
            [1] = capabilities[waterLevel].waterLevel({value = device.preferences.waterLevel2 or 'high'}),
        }
    }
    return map
end

return cap_map