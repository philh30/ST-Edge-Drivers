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
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({version=4})

local FAN_MANUFACTURER_ID = 0x0063
local FAN_PRODUCT_TYPE = 0x4944
local FAN_PRODUCT_ID = 0x3034 --0x3131

-- supported comand classes
local fan_endpoints = {
  {
    command_classes = {
      {value = zw.SWITCH_MULTILEVEL}
    }
  }
}

local mock_device = test.mock_device.build_test_zwave_device(
  {
    profile = t_utils.get_profile_definition("ge-fan-assoc.yml"),
    zwave_endpoints = fan_endpoints,
    zwave_manufacturer_id = FAN_MANUFACTURER_ID,
    zwave_product_type = FAN_PRODUCT_TYPE,
    zwave_product_id = FAN_PRODUCT_ID
  }
)

local function test_init()
  test.mock_device.add_test_device(mock_device)
end
test.set_test_init_function(test_init)

test.register_coroutine_test(
  "Setting fan speed should send the speed and then a follow up query",
  function()
    test.socket.capability:__queue_receive({
      mock_device.id,
      { capability = capabilities.fanSpeed.ID, command = "setFanSpeed", args = {2}, component = "main"}
    })
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        SwitchMultilevel:Set({
          duration = "default",
          value = 66
        })
      )
    )
    test.wait_for_events()
  end
)

test.run_registered_tests()