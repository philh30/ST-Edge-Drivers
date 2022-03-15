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

local log = require('log')
local json = require('dkjson')
local http = require('socket.http')
local ltn12 = require('ltn12')

local api = {}

------------------------
-- Send LAN HTTP Request
function api.send_lan_command(ip, method, path, body, passkey)
  local dest_url = 'http://' .. ip ..':80'..'/'..path
  local res_body = {}
  local req_body = json.encode(body)
  -- HTTP Request
  local _, code = http.request({
    method='POST',
    source=ltn12.source.string(req_body),
    url=dest_url,
    sink=ltn12.sink.table(res_body),
    headers={
      ['Content-Type'] = 'application/json',
      ['Content-Length'] = string.len(req_body),
      ['X-Auth-PSK'] = passkey,
    }
  })

  if code == 200 then
    return true, res_body
  end
  return false, nil
end

function api.get_interface_information(ip,passkey)
  local success, response = api.send_lan_command(ip,'POST','sony/system',{method="getInterfaceInformation",id=1,params={},version="1.0"},passkey or '')
  if success then
    return json.decode(response[1],1,nil)
  else
    log.warn(string.format('No response from %s to API command getInterfaceInformation',ip))
    return nil
  end
end

function api.get_model_name(ip,passkey)
  local dev_info = api.get_interface_information(ip,passkey)
  local model = ((dev_info.result or {})[1] or {}).modelName or 'TV'
  return model
end

function api.get_apps(ip,passkey)
  local success, response = api.send_lan_command(ip,'POST','sony/appControl',{method="getApplicationList",id=1,params={},version="1.0"},passkey or '')
  if success then
    return response
  else
    return nil
  end
end

function api.launch_app(app_uri,ip,passkey)
  local success = api.send_lan_command(ip,'POST','sony/appControl',{method="setActiveApp",id=1,params={{uri=app_uri}},version="1.0"},passkey or '')
  if success then
    log.trace(string.format('App %s Launched',app_uri))
  else
    log.error(string.format('App %s failed to launch',app_uri))
  end
  return success
end

return api