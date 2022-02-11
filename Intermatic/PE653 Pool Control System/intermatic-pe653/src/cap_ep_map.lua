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
local capdefs = require "capabilitydefs"
local get = require "get_constants"
local log = require "log"

local config = {}

config.CAP_MAP = {
  main = {
    switch = 'switch1',
    [capdefs.activeMode.name] = 'activeMode',
    [capdefs.activeSetpoint.name] = 'activeSetpoint',
    [capdefs.pumpSpeed.name] = 'vspSpeed',
    [capdefs.pumpRPM.name] = 'vspRPM',
    thermostatHeatingSetpoint = 'thermostatSetpointPool',
    temperatureMeasurement = 'waterTemp',
    thermostatOperatingState = 'heater',
    [capdefs.firmwareVersion.name] = 'firmwareVersion',
    [capdefs.poolSpaConfig.name] = 'poolSpaConfig',
    [capdefs.pumpTypeConfig.name] = 'pumpTypeConfig',
    [capdefs.boosterPumpConfig.name] = 'boosterPumpConfig',
  },
  heater = {
    [capdefs.firemanConfig.name] = 'firemanConfig',
    [capdefs.heaterSafetyConfig.name] = 'heaterSafetyConfig',
  },
  vsp = {
    [capdefs.vspSpeed1.name] = 'VSP_SPD_SETTING_1',
    [capdefs.vspSpeed2.name] = 'VSP_SPD_SETTING_2',
    [capdefs.vspSpeed3.name] = 'VSP_SPD_SETTING_3',
    [capdefs.vspSpeed4.name] = 'VSP_SPD_SETTING_4',
    [capdefs.vspSpeedMax.name] = 'VSP_MAX_PUMP_SPEED',
  },
  freezeControl = {
    [capdefs.tempFreezeControl.name] = 'freezeThreshold',
    [capdefs.circuit1FreezeControl.name] = 'freezeSwitch1',
    [capdefs.circuit2FreezeControl.name] = 'freezeSwitch2',
    [capdefs.circuit3FreezeControl.name] = 'freezeSwitch3',
    [capdefs.circuit4FreezeControl.name] = 'freezeSwitch4',
    [capdefs.circuit5FreezeControl.name] = 'freezeSwitch5',
    [capdefs.vspFreezeControl.name] = 'freezeVsp',
    [capdefs.heaterFreezeControl.name] = 'freezeHeater',
    [capdefs.poolSpaFreezeControl.name] = 'freezePoolSpaCycle'
  },
  temperatureOffsets = {
    [capdefs.waterOffset.name] = 'waterTempOffset',
    [capdefs.airOffset.name] = 'airTempOffset',
    [capdefs.solarOffset.name] = 'solarTempOffset',
  },
  pool = {
    [capdefs.pumpSpeed.name] = 'vspSpeed',
    [capdefs.pumpRPM.name] = 'vspRPM',
    thermostatHeatingSetpoint = 'thermostatSetpointPool',
    temperatureMeasurement = 'waterTemp',
    thermostatOperatingState = 'heater',
  },
  spa = {
    switch = 'poolSpaMode',
    [capdefs.pumpSpeed.name] = 'vspSpeed',
    [capdefs.pumpRPM.name] = 'vspRPM',
    thermostatHeatingSetpoint = 'thermostatSetpointSpa',
    temperatureMeasurement = 'waterTemp',
    thermostatOperatingState = 'heater',
  },
  circuit1 = { switch = 'switch1' },
  circuit2 = { switch = 'switch2' },
  circuit3 = { switch = 'switch3' },
  circuit4 = { switch = 'switch4' },
  circuit5 = { switch = 'switch5' },
  air = {temperatureMeasurement = 'airTemp',},
  solar = {temperatureMeasurement = 'solarTemp',},
  schedules = { 
    [capdefs.schedule.name] = 'schedule',
    [capdefs.scheduleTime.name] = 'scheduleTime',
    [capdefs.schedules.name] = 'schedules',
  },
}

