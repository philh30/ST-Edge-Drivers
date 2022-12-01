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
local splitAssocString = require "split_assoc_string"
local utilities = require "utilities"
local delay_send = require "delay_send"
local json = require "st.json"

local associationGroups = {}
local to_send_queue = {}
local to_send_display = {}

capabilities[capdefs.associationGroups.name] = capdefs.associationGroups.capability
capabilities[capdefs.associationGroup.name] = capdefs.associationGroup.capability
capabilities[capdefs.associationSet.name] = capdefs.associationSet.capability

local function table_header(row_items)
  local row = '<tr>'
  for _,item in pairs(row_items) do
    row = row .. '<th>' .. (item or '') .. '</th>'
  end
  row = row .. '</tr>'
  return row
end

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

local function update_group_table(device)
  local this_device = device.device_network_id
  local group_table = '<table style="font-size:65%;width:100%">'
  for group, data in pairs(associationGroups[this_device]) do
    group_table = group_table .. table_row({'Group ' .. group .. ': ' .. (data.name or 'Unknown')})
    local profile = (data.profile1 and data.profile2) and (AssociationGrpInfo._reflect_profile1[data.profile1]  .. ': ' .. AssociationGrpInfo._reflect_profile2[data.profile1][data.profile2]) or nil
    if profile then group_table = group_table .. table_row({'Profile: ' .. profile}) end
    group_table = group_table .. table_row({'Max Nodes: ' .. (data.max or 'Unknown')})
    group_table = group_table .. table_row({'Nodes: ' .. (data.nodes and ((data.nodes == '') and 'None' or data.nodes) or 'Unknown')})
    group_table = group_table .. table_row({''})
  end
  group_table = group_table .. '</table>'
  local evt = capabilities[capdefs.associationGroups.name].associationGroups({value = group_table})
  evt.visibility = {displayed = false}
  device:emit_event(evt)
end

local function update_device_info_table(device)
  local device_table = '<table style="font-size:65%;width:100%">'
  device_table = device_table .. table_row({'Device Network ID: [' .. device.device_network_id .. ']'})
  device_table = device_table .. table_row({'Fingerprint: ' .. string.format('%04X',(device.st_store or {}).zwave_manufacturer_id) .. '-' .. string.format('%04X',(device.st_store or {}).zwave_product_type) .. '-' .. string.format('%04X',(device.st_store or {}).zwave_product_id)})
  local fw_major = (((device.st_store or {}).zwave_version or {}).firmware or {}).major
  local fw_minor = (((device.st_store or {}).zwave_version or {}).firmware or {}).minor
  if fw_major and fw_minor then
    device_table = device_table .. table_row({'Firmware: ' .. fw_major .. '.' .. string.format('%02d',fw_minor)})
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
  local cc_list = {cc.ASSOCIATION,cc.MULTI_CHANNEL_ASSOCIATION,cc.ASSOCIATION_GRP_INFO,cc.ASSOCIATION_COMMAND_CONFIGURATION}
  local cc_table = '<table style="font-size:65%;width:100%">'
  for _, c in ipairs(cc_list) do
    if device:is_cc_supported(c) then
      cc_table = cc_table .. table_row({string.format('%02X',c),cc._classes[c]})
    end
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
  associationGroups[this_device] = nil
  to_send_queue[this_device] = nil
end

--- Association:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Association.Report
local function assoc_report(driver, device, command)
  log.trace('Association Report received')
  local group = tonumber(command.args.grouping_identifier)
  local requested_group = device:get_latest_state('setAssociationGroup',capdefs.associationGroup.name,'associationGroup')
  local max_nodes = command.args.max_nodes_supported .. ''
  local node_list = ''
  for n, node in ipairs(command.args.node_ids) do
    node_list = node_list .. ((#node_list > 0) and ',' or '') .. string.format('%02X',node)
  end
  local this_device = device.device_network_id
  associationGroups[this_device] = associationGroups[this_device] or {}
  associationGroups[this_device][group] = associationGroups[this_device][group] or {}
  associationGroups[this_device][group].max = max_nodes
  associationGroups[this_device][group].nodes = node_list
  if node_list == "" then node_list = 'None' end
  if group == requested_group then
    device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = node_list},{visibility = {displayed = false}}))
  end
  update_group_table(device)
end

