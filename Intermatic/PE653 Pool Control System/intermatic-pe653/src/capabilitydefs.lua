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

capabilitydefs.firmwareVersion = {}
capabilitydefs.firmwareVersion.name = "platinummassive43262.firmwareVersion"
capabilitydefs.firmwareVersion.capability = capabilities[capabilitydefs.firmwareVersion.name]

capabilitydefs.activeMode = {}
capabilitydefs.activeMode.name = "platinummassive43262.pe653ActiveMode"
capabilitydefs.activeMode.capability = capabilities[capabilitydefs.activeMode.name]

capabilitydefs.activeSetpoint = {}
capabilitydefs.activeSetpoint.name = "platinummassive43262.pe653ActiveSetpoint"
capabilitydefs.activeSetpoint.capability = capabilities[capabilitydefs.activeSetpoint.name]

capabilitydefs.pumpSpeed = {}
capabilitydefs.pumpSpeed.name = "platinummassive43262.pe653VariableSpeedPump"
capabilitydefs.pumpSpeed.capability = capabilities[capabilitydefs.pumpSpeed.name]

capabilitydefs.pumpRPM = {}
capabilitydefs.pumpRPM.name = "platinummassive43262.pe653VspCurrentSpeed"
capabilitydefs.pumpRPM.capability = capabilities[capabilitydefs.pumpRPM.name]

capabilitydefs.schedule = {}
capabilitydefs.schedule.name = "platinummassive43262.pe653Schedule"
capabilitydefs.schedule.capability = capabilities[capabilitydefs.schedule.name]

capabilitydefs.scheduleTime = {}
capabilitydefs.scheduleTime.name = "platinummassive43262.pe653ScheduleTime"
capabilitydefs.scheduleTime.capability = capabilities[capabilitydefs.scheduleTime.name]

capabilitydefs.schedules = {}
capabilitydefs.schedules.name = "platinummassive43262.pe653Schedules"
capabilitydefs.schedules.capability = capabilities[capabilitydefs.schedules.name]

capabilitydefs.poolSpaConfig = {}
capabilitydefs.poolSpaConfig.name = "platinummassive43262.pe653PoolSpaConfig"
capabilitydefs.poolSpaConfig.capability = capabilities[capabilitydefs.poolSpaConfig.name]

capabilitydefs.pumpTypeConfig = {}
capabilitydefs.pumpTypeConfig.name = "platinummassive43262.pe653PumpTypeConfig"
capabilitydefs.pumpTypeConfig.capability = capabilities[capabilitydefs.pumpTypeConfig.name]

capabilitydefs.boosterPumpConfig = {}
capabilitydefs.boosterPumpConfig.name = "platinummassive43262.pe653BoosterPumpConfig"
capabilitydefs.boosterPumpConfig.capability = capabilities[capabilitydefs.boosterPumpConfig.name]

capabilitydefs.firemanConfig = {}
capabilitydefs.firemanConfig.name = "platinummassive43262.pe653FiremanConfig"
capabilitydefs.firemanConfig.capability = capabilities[capabilitydefs.firemanConfig.name]

capabilitydefs.heaterSafetyConfig = {}
capabilitydefs.heaterSafetyConfig.name = "platinummassive43262.pe653HeaterSafetyConfig"
capabilitydefs.heaterSafetyConfig.capability = capabilities[capabilitydefs.heaterSafetyConfig.name]

capabilitydefs.circuit1FreezeControl = {}
capabilitydefs.circuit1FreezeControl.name = "platinummassive43262.pe653Circuit1Freeze"
capabilitydefs.circuit1FreezeControl.capability = capabilities[capabilitydefs.circuit1FreezeControl.name]

capabilitydefs.circuit2FreezeControl = {}
capabilitydefs.circuit2FreezeControl.name = "platinummassive43262.pe653Circuit2Freeze"
capabilitydefs.circuit2FreezeControl.capability = capabilities[capabilitydefs.circuit2FreezeControl.name]

