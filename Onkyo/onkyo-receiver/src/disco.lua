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

local socket = require('socket')
local log = require('log')
local config = require('config')

local disco = {}

function disco.parse_response(resp)
  local t = {}
  local r = {}
  for str in string.gmatch(resp, "([^/]+)") do
    table.insert(t, str)
  end
  r.model= t[1]:match("!1ECN(.+)")
  r.port = t[2]
  r.id = r.model .. '|' .. t[4]:match("(%w+)")
  return r
end

function disco.find_device()
  local devices = {}
  local res, ip, port
  local udp = socket.udp()
  udp:setsockname('*', 0)
  udp:setoption('broadcast', true)
  udp:settimeout(config.MC_TIMEOUT)

  log.info('===== SCANNING NETWORK FOR ONKYO...')
  udp:sendto(config.MSEARCH_ONKYO, config.MC_ADDRESS, config.MC_PORT)
  
  while true do
    res, ip, port = udp:receivefrom()
    if res ~= nil and string.gmatch(res,"ISCP.+!1ECN.+/.+/.+/.+") then
      local dev = disco.parse_response(res)
      dev.ip = ip
      log.info(string.format('===== RESPONSE FROM %s:%s | RX < %s',ip,port,res))
      log.info(string.format('===== LOCATION: %s:%s  |  MODEL: %s  |  ID: %s',dev.ip,dev.port,dev.model,dev.id))
      table.insert(devices,dev)
    elseif ip == 'timeout' then
      log.info('===== ONKYO SCAN COMPLETE!')
      break
    else
      log.error(string.format('Unrecognized response from IP: %s Port: %s | RX < %s',ip,port,res))
    end
  end

  log.info('===== SCANNING NETWORK FOR PIONEER...')
  udp:sendto(config.MSEARCH_PIONEER, config.MC_ADDRESS, config.MC_PORT)
  while true do
    res, ip, port = udp:receivefrom()
    if res ~= nil and string.gmatch(res,"ISCP.+!1ECN.+/.+/.+/.+") then
      local dev = disco.parse_response(res)
      dev.ip = ip
      log.info(string.format('===== RESPONSE FROM %s:%s | RX < %s',ip,port,res))
      log.info(string.format('===== LOCATION: %s:%s  |  MODEL: %s  |  ID: %s',dev.ip,dev.port,dev.model,dev.id))
      table.insert(devices,dev)
    elseif ip == 'timeout' then
      log.info('===== PIONEER SCAN COMPLETE!')
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
  
  local metadata = {
    type = config.DEVICE_TYPE,
    device_network_id = device.id,
    label = 'Onkyo ' .. device.model,
    profile = config.DEVICE_PROFILE,
    manufacturer = 'Onkyo',
    model = device.model,
    vendor_provided_label = device.model
  }
  return driver:try_create_device(metadata)
end

function disco.start(driver, opts, cons)
  local devices = disco.find_device()
  for _, device in ipairs(devices) do
    create_device(driver,device)
    if not DEVICE_MAP[device.id] then DEVICE_MAP[device.id] = {} end
    DEVICE_MAP[device.id].ip = device.ip
    DEVICE_MAP[device.id].model = device.model
  end
end

return disco