--- MultiChannelAssociation:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.MultiChannelAssociation.Report
local function multi_assoc_report(driver, device, command)
  log.trace('Association Report received')
  local group = tonumber(command.args.grouping_identifier)
  local requested_group = device:get_latest_state('setAssociationGroup',capdefs.associationGroup.name,'associationGroup')
  local max_nodes = command.args.max_nodes_supported .. ''
  local node_list = ''
  for _, node in ipairs(command.args.node_ids) do
    node_list = node_list .. ((#node_list > 0) and ',' or '') .. string.format('%02X',node)
  end
  for _, node in ipairs(command.args.multi_channel_nodes) do
    node_list = node_list .. ((#node_list > 0) and ',' or '') .. string.format('%02X',node.multi_channel_node_id) .. ':' .. string.format('%02X',node.end_point)
  end
  local this_device = device.device_network_id
  associationGroups[this_device] = associationGroups[this_device] or {}
  associationGroups[this_device][group] = associationGroups[this_device][group] or {}
  associationGroups[this_device][group].max = max_nodes
  associationGroups[this_device][group].nodes = node_list
  if node_list == "" then node_list = 'None' end
  if group == requested_group then
    device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = node_list},{visibility = {displayed = false}}))
  end
  update_group_table(device)
end

--- AssociationGroupInfo:GroupNameReport handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.AssociationGrpInfo.AssociationGroupNameReport
local function assoc_name_report(driver, device, command)
  log.trace('Association Group Name Report received')
  local group = tonumber(command.args.grouping_identifier)
  local group_name = command.args.name
  local this_device = device.device_network_id
  associationGroups[this_device] = associationGroups[this_device] or {}
  associationGroups[this_device][group] = associationGroups[this_device][group] or {}
  associationGroups[this_device][group].name = group_name
  update_group_table(device)
end

--- AssociationGroupInfo:GroupInfoReport handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.AssociationGrpInfo.AssociationGroupInfoReport
local function assoc_info_report(driver, device, command)
  log.trace('Association Group Info Report received')
  local group = tonumber(command.args.groups[1].grouping_identifier)
  local this_device = device.device_network_id
  associationGroups[this_device] = associationGroups[this_device] or {}
  associationGroups[this_device][group] = associationGroups[this_device][group] or {}
  associationGroups[this_device][group].profile1 = command.args.groups[1].profile1
  associationGroups[this_device][group].profile2 = command.args.groups[1].profile2
  update_group_table(device)
end

--- Association:GroupingsReport handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Association.GroupingsReport
local function assoc_group_report(driver, device, command)
  log.trace('Association Groupings Report received')
  local groups = command.args.supported_groupings
  local supports_multi = device:is_cc_supported(cc.MULTI_CHANNEL_ASSOCIATION)
  local cmds = {}
  local desc = {}
  local this_device = device.device_network_id
  associationGroups[this_device] = associationGroups[this_device] or {}
  if groups > 0 then
    for i=1,groups,1 do
      associationGroups[this_device][i] = associationGroups[this_device][i] or {}
      if supports_multi then
        table.insert(cmds,MultiChannelAssociation:Get({grouping_identifier = i}))
        table.insert(desc,'Multi-Channel Assoc Get - Group ' .. i)
      else
        table.insert(cmds,Association:Get({grouping_identifier = i}))
        table.insert(desc,'Assoc Get - Group ' .. i)
      end
      table.insert(cmds,AssociationGrpInfo:AssociationGroupNameGet({grouping_identifier = i}))
      table.insert(cmds,AssociationGrpInfo:AssociationGroupInfoGet({grouping_identifier = i}))
      table.insert(desc,'Assoc Group Name Get - Group ' .. i)
      table.insert(desc,'Assoc Group Info Get - Group ' .. i)
    end
  else
    update_group_table(device)
  end
  send_queue(device,cmds,1,desc)
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
local function get_association_group(driver, device, command)
  local group = tonumber(command.args.associationGroup)
  local supports_multi = device:is_cc_supported(cc.MULTI_CHANNEL_ASSOCIATION)
  local cmds = {}
  local desc = {}
  log.debug(string.format('Fetching data for Association Group %s',group))
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationGroup.name].associationGroup({value = group},{visibility = {displayed = false}}))
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = 'Fetching nodes...'},{visibility = {displayed = false}}))
  if supports_multi then
    table.insert(cmds,MultiChannelAssociation:Get({grouping_identifier = group}))
    table.insert(desc,'Multi-Channel Assoc Get - Group ' .. group)
  else
    table.insert(cmds,Association:Get({grouping_identifier = group}))
    table.insert(desc,'Assoc Get - Group ' .. group)
  end
  table.insert(cmds,AssociationGrpInfo:AssociationGroupNameGet({grouping_identifier = group}))
  table.insert(cmds,AssociationGrpInfo:AssociationGroupInfoGet({grouping_identifier = group}))
  table.insert(desc,'Assoc Group Name Get - Group ' .. group)
  table.insert(desc,'Assoc Group Info Get - Group ' .. group)
  send_queue(device,cmds,1,desc)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function refresh_handler(driver,device,command)
  local supports_multi = device:is_cc_supported(cc.MULTI_CHANNEL_ASSOCIATION)
  update_device_info_table(device)
  local group = 1
  if not device:get_latest_state('setAssociationGroup',capdefs.associationGroup.name,'associationGroup') then
    device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationGroup.name].associationGroup({value = 1},{visibility = {displayed = false}}))
  else
    group = device:get_latest_state('setAssociationGroup',capdefs.associationGroup.name,'associationGroup')
  end
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = 'Fetching nodes...'},{visibility = {displayed = false}}))
  local cmds = {Association:GroupingsGet({})}
  local desc = {'Assoc Groupings Get'}
  if supports_multi then
    table.insert(cmds,MultiChannelAssociation:Get({grouping_identifier = group}))
    table.insert(desc,'Multi-Channel Assoc Get - Group ' .. group)
  else
    table.insert(cmds,Association:Get({grouping_identifier = group}))
    table.insert(desc,'Assoc Get - Group ' .. group)
  end
  table.insert(cmds,AssociationGrpInfo:AssociationGroupNameGet({grouping_identifier = group}))
  table.insert(cmds,AssociationGrpInfo:AssociationGroupInfoGet({grouping_identifier = group}))
  table.insert(desc,'Assoc Group Name Get - Group ' .. group)
  table.insert(desc,'Assoc Group Info Get - Group ' .. group)
  send_queue(device,cmds,1,desc)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function association_set_handler(driver,device,command)
  local cmds = {}
  local desc = {}
  local nodes = command.args.associationSet
  local supports_multi = device:is_cc_supported(cc.MULTI_CHANNEL_ASSOCIATION)
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = nodes},{visibility = {displayed = false}}))
  local node_list,multi_nodes = splitAssocString(nodes,',',5,false,supports_multi)
  local group = device:get_latest_state('setAssociationGroup',capdefs.associationGroup.name,'associationGroup')
  if supports_multi then
    cmds = {MultiChannelAssociation:Remove({grouping_identifier = group, node_ids = {}, multi_channel_nodes = {}})}
    desc = {'Multi-Channel Assoc Remove - Group ' .. group}
  else
    cmds = {Association:Remove({grouping_identifier = group, node_ids = {}})}
    desc = {'Assoc Remove - Group ' .. group}
  end
  if (#node_list + #multi_nodes) > 0 then
    local nodes_desc = ''
    for _,n in ipairs(node_list) do
      nodes_desc = nodes_desc .. ((#nodes_desc > 0) and ',' or '') .. string.format('%02X',n)
    end
    for _,n in ipairs(multi_nodes) do
      nodes_desc = nodes_desc .. ((#nodes_desc > 0) and ',' or '') .. string.format('%02X',n.multi_channel_node_id) .. ':' .. string.format('%02X',n.end_point)
    end
    if #multi_nodes > 0 then
      table.insert(cmds,MultiChannelAssociation:Set({grouping_identifier = group, node_ids = node_list, multi_channel_nodes = multi_nodes}))
      table.insert(desc,'Multi-Channel Assoc Set - Group ' .. group .. ' Nodes: ' .. nodes_desc)
    else
      table.insert(cmds,Association:Set({grouping_identifier = group, node_ids = node_list}))
      table.insert(desc,'Assoc Set - Group ' .. group .. ' Nodes: ' .. nodes_desc)
    end
  end
  if supports_multi then
    table.insert(cmds,MultiChannelAssociation:Get({grouping_identifier = group}))
    table.insert(desc,'Multi-Channel Assoc Get - Group ' .. group)
  else
    table.insert(cmds,Association:Get({grouping_identifier = group}))
    table.insert(desc,'Assoc Get - Group ' .. group)
  end
  send_queue(device,cmds,2,desc)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function reset(driver,device,command)
  local this_device = device.device_network_id
  to_send_queue[this_device] = nil
  to_send_display[this_device] = nil
  update_queue_table(device)
end

local driver_template = {
  zwave_handlers = {
    [cc.ASSOCIATION] = {
      [Association.REPORT] = assoc_report,
      [Association.GROUPINGS_REPORT] = assoc_group_report,
    },
    [cc.ASSOCIATION_GRP_INFO] = {
      [AssociationGrpInfo.ASSOCIATION_GROUP_NAME_REPORT] = assoc_name_report,
      [AssociationGrpInfo.ASSOCIATION_GROUP_INFO_REPORT] = assoc_info_report,
    },
    [cc.MULTI_CHANNEL_ASSOCIATION] = {
      [MultiChannelAssociation.REPORT] = multi_assoc_report,
    },
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
    [capdefs.associationGroup.capability.ID] = {
      [capdefs.associationGroup.capability.commands.getAssociationGroup.NAME] = get_association_group,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
    [capdefs.associationSet.capability.ID] = {
      [capdefs.associationSet.capability.commands.setNodes.NAME] = association_set_handler,
    },
    [capdefs.reset.ID] = {
      [capdefs.reset.commands.reset.NAME] = reset,
    },
  },
  NAME = "zwub-associator",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local associator = ZwaveDriver("zwub-associator", driver_template)
associator:run()