config.EP_MAP = {
  firmwareVersion = {
    capability = capdefs.firmwareVersion.name,
    component = { 'main' },
    handler = 'firmware_event',
    cap = capabilities[capdefs.firmwareVersion.name].version,
  },
  poolSpaConfig = {
    capability = capdefs.poolSpaConfig.name,
    component = { 'main' },
    handler = 'string_event',
    cap = capabilities[capdefs.poolSpaConfig.name].poolSpaConfig,
  },
  pumpTypeConfig = {
    capability = capdefs.pumpTypeConfig.name,
    component = { 'main' },
    handler = 'string_event',
    cap = capabilities[capdefs.pumpTypeConfig.name].pumpType,
  },
  boosterPumpConfig = {
    capability = capdefs.boosterPumpConfig.name,
    component = { 'main' },
    handler = 'string_event',
    cap = capabilities[capdefs.boosterPumpConfig.name].boosterPumpConfig,
  },
  firemanConfig = {
    capability = capdefs.firemanConfig.name,
    component = { 'heater' },
    handler = 'string_event',
    cap = capabilities[capdefs.firemanConfig.name].firemanConfig,
  },
  heaterSafetyConfig = {
    capability = capdefs.heaterSafetyConfig.name,
    component = { 'heater' },
    handler = 'string_event',
    cap = capabilities[capdefs.heaterSafetyConfig.name].heaterSafetyConfig,
  },
  VSP_SPD_SETTING_1 = {
    capability = capdefs.vspSpeed1.name,
    component = { 'vsp' },
    handler = 'unit_event',
    unit = 'RPM',
    cap = capabilities[capdefs.vspSpeed1.name].vspSpeed,
  },
  VSP_SPD_SETTING_2 = {
    capability = capdefs.vspSpeed2.name,
    component = { 'vsp' },
    handler = 'unit_event',
    unit = 'RPM',
    cap = capabilities[capdefs.vspSpeed2.name].vspSpeed,
  },
  VSP_SPD_SETTING_3 = {
    capability = capdefs.vspSpeed3.name,
    component = { 'vsp' },
    handler = 'unit_event',
    unit = 'RPM',
    cap = capabilities[capdefs.vspSpeed3.name].vspSpeed,
  },
  VSP_SPD_SETTING_4 = {
    capability = capdefs.vspSpeed4.name,
    component = { 'vsp' },
    handler = 'unit_event',
    unit = 'RPM',
    cap = capabilities[capdefs.vspSpeed4.name].vspSpeed,
  },
  VSP_MAX_PUMP_SPEED = {
    capability = capdefs.vspSpeedMax.name,
    component = { 'vsp' },
    handler = 'unit_event',
    unit = 'RPM',
    cap = capabilities[capdefs.vspSpeedMax.name].vspSpeed,
  },
  freezeThreshold = {
    capability = capdefs.tempFreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.tempFreezeControl.name].freezeTemperature,
  },
  freezeSwitch1 = {
    capability = capdefs.circuit1FreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.circuit1FreezeControl.name].freezeControl,
  },
  freezeSwitch2 = {
    capability = capdefs.circuit2FreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.circuit2FreezeControl.name].freezeControl,
  },
  freezeSwitch3 = {
    capability = capdefs.circuit3FreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.circuit3FreezeControl.name].freezeControl,
  },
  freezeSwitch4 = {
    capability = capdefs.circuit4FreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.circuit4FreezeControl.name].freezeControl,
  },
  freezeSwitch5 = {
    capability = capdefs.circuit5FreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.circuit5FreezeControl.name].freezeControl,
  },
  freezeVsp = {
    capability = capdefs.vspFreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.vspFreezeControl.name].vspFreeze,
  },
  freezeHeater = {
    capability = capdefs.heaterFreezeControl.name,
    component = { 'freezeControl' },
    handler = 'string_event',
    cap = capabilities[capdefs.heaterFreezeControl.name].heaterFreeze,
  },
  freezePoolSpaCycle = {
    capability = capdefs.poolSpaFreezeControl.name,
    component = { 'freezeControl' },
    handler = 'unit_event',
    unit = 'minutes',
    cap = capabilities[capdefs.poolSpaFreezeControl.name].poolSpaFreezeCycle,
  },
  waterTempOffset = {
    capability = capdefs.waterOffset.name,
    component = { 'temperatureOffsets' },
    handler = 'raw_event',
    cap = capabilities[capdefs.waterOffset.name].tempOffset,
  },
  airTempOffset = {
    capability = capdefs.airOffset.name,
    component = { 'temperatureOffsets' },
    handler = 'raw_event',
    cap = capabilities[capdefs.airOffset.name].tempOffset,
  },
  solarTempOffset = {
    capability = capdefs.solarOffset.name,
    component = { 'temperatureOffsets' },
    handler = 'raw_event',
    cap = capabilities[capdefs.solarOffset.name].tempOffset,
  },
  expansionVersion = {
    handler = 'expansion_version_event',
  },
  activeMode = {
    capability = capdefs.activeMode.name,
    component = { 'main' },
    handler = 'string_event',
    cap = capabilities[capdefs.activeMode.name].activeMode,
  },
  activeSetpoint = {
    capability = capdefs.activeSetpoint.name,
    component = { 'main' },
    handler = 'unit_event',
    unit = 'F',
    cap = capabilities[capdefs.activeSetpoint.name].activeSetpoint,
  },
  vspSpeed = {
    capability = capdefs.pumpSpeed.name,
    component = { 'main', 'pool', 'spa' },
    handler = 'string_event',
    cap = capabilities[capdefs.pumpSpeed.name].vspSpeed,
  },
  vspRPM = {
    capability = capdefs.pumpRPM.name,
    component = { 'main', 'pool', 'spa'},
    handler = 'unit_event',
    unit = 'RPM',
    cap = capabilities[capdefs.pumpRPM.name].vspSpeed,
  },
  heater = {
    capability = 'thermostatOperatingState',
    component = { 'main', 'pool', 'spa' },
    handler = 'basic_event',
    cap = capabilities.thermostatOperatingState.thermostatOperatingState,
    on = 'heating',
    off = 'idle',
  },
  thermostatSetpointPool = {
    capability = 'thermostatHeatingSetpoint',
    component = { 'main', 'pool' },
    handler = 'unit_event',
    unit = 'F',
    cap = capabilities.thermostatHeatingSetpoint.heatingSetpoint,
  },
  thermostatSetpointSpa = {
    capability = 'thermostatHeatingSetpoint',
    component = {'spa'},
    handler = 'unit_event',
    unit = 'F',
    cap = capabilities.thermostatHeatingSetpoint.heatingSetpoint,
  },
  switch1 = {
    capability = 'switch',
    component = { 'circuit1' },
    handler = 'basic_event',
    cap = capabilities.switch.switch,
    on = 'on',
    off = 'off',
  },
  switch2 = {
    capability = 'switch',
    component = { 'circuit2' },
    handler = 'basic_event',
    cap = capabilities.switch.switch,
    on = 'on',
    off = 'off',
  },
  switch3 = {
    capability = 'switch',
    component = { 'circuit3' },
    handler = 'basic_event',
    cap = capabilities.switch.switch,
    on = 'on',
    off = 'off',
  },
  switch4 = {
    capability = 'switch',
    component = { 'circuit4' },
    handler = 'basic_event',
    cap = capabilities.switch.switch,
    on = 'on',
    off = 'off',
  },
  switch5 = {
    capability = 'switch',
    component = { 'circuit5' },
    handler = 'basic_event',
    cap = capabilities.switch.switch,
    on = 'on',
    off = 'off',
  },
  poolSpaMode = {
    capability = 'switch',
    component = { 'spa' },
    handler = 'basic_event',
    cap = capabilities.switch.switch,
    on = 'on',
    off = 'off',
  },
  waterTemp = {
    capability = 'temperatureMeasurement',
    component = { 'main', 'pool', 'spa' },
    handler = 'unit_event',
    unit = 'F',
    cap = capabilities.temperatureMeasurement.temperature,
  },
  airTemp = {
    capability = 'temperatureMeasurement',
    component = { 'air' },
    handler = 'unit_event',
    unit = 'F',
    cap = capabilities.temperatureMeasurement.temperature,
  },
  solarTemp = {
    capability = 'temperatureMeasurement',
    component = { 'solar' },
    handler = 'unit_event',
    unit = 'F',
    cap = capabilities.temperatureMeasurement.temperature,
  },
  schedule = {
    capability = capdefs.schedule.name,
    component = { 'schedules' },
    handler = 'no_action_event',
    cap = capabilities[capdefs.schedule.name].schedule,
  },
  scheduleTime = {
    capability = capdefs.scheduleTime.name,
    component = { 'schedules' },
    handler = 'schedule_event',
    cap = capabilities[capdefs.scheduleTime.name].scheduleTime,
  },
  schedules = {
    capability = capdefs.schedules.name,
    component = { 'schedules' },
    handler = 'string_event',
    cap = capabilities[capdefs.schedules.name].schedules,
  },
}

config.INSTANCE_KEY = {
	switch1 = 1,
	switch2 = 2,
	switch3 = 3,
	switch4 = 4,
	switch5 = 5,
	poolSpaMode = 4,
	vsp1 = get.VSP_CHAN_NO(1),
	vsp2 = get.VSP_CHAN_NO(2),
	vsp3 = get.VSP_CHAN_NO(3),
	vsp4 = get.VSP_CHAN_NO(4),
}

--- @param device st.zwave.Device
--- @param endpoint string
function config.GET_COMP(device,endpoint)
  if config.EP_MAP[endpoint] then
    for _, comp in ipairs(config.EP_MAP[endpoint].component) do
      if device:supports_capability_by_id(config.EP_MAP[endpoint].capability,comp) then
        return comp
      end
    end
  else
    log.error(string.format('Endpoint %s not found in config.EP_MAP',endpoint))
  end
  return nil
end

return config