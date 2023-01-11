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
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({ version=3 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 2 })

local devices = {
  ECOLINK_FLOOD_SENSOR_5 = {
    MATCHING_MATRIX = {
      mfrs = 0x014A,
      product_types = 0x0005,
      product_ids = {0x0010,0x000F}
    },
    NOTIFICATION = {
      -- Set the notification parameters for the device
      { notification_type = Notification.notification_type.WATER, notification_status = Notification.notification_status.ON },             -- Enable notifications for water sensor
      { notification_type = Notification.notification_type.HOME_SECURITY, notification_status = Notification.notification_status.ON  },    -- Enable notifications for tamper switch
      { notification_type = Notification.notification_type.POWER_MANAGEMENT, notification_status = Notification.notification_status.ON },  -- Enable notifications for battery alerts
    }
  },
  ECOLINK_TILT_CONTACT_SENSOR_2_5 = {
    MATCHING_MATRIX = {
      mfrs = 0x014A,
      product_types = 0x0004,
      product_ids = {0x0002,0x0003}
    },
    NOTIFICATION = {
      -- Set the notification parameters for the device
      { notification_type = Notification.notification_type.ACCESS_CONTROL, notification_status = Notification.notification_status.ON },    -- Enable notifications for tilt sensor
      { notification_type = Notification.notification_type.HOME_SECURITY, notification_status = Notification.notification_status.ON  },    -- Enable notifications for tamper switch
      { notification_type = Notification.notification_type.POWER_MANAGEMENT, notification_status = Notification.notification_status.ON },  -- Enable notifications for below 2.6V battery alerts
    }
  },
  FORTEZZ_LEAK = {
    MATCHING_MATRIX = {
      mfrs = 0x0084,
      product_types = {0x0053},
      product_ids = 0x0216
    },
    ASSOCIATION = {
      {grouping_identifier = 1}
    }
  },
  RING_CONTACT_2 = {
    MATCHING_MATRIX = {
      mfrs = 0x0346,
      product_types = 0x0201,
      product_ids = 0x0301,
    },
    BUTTONS = {
      main = {
        number_of_buttons = 1,
        supported_button_values = {"pushed"}
      },
    }
  }
}
local configurations = {}

configurations.initial_configuration = function(driver, device)
  local configuration = configurations.get_device_configuration(device)
  if configuration ~= nil then
    for _, value in ipairs(configuration) do
      device:send(Configuration:Set(value))
    end
  end
  local association = configurations.get_device_association(device)
  if association ~= nil then
    for _, value in ipairs(association) do
      local _node_ids = value.node_ids or {driver.environment_info.hub_zwave_id}
      device:send(Association:Set({grouping_identifier = value.grouping_identifier, node_ids = _node_ids}))
    end
  end
  local notification = configurations.get_device_notification(device)
  if notification ~= nil then
    for _, value in ipairs(notification) do
      device:send(Notification:Set(value))
    end
  end
  local wake_up = configurations.get_device_wake_up(device)
  if wake_up ~= nil then
    for _, value in ipairs(wake_up) do
      local _node_id = value.node_id or driver.environment_info.hub_zwave_id
      device:send(WakeUp:IntervalSet({seconds = value.seconds, node_id = _node_id}))
    end
  end
end

configurations.initial_buttons = function(driver,device)
  local buttons = configurations.get_device_buttons(device)
  if buttons ~= nil then
    for comp, button in pairs(buttons) do
      if device:supports_capability_by_id(capabilities.button.ID, comp) then
        device:emit_component_event(device.profile.components[comp], capabilities.button.numberOfButtons({ value= button.number_of_buttons or 1 }))
        device:emit_component_event(device.profile.components[comp], capabilities.button.supportedButtonValues(button.supported_button_values))
      end
    end
  end
end

configurations.get_device_configuration = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.CONFIGURATION
    end
  end
  return nil
end

configurations.get_device_association = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.ASSOCIATION
    end
  end
  return nil
end

configurations.get_device_notification = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.NOTIFICATION
    end
  end
  return nil
end

configurations.get_device_wake_up = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.WAKE_UP
    end
  end
  return nil
end

configurations.get_device_buttons = function(zw_device)
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

return configurations
