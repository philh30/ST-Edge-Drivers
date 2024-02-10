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

--- @type st.capabilities
local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local update_preferences = require "update_preferences"

local customCap = {}
customCap.deviceNetworkId = {}
customCap.deviceNetworkId.name = "platemusic11009.deviceNetworkId"
customCap.deviceNetworkId.capability = capabilities[customCap.deviceNetworkId.name]
customCap.firmware= {}
customCap.firmware.name = "platemusic11009.firmware"
customCap.firmware.capability = capabilities[customCap.firmware.name]

--- Map component to en_point
---
--- @param device st.zwave.Device
--- @param component_id string ID
--- @return table dst_channels destination channels e.g. {2} for Z-Wave channel 2 or {} for unencapsulated
local function component_to_endpoint(device, component_id)
  local ep_num = component_id:match("switch(%d)")
  return { ep_num and tonumber(ep_num) }
end

--- Map Z-Wave endpoint to component
---
--- @param device st.zwave.Device
--- @param ep number the endpoint(Z-Wave channel) ID to find the component for
--- @return string the component ID the endpoint matches to
local function endpoint_to_component(device, ep)
  local switch_comp = string.format("switch%d", ep)
  if device.profile.components[switch_comp] ~= nil then
    return switch_comp
  else
    return "main"
  end
end

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

---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local function updateFirmwareVersion(self, device)
  -- Set our zwave updateFirmwareVersion 
  for _, component in pairs(device.profile.components) do
    if device:supports_capability_by_id(customCap.firmware.name,component.id) then
      local fw_major = (((device.st_store or {}).zwave_version or {}).firmware or {}).major
      local fw_minor = (((device.st_store or {}).zwave_version or {}).firmware or {}).minor
      if fw_major and fw_minor then
        local fmtFirmwareVersion= fw_major .. "." .. string.format('%02d',fw_minor)
        device:emit_component_event(component,capabilities[customCap.firmware.name].firmwareVersion({value = tonumber(fmtFirmwareVersion) }))
      end
    end
  end
end

--- Initialize device
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local device_init = function(self, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function info_changed(driver, device, event, args)
  update_preferences(driver, device, args)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function device_added(driver, device)
  updateNetworkId(driver, device, device.device_network_id)
  updateFirmwareVersion(driver, device)
  device:refresh()
end


local driver_template = {
  lifecycle_handlers = {
    init           = device_init,
    infoChanged    = info_changed,
    added          = device_added,
  },
  supported_capabilities = {
    capabilities.switch,
    capabilities.switchLevel,
    capabilities.refresh,
    capabilities.button,
    capabilities.energyMeter,
    capabilities.powerMeter,
    capabilities.motionSensor,
    capabilities.illuminanceMeasurement,
    capabilities.temperatureMeasurement,
    capabilities.colorControl,
    capabilities.colorTemperature,
    capabilities.colorMode,
  },
  sub_drivers = {
    require("ge-switch"),
    require("ge-motion-switch"),
    require("inovelli-lzw36"),
    require("inovelli-lzw45"),
    require("inovelli-nzw97"),
    require("zooz-zen32"),
    require("zooz-zen51"),
    require("homeseer-motion-fls100"),
  },
  NAME = "zwave-switch",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local zwave_switch = ZwaveDriver("zwave-switch", driver_template)
zwave_switch:run()