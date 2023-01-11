---@diagnostic disable: undefined-field, missing-parameter

local test = require "integration_test"
local capabilities = require "st.capabilities"
local zw = require "st.zwave"
local zw_test_utils = require "integration_test.zwave_test_utils"
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 5 })
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 2 })
local t_utils = require "integration_test.utils"

local sensor_endpoints = {
  {
    command_classes = {
      {value = zw.BATTERY},
      {value = zw.NOTIFICATION},
      {value = zw.SENSOR_BINARY}
    }
  }
}

local mock_sensor = test.mock_device.build_test_zwave_device({
  profile = t_utils.get_profile_definition("ecolink-flood-5.yml"),
  zwave_endpoints = sensor_endpoints,
  zwave_manufacturer_id = 0x014A,
  zwave_product_type = 0x0005,
  zwave_product_id = 0x0010,
})

local function test_init()
  test.mock_device.add_test_device(mock_sensor)
end

test.set_test_init_function(test_init)

test.register_message_test(
    "Water Notification report 0x02 should be handled as waterSensor wet",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
          notification_type = Notification.notification_type.WATER,
          event = Notification.event.water.LEAK_DETECTED,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.waterSensor.water.wet())
      }
    }
)

test.register_message_test(
    "Water Notification report 0x04 should be handled as waterSensor dry",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
          notification_type = Notification.notification_type.WATER,
          event = Notification.event.water.LEVEL_DROPPED,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.waterSensor.water.dry())
      }
    }
)

test.register_message_test(
    "Home Security Notification report 0x03 event should be handled as tamperAlert detected",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
          notification_type = Notification.notification_type.HOME_SECURITY,
          event = Notification.event.home_security.TAMPERING_PRODUCT_COVER_REMOVED,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.tamperAlert.tamper.detected())
      }
    }
)

test.register_message_test(
    "Home Security Notification report 0x00 event should be handled as tamperAlert clear",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
          notification_type = Notification.notification_type.HOME_SECURITY,
          event = Notification.event.home_security.STATE_IDLE,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.tamperAlert.tamper.clear())
      }
    }
)

test.register_message_test(
    "Power Management Notification report 0x0A event should be handled as 1% battery",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
          notification_type = Notification.notification_type.POWER_MANAGEMENT,
          event = Notification.event.power_management.REPLACE_BATTERY_SOON,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.battery.battery({value = 1}))
      }
    }
)

test.register_message_test(
    "Power Management Notification report 0x0B event should be handled as 0% battery",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
          notification_type = Notification.notification_type.POWER_MANAGEMENT,
          event = Notification.event.power_management.REPLACE_BATTERY_NOW,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.battery.battery({value = 0}))
      }
    }
)

test.register_message_test(
    "SensorBinary Water 0xFF should be handled as waterSensor wet",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(SensorBinary:Report({
          sensor_type = SensorBinary.sensor_type.WATER,
          sensor_value = SensorBinary.sensor_value.DETECTED_AN_EVENT,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.waterSensor.water.wet())
      }
    }
)

test.register_message_test(
    "SensorBinary Water 0x00 should be handled as waterSensor dry",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(SensorBinary:Report({
          sensor_type = SensorBinary.sensor_type.WATER,
          sensor_value = SensorBinary.sensor_value.IDLE,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.waterSensor.water.dry())
      }
    }
)

test.register_message_test(
    "SensorBinary Freeze 0xFF should be handled as temperatureAlarm freeze",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(SensorBinary:Report({
          sensor_type = SensorBinary.sensor_type.FREEZE,
          sensor_value = SensorBinary.sensor_value.DETECTED_AN_EVENT,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.temperatureAlarm.temperatureAlarm.freeze())
      }
    }
)

test.register_message_test(
    "SensorBinary Freeze 0x00 should be handled as temperatureAlarm cleared",
    {
      {
        channel = "zwave",
        direction = "receive",
        message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(SensorBinary:Report({
          sensor_type = SensorBinary.sensor_type.FREEZE,
          sensor_value = SensorBinary.sensor_value.IDLE,
        })) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_sensor:generate_test_message("main", capabilities.temperatureAlarm.temperatureAlarm.cleared())
      }
    }
)

test.run_registered_tests()