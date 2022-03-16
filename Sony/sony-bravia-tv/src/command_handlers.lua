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

local log = require("log")
local build_cmd = require("build_cmd")
local map = require("cap_map")
local client_functions = require("client_functions")
local api_cmd = require("api_cmd")
local cap_defs = require("cap_defs")
local split_string = require("split_string")
local get_app_list = require("app_list")
local emit_source_list = require("source_list")
local delay_send = require("delay_send")

local command_handlers = {}

--- Called whenever a command is sent. If a message is not received from the device within 3 seconds,
--- query the attribute. If another 3 seconds pass, assume the TCP connection has dropped and reconnect.
---
--- @param driver Driver
--- @param device st.Device
function command_handlers.wait_for_response(driver,device,component,capability,attribute)
  local function do_reconnect()
    log.warn(string.format('%s NO RESPONSE - DROPPING CONNECTION AND RECONNECTING',device.device_network_id))
    device.thread:cancel_timer(DEVICE_MAP[device.device_network_id].response)
    DEVICE_MAP[device.device_network_id].response = nil
    client_functions.refresh_connection(driver,device)
  end
  local function do_query()
    log.warn(string.format('%s NO RESPONSE - QUERYING %s:%s:%s',device.device_network_id,component,capability,attribute))
    local msg = build_cmd(device,component,capability,attribute,'query')
    if DEVICE_MAP[device.device_network_id].sock then
      DEVICE_MAP[device.device_network_id].sock:send(build_cmd(device,'main','switch','switch','query'))
      if msg then
        DEVICE_MAP[device.device_network_id].sock:send(msg)
      end
    end
    device.thread:cancel_timer(DEVICE_MAP[device.device_network_id].response)
    DEVICE_MAP[device.device_network_id].response = device.thread:call_with_delay(5, do_reconnect)
  end
  if not DEVICE_MAP[device.device_network_id].response then
    DEVICE_MAP[device.device_network_id].response = device.thread:call_with_delay(5, do_query)
  end
end

--- Check connection and send. Time of request is logged as an ACK is immediately sent by the unit that is identical to
--- a real state report, but is meaningless. These ACK messages are identified by how quickly they follow a command.
---
--- @param driver Driver
--- @param device st.Device
function command_handlers.send_cmd(driver,device,command,attribute,state)
  local msg = build_cmd(device,command.component,command.capability,attribute,state)
  client_functions.check_connection(driver,device)
  DEVICE_MAP[device.device_network_id][attribute] = os.time()
  if msg and DEVICE_MAP[device.device_network_id].sock then DEVICE_MAP[device.device_network_id].sock:send(msg) end
  command_handlers.wait_for_response(driver,device,command.component,command.capability,attribute)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.set_switch(driver,device,command)
  local state = command.command
  local attribute = 'switch'
  command_handlers.send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.set_mute(driver,device,command)
  local state = ((command.command == 'setMute') and command.args.state or (command.command .. 'd'))
  local attribute = 'mute'
  command_handlers.send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.set_pmute(driver,device,command)
  local state = ((command.command == 'setMute') and command.args.value or (command.command .. 'd'))
  local attribute = 'pictureMute'
  command_handlers.send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.set_volume(driver,device,command)
  local state = command.args.volume .. ''
  local attribute = 'volume'
  command_handlers.send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.volume_up(driver,device,command)
  local state = '30'
  local attribute = cap_defs.irccCommand.irccCommand.ID
  local cmd = { component = command.component, capability = cap_defs.irccCommand.ID }
  command_handlers.send_cmd(driver,device,cmd,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.volume_down(driver,device,command)
  local state = '31'
  local attribute = cap_defs.irccCommand.irccCommand.ID
  local cmd = { component = command.component, capability = cap_defs.irccCommand.ID }
  command_handlers.send_cmd(driver,device,cmd,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.set_input(driver,device,command)
  local state = command.args.inputSource
  local attribute = 'inputSource'
  command_handlers.send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.ircc_command(driver,device,command)
  local state = command.args.irccCommand
  local cmds = split_string(state,',')
  delay_send(device,cmds,(device.preferences.delayIRCC or 10)/1000)
  device:emit_event(cap_defs.irccCommand.irccCommand({value='Ready'}))
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.set_home(driver,device,command)
  local state = '6'
  local attribute = cap_defs.irccCommand.irccCommand.ID
  local cmd = { component = command.component, capability = cap_defs.irccCommand.ID }
  command_handlers.send_cmd(driver,device,cmd,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.channel_up(driver,device,command)
  local state = '33'
  local attribute = cap_defs.irccCommand.irccCommand.ID
  local cmd = { component = command.component, capability = cap_defs.irccCommand.ID }
  command_handlers.send_cmd(driver,device,cmd,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.channel_down(driver,device,command)
  local state = '34'
  local attribute = cap_defs.irccCommand.irccCommand.ID
  local cmd = { component = command.component, capability = cap_defs.irccCommand.ID }
  command_handlers.send_cmd(driver,device,cmd,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.set_channel(driver,device,command)
  local state = command.args.tvChannel
  local attribute = cap_defs.tvChannel.tvChannel.ID
  command_handlers.send_cmd(driver,device,command,attribute,state)
end

--- To allow preset to be sent either by ID or Name, search App List for matching name. If no match, assume ID was passed.
---
--- @param driver Driver
--- @param device st.Device
function command_handlers.launch_app(driver,device,command)
  local app_list = device:get_latest_state('main','mediaPresets','presets')
  local target = command.args.presetId
  local target_id = target
  for _, app in ipairs(app_list) do
    if app.name == target then
      target_id = app.id
      break
    end
  end
  api_cmd.launch_app(target_id,DEVICE_MAP[device.device_network_id].ip,device.preferences.passkey)
end

--- @param driver Driver
--- @param device st.Device
function command_handlers.refresh_handler(driver,device,command)
  client_functions.check_connection(driver,device)
  for _, comp in pairs(device.profile.components) do
    for _, cap in pairs(comp.capabilities) do
      if (map[comp.id] or {})[cap.id] then
        for attr, _ in pairs(map[comp.id][cap.id]) do
          local msg = build_cmd(device,comp.id,cap.id,attr,'query')
          if msg and DEVICE_MAP[device.device_network_id].sock then DEVICE_MAP[device.device_network_id].sock:send(msg) end
        end
      end
    end
  end
  if DEVICE_MAP[device.device_network_id].ip and device.preferences.refreshApps then
    get_app_list(driver,device)
  end
  emit_source_list(device)
  command_handlers.wait_for_response(driver,device,'main','switch','switch')
end

return command_handlers