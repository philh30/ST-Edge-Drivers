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
        [capabilities.accelerationSensor.ID] = {
            [0] = capabilities.accelerationSensor.acceleration.inactive(),
            [1] = capabilities.accelerationSensor.acceleration.active(),
        },
        [capabilities.alarm.ID] = {
            [0] = capabilities.alarm.alarm({value = device.preferences.alarm1 or 'off'}),
            [1] = capabilities.alarm.alarm({value = device.preferences.alarm2 or 'siren'}),
        },
        [capabilities.carbonMonoxideDetector.ID] = {
            [0] = capabilities.carbonMonoxideDetector.carbonMonoxide.clear(),
            [1] = capabilities.carbonMonoxideDetector.carbonMonoxide.detected(),
        },
        [capabilities.contactSensor.ID] = {
            [0] = capabilities.contactSensor.contact.closed(),
            [1] = capabilities.contactSensor.contact.open(),
        },
        [capabilities.lock.ID] = {
            [0] = capabilities.lock.lock.locked(),
            [1] = capabilities.lock.lock.unlocked(),
        },
        [capabilities.motionSensor.ID] = {
            [0] = capabilities.motionSensor.motion.inactive(),
            [1] = capabilities.motionSensor.motion.active(),
        },
        [capabilities.presenceSensor.ID] = {
            [0] = capabilities.presenceSensor.presence({value = 'not present'}),
            [1] = capabilities.presenceSensor.presence({value = 'present'}),
        },
        [capabilities.smokeDetector.ID] = {
            [0] = capabilities.smokeDetector.smoke.clear(),
            [1] = capabilities.smokeDetector.smoke.detected(),
        },
        [capabilities.switch.ID] = {
            [0] = capabilities.switch.switch.off(),
            [1] = capabilities.switch.switch.on(),
        },
        [capabilities.tamperAlert.ID] = {
            [0] = capabilities.tamperAlert.tamper.clear(),
            [1] = capabilities.tamperAlert.tamper.detected(),
        },
        [capabilities.temperatureAlarm.ID] = {
            [0] = capabilities.temperatureAlarm.temperatureAlarm({value = device.preferences.tempAlarm1 or 'cleared'}),
            [1] = capabilities.temperatureAlarm.temperatureAlarm({value = device.preferences.tempAlarm2 or 'heat'}),
        },
        [capabilities.valve.ID] = {
            [0] = capabilities.valve.valve.closed(),
            [1] = capabilities.valve.valve.open(),
        },
        [capabilities.waterSensor.ID] = {
            [0] = capabilities.waterSensor.water.dry(),
            [1] = capabilities.waterSensor.water.wet(),
        },
        [waterLevel] = {
            [0] = capabilities[waterLevel].waterLevel({value = device.preferences.waterLevel1 or 'normal'}),
            [1] = capabilities[waterLevel].waterLevel({value = device.preferences.waterLevel2 or 'high'}),
        },
        [capabilities.windowShade.ID] = {
            [0] = capabilities.windowShade.windowShade.closed(),
            [1] = capabilities.windowShade.windowShade.open(),
            init = capabilities.windowShade.supportedWindowShadeCommands({value = {'open','close'}})
        },
        [capabilities.windowShadeLevel.ID] = {
            [0] = capabilities.windowShadeLevel.shadeLevel({value = 0}),
            [1] = capabilities.windowShadeLevel.shadeLevel({value = 100}),
        },
    }
    return map
end

return cap_map