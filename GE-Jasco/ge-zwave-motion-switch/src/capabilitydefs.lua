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

local capabilities = require('st.capabilities')

local capabilitydefs = {}

capabilitydefs.LightSensing = {}
capabilitydefs.LightSensing.name = "platinummassive43262.jascoLightSensing"
capabilitydefs.LightSensing.capability = capabilities[capabilitydefs.LightSensing.name]

capabilitydefs.OperationMode = {}
capabilitydefs.OperationMode.name = "platinummassive43262.jascoOperationMode"
capabilitydefs.OperationMode.capability = capabilities[capabilitydefs.OperationMode.name]

capabilitydefs.MotionSensitivity = {}
capabilitydefs.MotionSensitivity.name = "platinummassive43262.jascoMotionSensitivity"
capabilitydefs.MotionSensitivity.capability = capabilities[capabilitydefs.MotionSensitivity.name]

capabilitydefs.TimeoutDuration = {}
capabilitydefs.TimeoutDuration.name = "platinummassive43262.jascoTimeoutDuration"
capabilitydefs.TimeoutDuration.capability = capabilities[capabilitydefs.TimeoutDuration.name]

capabilitydefs.TimeoutDuration = {}
capabilitydefs.TimeoutDuration.name = "platinummassive43262.jascoTimeoutDuration"
capabilitydefs.TimeoutDuration.capability = capabilities[capabilitydefs.TimeoutDuration.name]

capabilitydefs.DefaultLevel = {}
capabilitydefs.DefaultLevel.name = "platinummassive43262.jascoDefaultLevel"
capabilitydefs.DefaultLevel.capability = capabilities[capabilitydefs.DefaultLevel.name]

return capabilitydefs