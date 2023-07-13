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

local socket = require("cosock.socket")
local log = require('log')
local config = require('config')
local upnpcommon = require('upnpcommon')
local api_cmd = require('api_cmd')

local disco = {}

function disco.find_device()
  local devices = {}
  local res, ip, port
  local udp = socket.udp()
  udp:setsockname('*', 0)
  udp:setoption('broadcast', true)
  udp:settimeout(config.MC_TIMEOUT)

  log.info('===== SCANNING NETWORK...')
  udp:sendto(config.MSEARCH, config.MC_ADDRESS, config.MC_PORT)

  while true do
    res, ip, port = udp:receivefrom()
    if res ~= nil then
      local headers = upnpcommon.process_response(res,{'200 OK'})
      local id = ((headers or {}).usn or ''):match("uuid:([^,::]+)")
      if headers and id and headers.st == config.ST then
        local dev = {
          ip = ip,
          id = 'sony|' .. id,
          port = port,
        }
        log.info(string.format('===== RESPONSE FROM %s:%s | UUID %s',ip,port,dev.id))
        table.insert(devices,dev)
      end
    elseif ip == 'timeout' then
      log.info('===== SCAN COMPLETE!')
      break
    else
      log.error(string.format('Unrecognized response from IP: %s Port: %s | RX < %s',ip,port,res))
    end
  end
  udp:close()

  return devices
end

local function create_device(driver, device)
  log.info(string.format('===== CREATING DEVICE: %s',device.id))
  
  local model = api_cmd.get_model_name(device.ip,'')

  local metadata = {
    type = config.DEVICE_TYPE,
    device_network_id = device.id,
    label = 'Sony Bravia ' .. (model or 'TV'),
    profile = config.DEVICE_PROFILE,
    manufacturer = 'Sony',
    model = 'Sony Bravia ' .. (model or 'TV'),
    vendor_provided_label = 'Sony Bravia TV'
  }
  return driver:try_create_device(metadata)
end

function disco.start(driver, opts, cons)
  local devices = disco.find_device()

  for _, device in ipairs(devices) do
    create_device(driver,device)
    if not DEVICE_MAP[device.id] then DEVICE_MAP[device.id] = {} end
    DEVICE_MAP[device.id].ip = device.ip
  end

end

return disco