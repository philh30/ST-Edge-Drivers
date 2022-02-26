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

local Driver = require("st.driver")
local caps = require("st.capabilities")
local log = require("log")
local build_cmd = require("build_cmd")
local disco = require("disco")
local map = require("cap_map")
local client_functions = require("client_functions")

DEVICE_MAP = {}

--- Called whenever a command is sent. If a message is not received from the device within 3 seconds,
--- query the attribute. If another 3 seconds pass, assume the TCP connection has dropped and reconnect.
---
--- @param driver Driver
--- @param device st.Device
local function wait_for_response(driver,device,component,capability,attribute)
  local function do_reconnect()
    log.warn(string.format('%s CONNECTION DROPPED',device.device_network_id))
    device.thread:cancel_timer(DEVICE_MAP[device.device_network_id].response)
    DEVICE_MAP[device.device_network_id].response = nil
    client_functions.refresh_connection(driver,device)
  end
  local function do_query()
    log.warn(string.format('%s NO RESPONSE - QUERYING %s:%s:%s',device.device_network_id,component,capability,attribute))
    local msg = build_cmd(device,component,capability,attribute,'query')
    if msg and DEVICE_MAP[device.device_network_id].sock then DEVICE_MAP[device.device_network_id].sock:send(msg) end
    device.thread:cancel_timer(DEVICE_MAP[device.device_network_id].response)
    DEVICE_MAP[device.device_network_id].response = device.thread:call_with_delay(3, do_reconnect)
  end
  if not DEVICE_MAP[device.device_network_id].response then
    DEVICE_MAP[device.device_network_id].response = device.thread:call_with_delay(3, do_query)
  end
end

--- Check connection and send. Time of request is logged as an ACK is immediately sent by the unit that is identical to
--- a real state report, but is meaningless. These ACK messages are identified by how quickly they follow a command.
---
--- @param driver Driver
--- @param device st.Device
local function send_cmd(driver,device,command,attribute,state)
  local msg = build_cmd(device,command.component,command.capability,attribute,state)
  client_functions.check_connection(driver,device)
  DEVICE_MAP[device.device_network_id][attribute] = os.time()
  if msg and DEVICE_MAP[device.device_network_id].sock then DEVICE_MAP[device.device_network_id].sock:send(msg) end
  wait_for_response(driver,device,command.component,command.capability,attribute)
end

--- @param driver Driver
--- @param device st.Device
local function set_switch(driver,device,command)
  local state = command.command
  local attribute = 'switch'
  send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
local function set_mute(driver,device,command)
  local state = ((command.command == 'setMute') and command.args.state or command.command) .. 'd'
  local attribute = 'mute'
  send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
local function set_volume(driver,device,command)
  local state = command.args.volume .. ''
  local attribute = 'volume'
  send_cmd(driver,device,command,attribute,state)
end

--- @param driver Driver
--- @param device st.Device
local function refresh_handler(driver,device,command)
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
  wait_for_response(driver,device,'main','switch','switch')
end

--- @param driver Driver
--- @param device st.Device
local function init(driver,device,command)
  client_functions.check_connection(driver,device)
end

--- @param driver Driver
--- @param device st.Device
local function removed(driver,device)
  log.trace(string.format("%s REMOVED",device.device_network_id))
  if DEVICE_MAP[device.device_network_id] then
    DEVICE_MAP[device.device_network_id].sock:close()
    DEVICE_MAP[device.device_network_id] = nil
  end
end

local driver = Driver('sony-tv', {
    discovery = disco.start,
    capability_handlers = {
      [caps.refresh.ID] = {
        [caps.refresh.commands.refresh.NAME] = refresh_handler,
      },
      [caps.switch.ID] = {
        [caps.switch.commands.on.NAME] = set_switch,
        [caps.switch.commands.off.NAME] = set_switch,
      },
      [caps.audioMute.ID] = {
        [caps.audioMute.commands.mute.NAME] = set_mute,
        [caps.audioMute.commands.unmute.NAME] = set_mute,
      },
      [caps.audioVolume.ID] = {
        [caps.audioVolume.commands.setVolume.NAME] = set_volume,
      },
    },
    lifecycle_handlers = {
      init = init,
      removed = removed,
    }
  }
)

driver:run()