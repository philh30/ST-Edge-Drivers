---@diagnostic disable: missing-parameter
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

local DoorLock = (require "st.zwave.CommandClass.DoorLock")({ version = 1 })
local UserCode = (require "st.zwave.CommandClass.UserCode")({ version = 1 })
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 2 })
local Association = (require "st.zwave.CommandClass.Association")({ version = 1 })
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })

local SCHLAGE_MANUFACTURER_ID = 0x003B
local SCHLAGE_PRODUCT_TYPE = 0x6341
local SCHLAGE_PRODUCT_ID = 0x5044

-- supported comand classes
local zwave_lock_endpoints = {
  {
    command_classes = {
      {value = zw.BATTERY},
      {value = zw.DOOR_LOCK},
      {value = zw.USER_CODE},
      {value = zw.NOTIFICATION}
    }
  }
}

local mock_device = test.mock_device.build_test_zwave_device(
  {
    profile = t_utils.get_profile_definition("base-lock.yml"),
    zwave_endpoints = zwave_lock_endpoints,
    zwave_manufacturer_id = SCHLAGE_MANUFACTURER_ID,
    zwave_product_type = SCHLAGE_PRODUCT_TYPE,
    zwave_product_id = SCHLAGE_PRODUCT_ID
  }
)

local function test_init()
  test.mock_device.add_test_device(mock_device)
end
test.set_test_init_function(test_init)

test.register_coroutine_test(
  "Setting a user code should result in the named code changed event firing",
  function()
    test.socket.capability:__queue_receive({ mock_device.id, { capability = capabilities.lockCodes.ID, command = "setCode", args = { 1, "1234", "test" } } })
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:Set({user_identifier = 1, user_code = "1234", user_id_status = UserCode.user_id_status.ENABLED_GRANT_ACCESS})
      )
    )
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:Report({user_identifier = 1, user_id_status = UserCode.user_id_status.ENABLED_GRANT_ACCESS}) })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.lockCodes(json.encode({["1"] = "test"}), { visibility = { displayed = false } })
    ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeChanged("1 set", { data = { codeName = "test"}, state_change = true }))
    )
  end
)

