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

local capabilities = require "st.capabilities"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.Driver
local ZwaveDriver = require "st.zwave.driver"
--- @type st.zwave.defaults
local defaults = require "st.zwave.defaults"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })

local preferences = require "preferences"
local configurations = require "configurations"

local customCap = {}
customCap.deviceNetworkId = {}
customCap.deviceNetworkId.name = "platemusic11009.deviceNetworkId"
customCap.deviceNetworkId.capability = capabilities[customCap.deviceNetworkId.name]

---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local function updateNetworkId(self, device, deviceId)
  -- Set our zwave deviceNetworkID 
  for _, component in pairs(device.profile.components) do
    if device:supports_capability_by_id(customCap.deviceNetworkId.name,component.id) then
      local fmtDeviceId = "[" .. deviceId .. "]"
      device:emit_component_event(component,capabilities[customCap.deviceNetworkId.name].deviceNetworkId({value = fmtDeviceId }))
    end
  end
end

--- Handle preference changes
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function info_changed(self, device, event, args)
  if not device:is_cc_supported(cc.WAKE_UP) then
    preferences.update_preferences(self, device, args)
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local function device_init(self, device)
  device:set_update_preferences_fn(preferences.update_preferences)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  device.log.trace("do_configure()")
  configurations.initial_configuration(driver, device)
  device:refresh()

  -- Setup the initial preferences
  device.log.debug("setting up initial preferences")
  preferences.update_preferences(driver, device)

  -- Handle zwave plus lifeline associations
  if device:is_cc_supported(cc.ZWAVEPLUS_INFO) and
      device:is_cc_supported(cc.ASSOCIATION)  then
      -- Add us to lifeline
    device.log.debug("Adding to lifeline")
    device:send(Association:Set({grouping_identifier = 1, node_ids ={driver.environment_info.hub_zwave_id}}))
    device:send(Association:Get({grouping_identifier = 1}))
  end
end

local initial_events_map = {
  [capabilities.tamperAlert.ID] = capabilities.tamperAlert.tamper.clear(),
  [capabilities.waterSensor.ID] = capabilities.waterSensor.water.dry(),
  [capabilities.moldHealthConcern.ID] = capabilities.moldHealthConcern.moldHealthConcern.good(),
  [capabilities.contactSensor.ID] = capabilities.contactSensor.contact.closed(),
  [capabilities.smokeDetector.ID] = capabilities.smokeDetector.smoke.clear(),
  [capabilities.motionSensor.ID] = capabilities.motionSensor.motion.inactive(),
  [capabilities.temperatureAlarm.ID] = capabilities.temperatureAlarm.temperatureAlarm.cleared()
}

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local function added_handler(self, device)
  for id, event in pairs(initial_events_map) do
    if device:supports_capability_by_id(id) then
      device:emit_event(event)
    end
  end
  updateNetworkId(self, device, device.device_network_id)
end

local driver_template = {
  supported_capabilities = {
    capabilities.waterSensor,
    capabilities.colorControl,
    capabilities.contactSensor,
    capabilities.motionSensor,
    capabilities.relativeHumidityMeasurement,
    capabilities.illuminanceMeasurement,
    capabilities.battery,
    capabilities.tamperAlert,
    capabilities.temperatureAlarm,
    capabilities.temperatureMeasurement,
    capabilities.switch,
    capabilities.moldHealthConcern,
    capabilities.dewPoint,
    capabilities.ultravioletIndex,
    capabilities.accelerationSensor,
    capabilities.atmosphericPressureMeasurement,
    capabilities.threeAxis,
    capabilities.bodyWeightMeasurement,
    capabilities.voltageMeasurement,
    capabilities.energyMeter,
    capabilities.powerMeter,
    capabilities.smokeDetector
  },
  sub_drivers = {
    require("ecolink-tilt"),
    require("zooz-motion-sensor"),
    require("fortrezz-leak"),
    require("homeseer-leak")
  },
  lifecycle_handlers = {
    added       = added_handler,
    init        = device_init,
    infoChanged = info_changed,
    doConfigure = do_configure
  },
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
--- @type st.zwave.Driver
local sensor = ZwaveDriver("zwave_sensor", driver_template)
sensor:run()
