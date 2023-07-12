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

local test = require "integration_test"
local capabilities = require "st.capabilities"
local zw = require "st.zwave"
local json = require "dkjson"
local zw_test_utils = require "integration_test.zwave_test_utils"
local t_utils = require "integration_test.utils"

local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 2 })
local Association = (require "st.zwave.CommandClass.Association")({ version = 1 })
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local Alarm = (require "st.zwave.CommandClass.Alarm")({version=1})
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({version=1})
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({version=5})
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2})

local MIMOLITE_MANUFACTURER_ID = 0x0084
local MIMOLITE_PRODUCT_TYPE = 0x0453
local MIMOLITE_PRODUCT_ID = 0x0111

-- supported comand classes
local mimolite_endpoints = {
  {
    command_classes = {
      {value = zw.SENSOR_BINARY},
      {value = zw.SENSOR_MULTILEVEL},
      {value = zw.SWITCH_BINARY},
      {value = zw.ALARM}
    }
  }
}

local mock_device = test.mock_device.build_test_zwave_device(
  {
    profile = t_utils.get_profile_definition("fortrezz-mimolite.yml"),
    zwave_endpoints = mimolite_endpoints,
    zwave_manufacturer_id = MIMOLITE_MANUFACTURER_ID,
    zwave_product_type = MIMOLITE_PRODUCT_TYPE,
    zwave_product_id = MIMOLITE_PRODUCT_ID
  }
)

local function test_init()
  test.mock_device.add_test_device(mock_device)
end
test.set_test_init_function(test_init)

test.register_coroutine_test(
  "Sensor binary report of 0 should close contact sensor",
  function()
    test.socket.zwave:__queue_receive({mock_device.id, SensorBinary:Report({sensor_value = 0}) })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.closed() ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.powerSource.powerSource.dc() ))
  end
)

test.register_coroutine_test(
  "Sensor binary report of 1 should open contact sensor",
  function()
    test.socket.zwave:__queue_receive({mock_device.id, SensorBinary:Report({sensor_value = 1}) })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.contactSensor.contact.open() ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.powerSource.powerSource.dc() ))
  end
)

test.register_coroutine_test(
  "Switch binary report of 0 should turn off switch",
  function()
    test.socket.zwave:__queue_receive({mock_device.id, SwitchBinary:Report({current_value = 0, target_value = 0}) })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.switch.switch.off() ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.powerSource.powerSource.dc() ))
  end
)

test.register_coroutine_test(
  "Sensor binary report of 255 should open contact sensor",
  function()
    test.socket.zwave:__queue_receive({mock_device.id, SwitchBinary:Report({current_value = 255, target_value = 0}) })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.switch.switch.on() ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main", capabilities.powerSource.powerSource.dc() ))
  end
)

test.run_registered_tests()