test.register_coroutine_test(
  "Comparison - getting a response pattern from a 469ZP",
  function()
    test.socket.capability:__queue_receive({ mock_device.id, { capability = capabilities.lockCodes.ID, command = "setCode", args = { 1, "1234", "Test Name" } } })
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:Set({user_identifier = 1, user_code = "1234", user_id_status = UserCode.user_id_status.ENABLED_GRANT_ACCESS})
      )
    )
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:Report({user_code="1234", user_id_status=UserCode.user_id_status.ENABLED_GRANT_ACCESS, user_identifier=1}) })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.lockCodes(json.encode({["1"] = "Test Name"}), { visibility = { displayed = false } })
    ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeChanged("1 set", { data = { codeName = "Test Name"}, state_change = true }))
    )
    test.wait_for_events()
    test.socket.capability:__queue_receive({ mock_device.id, { capability = capabilities.lockCodes.ID, command = "requestCode", args = { 1 } } })
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:Get({user_identifier = 1})
      )
    )
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:Report({user_code="1234", user_id_status=UserCode.user_id_status.ENABLED_GRANT_ACCESS, user_identifier=1}) })
    test.socket.capability:__set_channel_ordering("relaxed")
    --test.socket.capability:__expect_send(mock_device:generate_test_message("main",
    --        capabilities.lockCodes.lockCodes(json.encode({["1"] = "Test Name"}), { visibility = { displayed = false } })
    --))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeChanged("1 changed", { data = { codeName = "Test Name"}, state_change = true }))
    )
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "Looking into problem reported by bthrock",
  function()
    test.socket.capability:__queue_receive({ mock_device.id, { capability = capabilities.lockCodes.ID, command = "setCode", args = { 1, "1234", "Test Name" } } })
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:Set({user_identifier = 1, user_code = "1234", user_id_status = UserCode.user_id_status.ENABLED_GRANT_ACCESS})
      )
    )
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:Report({user_code="**********", user_id_status=UserCode.user_id_status.ENABLED_GRANT_ACCESS, user_identifier=1}) })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.lockCodes(json.encode({["1"] = "Test Name"}), { visibility = { displayed = false } })
    ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeChanged("1 set", { data = { codeName = "Test Name"}, state_change = true }))
    )
    test.wait_for_events()
    test.socket.capability:__queue_receive({ mock_device.id, { capability = capabilities.lockCodes.ID, command = "requestCode", args = { 1 } } })
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:Get({user_identifier = 1})
      )
    )
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:Report({user_code="**********", user_id_status=UserCode.user_id_status.ENABLED_GRANT_ACCESS, user_identifier=1}) })
    test.socket.capability:__set_channel_ordering("relaxed")
    --test.socket.capability:__expect_send(mock_device:generate_test_message("main",
    --        capabilities.lockCodes.lockCodes(json.encode({["1"] = "Test Name"}), { visibility = { displayed = false } })
    --))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeChanged("1 changed", { data = { codeName = "Test Name"}, state_change = true }))
    )
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "reloadAllCodes should query each code and then stop",
  function()
    test.socket.capability:__queue_receive({ mock_device.id, { capability = capabilities.lockCodes.ID, command = "setCode", args = { 1, "1234", "Test Name" } } })
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:Set({user_identifier = 1, user_code = "1234", user_id_status = UserCode.user_id_status.ENABLED_GRANT_ACCESS})
      )
    )
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:Report({user_code="**********", user_id_status=UserCode.user_id_status.ENABLED_GRANT_ACCESS, user_identifier=1}) })
    test.socket.capability:__set_channel_ordering("relaxed")
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.lockCodes(json.encode({["1"] = "Test Name"}), { visibility = { displayed = false } })
    ))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeChanged("1 set", { data = { codeName = "Test Name"}, state_change = true }))
    )
    test.wait_for_events()
    test.socket.capability:__queue_receive({ mock_device.id, { capability = capabilities.lockCodes.ID, command = "reloadAllCodes", args = {  } } })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
          capabilities.lockCodes.lockCodes(json.encode({["1"] = "Test Name"}), { visibility = { displayed = false } })
    ))
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:UsersNumberGet({})
      )
      --zw_test_utils.zwave_test_build_send_command(
      --  mock_device,
      --  UserCode:Get({user_identifier = 1})
      --)
    )
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
          capabilities.lockCodes.scanCodes({value="Scanning"}, { visibility = { displayed = false } })
    ))
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        UserCode:Get({user_identifier = 1})
      )
    )
    test.socket.zwave:__expect_send(
      zw_test_utils.zwave_test_build_send_command(
        mock_device,
        Configuration:Get({parameter_number = 16})
      )
    )
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:UsersNumberReport({supported_users = 1}) })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.maxCodes({ value = 1 }, { visibility = { displayed = false } })
    ))
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, Configuration:Report({parameter_number = 16, configuration_value = 4, size = 1}) })
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeLength({ value = 4 })
    ))
    test.wait_for_events()
    test.socket.zwave:__queue_receive({mock_device.id, UserCode:Report({user_code="**********", user_id_status=UserCode.user_id_status.ENABLED_GRANT_ACCESS, user_identifier=1}) })
    test.socket.capability:__set_channel_ordering("relaxed")
    --test.socket.capability:__expect_send(mock_device:generate_test_message("main",
    --        capabilities.lockCodes.lockCodes(json.encode({["1"] = "Test Name"}), { visibility = { displayed = false } })
    --))
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
            capabilities.lockCodes.codeChanged("1 changed", { data = { codeName = "Test Name"}, state_change = true }))
    )
    test.socket.capability:__expect_send(mock_device:generate_test_message("main",
          capabilities.lockCodes.scanCodes({value="Complete"}, { visibility = { displayed = false } })
    ))
    test.wait_for_events()
  end
)


test.run_registered_tests()