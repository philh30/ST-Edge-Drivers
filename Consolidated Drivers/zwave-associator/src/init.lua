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
local splitAssocString = require "split_assoc_string"
local utilities = require "utilities"
local delay_send = require "delay_send"
local json = require "st.json"

local associationGroups = {}

capabilities[capdefs.associationGroups.name] = capdefs.associationGroups.capability
capabilities[capdefs.associationGroup.name] = capdefs.associationGroup.capability
capabilities[capdefs.associationSet.name] = capdefs.associationSet.capability

local function send_queue(device,commands,delay,description)
  for _, s in ipairs(description) do
    log.trace(string.format('Queued z-wave command: %s',s))
  end
  if device:is_cc_supported(cc.WAKE_UP) then
    ------------------------ Need to handle sleepy devices
  else
    delay_send(device,commands,delay)
  end
end

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

local function update_group_table(device)
  local group_table = '<table style="font-size:65%;width:100%">'
  for group, data in pairs(associationGroups) do
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
  device_table = device_table .. table_row({'Device Network ID: ' .. device.device_network_id})
  local security
  if (device.st_store or {}).zwave_security_flags then
    for _,flag in pairs(device.st_store.zwave_security_flags) do
      security = (security and (security .. ', ') or '') .. flag
    end
  end
  device_table = device_table .. table_row({'Security Level: ' .. security})
  local mesh = json.decode((device.st_store.data or {}).meshInfo)
  local route = '[' .. device.device_network_id .. '] <-> ['
  for _, node in ipairs(mesh.route) do
    route = route .. node.deviceId .. '] <-> ['
  end
  local hubnode = device.driver.environment_info.hub_zwave_id
  route = route .. string.format('%02X',hubnode) .. ']'
  device_table = device_table .. table_row({'Route: ' .. route})
  device_table = device_table .. table_row({'Association: ' .. (device:is_cc_supported(cc.ASSOCIATION) and 'Yes' or 'No')})
  device_table = device_table .. table_row({'Association Group Info: ' .. (device:is_cc_supported(cc.ASSOCIATION_GRP_INFO) and 'Yes' or 'No')})
  device_table = device_table .. table_row({'Association Command Configuration: ' .. (device:is_cc_supported(cc.ASSOCIATION_COMMAND_CONFIGURATION) and 'Yes' or 'No')})
  device_table = device_table .. table_row({'Multi Channel Association: ' .. (device:is_cc_supported(cc.MULTI_CHANNEL_ASSOCIATION) and 'Yes' or 'No')})
  device_table = device_table .. table_row({'Multi Instance Association: ' .. (device:is_cc_supported(cc.MULTI_INSTANCE_ASSOCIATION) and 'Yes' or 'No')})
  device_table = device_table .. '</table>'
  local evt = capdefs.deviceInfo.deviceInformation({value = device_table})
  evt.visibility = {displayed = false}
  device:emit_event(evt)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function do_configure(driver, device)
  device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function added(driver, device)
  device:refresh()
  local cmds = {Association:GroupingsGet({})}
  local desc = {'Assoc Groupings Get'}
  send_queue(device,cmds,1,desc)
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationGroup.name].associationGroup({value = 1}))
end

--- Association:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Association.Report
local function assoc_report(driver, device, command)
  log.trace('Association Report received')
  utilities.disptable(command.args,'  ')
  local group = tonumber(command.args.grouping_identifier)
  local requested_group = device:get_latest_state('setAssociationGroup',capdefs.associationGroup.name,'associationGroup')
  local max_nodes = command.args.max_nodes_supported .. ''
  local node_list = ''
  for n, node in ipairs(command.args.node_ids) do
    node_list = node_list .. ((#node_list > 0) and ',' or '') .. string.format('%02X',node)
  end
  associationGroups[group] = associationGroups[group] or {}
  associationGroups[group].max = max_nodes
  associationGroups[group].nodes = node_list
  if node_list == "" then node_list = 'None' end
  if group == requested_group then
    device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = node_list}))
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
  utilities.disptable(command.args,'  ')
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
  associationGroups[group] = associationGroups[group] or {}
  associationGroups[group].max = max_nodes
  associationGroups[group].nodes = node_list
  if node_list == "" then node_list = 'None' end
  if group == requested_group then
    device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = node_list}))
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
  utilities.disptable(command.args,'  ')
  local group = tonumber(command.args.grouping_identifier)
  local group_name = command.args.name
  associationGroups[group] = associationGroups[group] or {}
  associationGroups[group].name = group_name
  update_group_table(device)
end

--- AssociationGroupInfo:GroupInfoReport handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.AssociationGrpInfo.AssociationGroupInfoReport
local function assoc_info_report(driver, device, command)
  log.trace('Association Group Info Report received')
  utilities.disptable(command.args,'  ')
  local group = tonumber(command.args.groups[1].grouping_identifier)
  associationGroups[group] = associationGroups[group] or {}
  associationGroups[group].profile1 = command.args.groups[1].profile1
  associationGroups[group].profile2 = command.args.groups[1].profile2
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
  if groups > 0 then
    for i=1,groups,1 do
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

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function get_association_group(driver, device, command)
  local group = tonumber(command.args.associationGroup)
  local supports_multi = device:is_cc_supported(cc.MULTI_CHANNEL_ASSOCIATION)
  local cmds = {}
  local desc = {}
  log.debug(string.format('Fetching data for Association Group %s',group))
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationGroup.name].associationGroup({value = group}))
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = 'Fetching nodes...'}))
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
    device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationGroup.name].associationGroup({value = 1}))
  else
    group = device:get_latest_state('setAssociationGroup',capdefs.associationGroup.name,'associationGroup')
  end
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = 'Fetching nodes...'}))
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
  device:emit_component_event(device.profile.components['setAssociationGroup'],capabilities[capdefs.associationSet.name].associationSet({value = nodes}))
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
  },
  supported_capabilities = {
    capabilities.refresh,
  },
  lifecycle_handlers = {
    doConfigure = do_configure,
    added = added,
  },
  capability_handlers = {
    [capdefs.associationGroup.capability.ID] = {
      [capdefs.associationGroup.capability.commands.getAssociationGroup.NAME] = get_association_group,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
    [capdefs.associationSet.capability.ID] = {
      [capdefs.associationSet.capability.commands.setNodes.NAME] = association_set_handler
    },
  },
  NAME = "zwub-associator",
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local associator = ZwaveDriver("zwub-associator", driver_template)
associator:run()