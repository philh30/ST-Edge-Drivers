-- Author: philh30
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

local capabilities = require('st.capabilities')

-- statusMessage        = platinummassive43262.statusMessage
-- alarmMode            = platinummassive43262.alarmState
-- alarmCommands        = platinummassive43262.securityPartitionCommands
-- bypass               = platinummassive43262.bypass
-- carbonMonoxideZone   = platinummassive43262.carbonMonoxideZone
-- contactZone          = platinummassive43262.contactZone
-- glassBreakZone       = platinummassive43262.glassBreakZone
-- leakZone             = platinummassive43262.leakZone
-- motionZone           = platinummassive43262.motionZone
-- smokeZone            = platinummassive43262.smokeZone

local capabilitydefs = {}

capabilitydefs.statusMessage = {}
capabilitydefs.statusMessage.name = "platinummassive43262.statusMessage"
capabilitydefs.statusMessage.capability = capabilities[capabilitydefs.statusMessage.name]

capabilitydefs.alarmMode = {}
capabilitydefs.alarmMode.name = "platinummassive43262.alarmMode"
capabilitydefs.alarmMode.capability = capabilities[capabilitydefs.alarmMode.name]

capabilitydefs.bypass = {}
capabilitydefs.bypass.name = "platinummassive43262.bypass"
capabilitydefs.bypass.capability = capabilities[capabilitydefs.bypass.name]

capabilitydefs.carbonMonoxideZone = {}
capabilitydefs.carbonMonoxideZone.name = "platinummassive43262.carbonMonoxideZone"
capabilitydefs.carbonMonoxideZone.capability = capabilities[capabilitydefs.carbonMonoxideZone.name]

capabilitydefs.contactZone= {}
capabilitydefs.contactZone.name = "platinummassive43262.contactZone"
capabilitydefs.contactZone.capability = capabilities[capabilitydefs.contactZone.name]

capabilitydefs.glassBreakZone = {}
capabilitydefs.glassBreakZone.name = "platinummassive43262.glassBreakZone"
capabilitydefs.glassBreakZone.capability = capabilities[capabilitydefs.glassBreakZone.name]

capabilitydefs.leakZone = {}
capabilitydefs.leakZone.name = "platinummassive43262.leakZone"
capabilitydefs.leakZone.capability = capabilities[capabilitydefs.leakZone.name]

capabilitydefs.motionZone = {}
capabilitydefs.motionZone.name = "platinummassive43262.motionZone"
capabilitydefs.motionZone.capability = capabilities[capabilitydefs.motionZone.name]

capabilitydefs.smokeZone = {}
capabilitydefs.smokeZone.name = "platinummassive43262.smokeZone"
capabilitydefs.smokeZone.capability = capabilities[capabilitydefs.smokeZone.name]

return capabilitydefs
