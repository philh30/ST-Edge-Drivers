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

local api_cmd = require("api_cmd")
local process_multiline = require("process_multiline")
local caps = require("st.capabilities")
local log = require("log")

local function check_duplicate_app(list,item)
  for _, app in ipairs(list) do
    if app.name == item then
      return true
    end
  end
  return false
end
  
local function check_blacklist(item)
  local list = {"Bonus Offer","BRAVIA notifications","Help","Play Store","Sony Select","Timers &amp; Clock","TV Control with Smart Speakers"}
  for _, app in ipairs(list) do
    if app == item then
      return true
    end
  end
  return false
end
  
--- @param driver Driver
--- @param device st.Device
local function get_app_list(driver,device)
  local response = api_cmd.get_apps(DEVICE_MAP[device.device_network_id].ip,device.preferences.passkey or '')
  if response then
    local tbl = process_multiline(response)
    local apps = {}
    for _, app in pairs(tbl) do
      if app.title and app.uri then
        if device.preferences.duplicateApps and check_duplicate_app(apps,app.title) then
          log.warn(string.format("Ignoring duplicate app: %s | %s",app.title,app.uri))
        else
          if device.preferences.blacklistApps and check_blacklist(app.title) then
            log.trace(string.format("Ignoring blacklisted app: %s | %s",app.title,app.uri))
          else
            table.insert(apps,{id=app.uri,name=app.title})
            log.trace(string.format("App discovered: %s | %s",app.title,app.uri))
          end
        end
      end
    end
    table.sort(apps,function (a,b) return (a.name == b.name) and (a.id < b.id) or (a.name < b.name) end)
    local event = caps.mediaPresets.presets({value=apps})
    event.visibility = {displayed=false}
    device:emit_event(event)
  else
      log.warn(string.format('%s did not respond to API request for list of installed apps.',device.device_network_id))
  end
end

return get_app_list