capabilitydefs.circuit3FreezeControl = {}
capabilitydefs.circuit3FreezeControl.name = "platinummassive43262.pe653Circuit3Freeze"
capabilitydefs.circuit3FreezeControl.capability = capabilities[capabilitydefs.circuit3FreezeControl.name]

capabilitydefs.circuit4FreezeControl = {}
capabilitydefs.circuit4FreezeControl.name = "platinummassive43262.pe653Circuit4Freeze"
capabilitydefs.circuit4FreezeControl.capability = capabilities[capabilitydefs.circuit4FreezeControl.name]

capabilitydefs.circuit5FreezeControl = {}
capabilitydefs.circuit5FreezeControl.name = "platinummassive43262.pe653Circuit5Freeze"
capabilitydefs.circuit5FreezeControl.capability = capabilities[capabilitydefs.circuit5FreezeControl.name]

capabilitydefs.vspFreezeControl = {}
capabilitydefs.vspFreezeControl.name = "platinummassive43262.pe653VspFreeze"
capabilitydefs.vspFreezeControl.capability = capabilities[capabilitydefs.vspFreezeControl.name]

capabilitydefs.heaterFreezeControl = {}
capabilitydefs.heaterFreezeControl.name = "platinummassive43262.pe653HeaterFreeze"
capabilitydefs.heaterFreezeControl.capability = capabilities[capabilitydefs.heaterFreezeControl.name]

capabilitydefs.tempFreezeControl = {}
capabilitydefs.tempFreezeControl.name = "platinummassive43262.pe653FreezeTemperature"
capabilitydefs.tempFreezeControl.capability = capabilities[capabilitydefs.tempFreezeControl.name]

capabilitydefs.poolSpaFreezeControl = {}
capabilitydefs.poolSpaFreezeControl.name = "platinummassive43262.pe653PoolSpaFreezeCycle"
capabilitydefs.poolSpaFreezeControl.capability = capabilities[capabilitydefs.poolSpaFreezeControl.name]

capabilitydefs.vspSpeed1 = {}
capabilitydefs.vspSpeed1.name = "platinummassive43262.pe653VspSpeed1Config"
capabilitydefs.vspSpeed1.capability = capabilities[capabilitydefs.vspSpeed1.name]

capabilitydefs.vspSpeed2 = {}
capabilitydefs.vspSpeed2.name = "platinummassive43262.pe653VspSpeed2Config"
capabilitydefs.vspSpeed2.capability = capabilities[capabilitydefs.vspSpeed2.name]

capabilitydefs.vspSpeed3 = {}
capabilitydefs.vspSpeed3.name = "platinummassive43262.pe653VspSpeed3Config"
capabilitydefs.vspSpeed3.capability = capabilities[capabilitydefs.vspSpeed3.name]

capabilitydefs.vspSpeed4 = {}
capabilitydefs.vspSpeed4.name = "platinummassive43262.pe653VspSpeed4Config"
capabilitydefs.vspSpeed4.capability = capabilities[capabilitydefs.vspSpeed4.name]

capabilitydefs.vspSpeedMax = {}
capabilitydefs.vspSpeedMax.name = "platinummassive43262.pe653VspMaxSpeedConfig"
capabilitydefs.vspSpeedMax.capability = capabilities[capabilitydefs.vspSpeedMax.name]

capabilitydefs.waterOffset = {}
capabilitydefs.waterOffset.name = "platinummassive43262.pe653WaterOffset"
capabilitydefs.waterOffset.capability = capabilities[capabilitydefs.waterOffset.name]

capabilitydefs.airOffset = {}
capabilitydefs.airOffset.name = "platinummassive43262.pe653AirOffset"
capabilitydefs.airOffset.capability = capabilities[capabilitydefs.airOffset.name]

capabilitydefs.solarOffset = {}
capabilitydefs.solarOffset.name = "platinummassive43262.pe653SolarOffset"
capabilitydefs.solarOffset.capability = capabilities[capabilitydefs.solarOffset.name]

return capabilitydefs