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

local capabilities = require "st.capabilities"
local capdefs = require "capabilitydefs"
local cc = require "st.zwave.CommandClass"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local log = require "log"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=3 })
--- @type st.zwave.CommandClass.MultiChannelAssociation
local MultiChannelAssociation = (require "st.zwave.CommandClass.MultiChannelAssociation")({ version=4 })
--- @type st.zwave.CommandClass.AssociationGrpInfo
local AssociationGrpInfo = (require "st.zwave.CommandClass.AssociationGrpInfo")({ version=3 })
--- @type st.zwave.CommandClass.WakeUp
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version=1 })
--- @type st.zwave.CommandClass.Version
local Version = (require "st.zwave.CommandClass.Version")({ version=3 })
local splitAssocString = require "split_assoc_string"
local utilities = require "utilities"
local delay_send = require "delay_send"
local json = require "st.json"

local to_send_queue = {}
local to_send_display = {}

local function table_row(row_items)
  local row = '<tr>'
  for _,item in pairs(row_items) do
    row = row .. '<td>' .. (item or '') .. '</td>'
  end
  row = row .. '</tr>'
  return row
end

local function update_queue_table(device)
  local this_device = device.device_network_id
  local queued_cmds = '<table style="font-size:65%;width:100%">'
  if to_send_display[this_device] and #to_send_display[this_device] > 0 then
    for _, d in ipairs(to_send_display[this_device]) do
      queued_cmds = queued_cmds .. table_row({d})
    end
  else
    queued_cmds = queued_cmds .. table_row({'No commands in queue'})
  end
  queued_cmds = queued_cmds .. '</table>'
  device:emit_component_event(device.profile.components['queue'],capdefs.messageQueue.queue({value = queued_cmds},{visibility = {displayed = false}}))
end

local function send_queue(device,commands,delay,description)
  local this_device = device.device_network_id
  for _, s in ipairs(description) do
    log.trace(string.format('Queued z-wave command: %s',s))
  end
  if device:is_cc_supported(cc.WAKE_UP) then
    to_send_queue[this_device] = to_send_queue[this_device] or {}
    for _,cmd in ipairs(commands) do
      table.insert(to_send_queue[this_device],cmd)
    end
    to_send_display[this_device] = to_send_display[this_device] or {}
    for _,d in ipairs(description) do
      table.insert(to_send_display[this_device],d)
    end
    update_queue_table(device)
  else
    delay_send(device,commands,delay)
  end
end

local function update_device_info_table(device)
  local device_table = '<table style="font-size:65%;width:100%">'
  device_table = device_table .. table_row({'Device Network ID: [' .. device.device_network_id .. ']'})
  device_table = device_table .. table_row({'Fingerprint: ' .. string.format('%04X',(device.st_store or {}).zwave_manufacturer_id) .. '-' .. string.format('%04X',(device.st_store or {}).zwave_product_type) .. '-' .. string.format('%04X',(device.st_store or {}).zwave_product_id)})
  local fw_major = (((device.st_store or {}).zwave_version or {}).firmware or {}).major
  local fw_minor = (((device.st_store or {}).zwave_version or {}).firmware or {}).minor
  if fw_major and fw_minor then
    device_table = device_table .. table_row({'Firmware: ' .. fw_major .. '.' .. fw_minor})
  end
  local security
  if (device.st_store or {}).zwave_security_flags then
    for _,flag in pairs((device.st_store or {}).zwave_security_flags) do
      security = (security and (security .. ', ') or '') .. flag
    end
  end
  device_table = device_table .. table_row({'Security Level: ' .. security})
  local mesh = json.decode((device.st_store.data or {}).meshInfo)
  local route = '[' .. device.device_network_id .. '] <-> ['
  for _, node in ipairs(mesh.route) do
    route = route .. node.deviceId .. '] <-> ['
  end
  local hubnode = device.driver.environment_info.hub_zwave_id or 1
  route = route .. string.format('%02X',hubnode) .. ']'
  device_table = device_table .. table_row({'Route: ' .. route})
  local metrics = string.format('Transmitted: %s  Received: %s  Failed: %s', mesh.metrics.totalTransmittedMessages, mesh.metrics.totalReceivedMessages, mesh.metrics.transmitFailures)
  device_table = device_table .. table_row({metrics})
  local evt = capdefs.deviceInfo.deviceInformation({value = device_table})
  evt.visibility = {displayed = false}
  device:emit_event(evt)
  local cc_list = {}
  local cc_table = '<table style="font-size:50%;width:100%">'
  for _, ep in ipairs(device.zwave_endpoints) do
    for _, c in ipairs(ep.command_classes) do
      if c.supported then
        cc_list[c.value] = cc_list[c.value] or {name = cc._classes[c.value],ep = 'Endpoints:',secure=c.secure}
        cc_list[c.value].ep = cc_list[c.value].ep .. ' ' .. ep.id
      end
    end
  end
  local cc_list_sort = {}
  for c, data in pairs(cc_list) do
    table.insert(cc_list_sort,{num = c, name = data.name, ep = data.ep, secure = data.secure})
  end
  table.sort(cc_list_sort,function (k1, k2) return k1.name < k2.name end)
  for _, c in pairs(cc_list_sort) do
    cc_table = cc_table .. table_row({string.format('%02X',c.num),c.name,c.secure and 'Secure' or 'Not Secure',c.ep})
  end
  cc_table = cc_table .. '</table>'
  evt = capdefs.commandClasses.commandClasses({value = cc_table})
  evt.visibility = {displayed = false}
  device:emit_event(evt)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function init(driver, device)
  if device:is_cc_supported(cc.WAKE_UP) then
    update_queue_table(device)
  end
  update_device_info_table(device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  --device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added(driver, device)
  device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function removed(driver, device)
  local this_device = device.device_network_id
  to_send_queue[this_device] = nil
end

--- WakeUp:Notification handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(driver, device, command)
  log.trace('WakeUp Notification received')
  local this_device = device.device_network_id
  for _, cmd in ipairs(to_send_queue[this_device] or {}) do
    device:send(cmd)
  end
  to_send_queue[this_device] = nil
  to_send_display[this_device] = nil
  update_queue_table(device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver,device,command)
  update_device_info_table(device)local cmds = {}
  local desc = {}
  table.insert(cmds,Version:Get({}))
  send_queue(device,cmds,1,desc)
end

local driver_template = {
  zwave_handlers = {
    [cc.WAKE_UP] = {
        [WakeUp.NOTIFICATION] = wakeup_notification,
    },
  },
  supported_capabilities = {
    capabilities.refresh,
  },
  lifecycle_handlers = {
    doConfigure = do_configure,
    added = added,
    removed = removed,
    init = init,
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
  },
  NAME = "zwub-utility-belt",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local explorer = ZwaveDriver("zwub-explorer", driver_template)
explorer:run()