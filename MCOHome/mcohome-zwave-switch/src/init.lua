-- Copyright 2022 SmartThings
-- Modified 2022 philh30 - update_preferences function
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
--- @type st.zwave.defaults
local defaults = require "st.zwave.defaults"
--- @type st.zwave.Driver
local ZwaveDriver = require "st.zwave.driver"
--- @type st.zwave.constants
local constants = require "st.zwave.constants"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.Association
local Association = (require "st.zwave.CommandClass.Association")({ version=2 })
--- @type st.zwave.CommandClass.Basic
local Basic = (require "st.zwave.CommandClass.Basic")({ version=1 })
--- @type st.zwave.CommandClass.MultiChannelAssociation
local MultiChannelAssociation = (require "st.zwave.CommandClass.MultiChannelAssociation")({ version=4 })
--- @type st.zwave.CommandClass.Configuration
local Configuration = (require "st.zwave.CommandClass.Configuration")({ version=4 })
--- @type st.zwave.CommandClass.SwitchAll
local SwitchAll = (require "st.zwave.CommandClass.SwitchAll")({ version=1 })
--- @type st.zwave.CommandClass.SwitchBinary
local SwitchBinary = (require "st.zwave.CommandClass.SwitchBinary")({version=2,strict=true})
--- @type st.zwave.CommandClass.SwitchMultilevel
local SwitchMultilevel = (require "st.zwave.CommandClass.SwitchMultilevel")({version=4,strict=true})
--- @type st.zwave.CommandClass.MultiChannel
local MultiChannel = (require "st.zwave.CommandClass.MultiChannel")({ version=2 })
local preferencesMap = require "preferences"
local configurations = require "configurations"
local splitAssocString = require "split_assoc_string"
local log = require "log"

local MCOHOME_FINGERPRINT = {
  {mfr = 0x015F, prod = 0x3141, model = 0x1302, lifeline = 5, switchall = 2}, -- MCOHome MH-S314 Legacy
  {mfr = 0x015F, prod = 0x3121, model = 0x1302, lifeline = 3, switchall = 2}, -- MCOHome MH-S312 Legacy
  {mfr = 0x015F, prod = 0x3141, model = 0x5102, lifeline = 1, switchall = 1}, -- MCOHome MH-S314
}

local IS_POLLING = {}

--- Map component to end_points(channels)
---
--- @param device st.zwave.Device
--- @param component_id string ID
--- @return table dst_channels destination channels e.g. {2} for Z-Wave channel 2 or {} for unencapsulated
local function component_to_endpoint(device, component_id)
  local ep_num = component_id:match("switch(%d)")
  return { ep_num and tonumber(ep_num) }
end

--- Map end_point(channel) to Z-Wave endpoint
---
--- @param device st.zwave.Device
--- @param ep number the endpoint(Z-Wave channel) ID to find the component for
--- @return string the component ID the endpoint matches to
local function endpoint_to_component(device, ep)
  local switch_comp = string.format("switch%d", ep)
  if device.profile.components[switch_comp] ~= nil then
    return switch_comp
  else
    return "main"
  end
end

--- @param device st.zwave.Device
local function set_lifeline(device)
  local is_set = device:get_field("LIFELINE")
  local lifeline_group
  local hubnode = device.driver.environment_info.hub_zwave_id
  for _, fingerprint in ipairs(MCOHOME_FINGERPRINT) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      lifeline_group = fingerprint.lifeline
    end
  end
  if not is_set then
    -- Lifeline group has not yet been checked, so check it
    if lifeline_group then
      log.debug("Query to determine if lifeline is set")
      device:send(Association:Get({grouping_identifier = lifeline_group}))
    end
  elseif is_set == 0 then
    -- Lifeline group previously reported to not contain the hub, so attempt to clear and set it
    log.debug(string.format("Lifeline association group not set! Attempting to add hub node to Association Group %s.",lifeline_group))
    if lifeline_group then
      device:send(Association:Remove({grouping_identifier = lifeline_group, node_ids = {}}))
      device:send(Association:Set({grouping_identifier = lifeline_group, node_ids = {hubnode}}))
      device:send(Association:Get({grouping_identifier = lifeline_group}))
    end
  else
    log.trace("Lifeline association already set.")
  end
end

--- Polling for devices that fall offline
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
local set_up_polling = function(self, device)
  local poll_interval = device.preferences.pollingInterval
  local timer
  local do_poll = function()
    log.trace(string.format('POLLING %s every %s minutes',device.device_network_id,poll_interval))
    device:send_to_component(SwitchBinary:Get({}),'switch1')
  end
  if IS_POLLING[device.device_network_id] then
    if poll_interval ~= IS_POLLING[device.device_network_id].interval then
      device.thread:cancel_timer(IS_POLLING[device.device_network_id].timer)
      if poll_interval == 0 then
        log.trace(string.format('POLLING %s cancelled',device.device_network_id))
        IS_POLLING[device.device_network_id] = nil
      else
        log.trace(string.format('POLLING %s every %s minutes',device.device_network_id,poll_interval))
        timer = device.thread:call_on_schedule(60*poll_interval,do_poll,string.format('POLLING %s',device.device_network_id))
        IS_POLLING[device.device_network_id] = {timer = timer, interval = poll_interval}
      end
    end
  else
    if poll_interval > 0 then
      log.trace(string.format('POLLING %s every %s minutes',device.device_network_id,poll_interval))
      timer = device.thread:call_on_schedule(60*poll_interval,do_poll,string.format('POLLING %s',device.device_network_id))
      IS_POLLING[device.device_network_id] = {timer = timer, interval = poll_interval}
    end
  end
end

--- Initialize device
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local device_init = function(driver, device)
  device:set_component_to_endpoint_fn(component_to_endpoint)
  device:set_endpoint_to_component_fn(endpoint_to_component)
  set_lifeline(device)
  set_up_polling(driver,device)
end

--- Handle preference changes
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function update_preferences(driver, device, args)
  local preferences = preferencesMap.get_device_parameters(device)
  for id, value in pairs(device.preferences) do
    if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value and preferences and preferences[id]) then
      if (preferences[id]or {}).type == 'config' then
        local new_parameter_value = preferencesMap.to_numeric_value(device.preferences[id])
        device:send(Configuration:Set({parameter_number = preferences[id].parameter_number, size = preferences[id].size, configuration_value = new_parameter_value}))
        device:send(Configuration:Get({parameter_number = preferences[id].parameter_number}))
      elseif (preferences[id]or {}).type == 'assoc' then
        local group = preferences[id].group
        local maxnodes = preferences[id].maxnodes
        local addhub = preferences[id].addhub
        local nodes,multi_nodes,multi = splitAssocString(value,',',maxnodes,addhub)
        local hubnode = device.driver.environment_info.hub_zwave_id
        device:send(Association:Remove({grouping_identifier = group, node_ids = {}}))
        if addhub then device:send(Association:Set({grouping_identifier = group, node_ids = {hubnode}})) end
        if (#multi_nodes + #nodes) > 0 then
          if multi then
            device:send(MultiChannelAssociation:Set({grouping_identifier = group, node_ids = nodes, multi_channel_nodes = multi_nodes}))
          else
            device:send(Association:Set({grouping_identifier = group, node_ids = nodes}))
          end
        end
        if multi then
          device:send(MultiChannelAssociation:Get({grouping_identifier = group}))
        else
          device:send(Association:Get({grouping_identifier = group}))
        end
      end
    end
  end
  if ((args.old_st_store or {}).preferences or {}).chooseProfile ~= (device.preferences or {}).chooseProfile then
    local create_device_msg = {
      profile = device.preferences.chooseProfile,
    }
    assert (device:try_update_metadata(create_device_msg), "Failed to change device")
    log.warn('Changed to new profile. App restart required.')
  end
  set_up_polling(driver,device)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function device_added(driver, device)
  configurations.initial_configuration(driver, device)
  if device:supports_capability_by_id('platinummassive43262.deviceInformation','deviceInfo') then
    device:emit_component_event(device.profile.components.deviceInfo,capabilities['platinummassive43262.deviceInformation'].deviceInformation({value = device.device_network_id}))
  end
  device:refresh()
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function main_switch_status(driver,device)
    local switch_state = { on=0, off=0 }
    for _, comp in pairs(device.profile.components) do
        if comp.id:match("switch(%d)") then
            local state = device:get_latest_state(comp.id,'switch','switch')
            if state then
                switch_state[state]=switch_state[state]+1
            else
                log.warn(string.format('Component %s returned nil state',comp.id))
            end
        end
    end
    if device.preferences.mainSwitch == '0' then
        if switch_state.on > 0 then
            device:emit_event(capabilities.switch.switch.on())
        else
            device:emit_event(capabilities.switch.switch.off())
        end
    else
        if switch_state.off > 0 then
            device:emit_event(capabilities.switch.switch.off())
        else
            device:emit_event(capabilities.switch.switch.on())
        end
    end
end

--- Default handler for basic, binary and multilevel switch reports for
--- switch-implementing devices
---
--- This converts the command value from 0 -> Switch.switch.off, otherwise
--- Switch.switch.on.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.SwitchMultilevel.Report|st.zwave.CommandClass.SwitchBinary.Report|st.zwave.CommandClass.Basic.Report
local function switch_report_handler(driver, device, cmd)
  local event
  if cmd.args.target_value ~= nil then
    -- Target value is our best inidicator of eventual state.
    -- If we see this, it should be considered authoritative.
    if cmd.args.target_value == SwitchBinary.value.OFF_DISABLE then
      event = capabilities.switch.switch.off()
    else
      event = capabilities.switch.switch.on()
    end
  else
    if cmd.args.value == SwitchBinary.value.OFF_DISABLE then
      event = capabilities.switch.switch.off()
    else
      event = capabilities.switch.switch.on()
    end
  end
  device:emit_event_for_endpoint(cmd.src_channel, event)
  main_switch_status(driver,device)
end

--- Interrogate the device's supported command classes to determine whether a
--- BASIC, SWITCH_BINARY or SWITCH_MULTILEVEL set should be issued to fulfill
--- the on/off capability command.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param value number st.zwave.CommandClass.SwitchBinary.value.OFF_DISABLE or st.zwave.CommandClass.SwitchBinary.value.ON_ENABLE
--- @param command table The capability command table
local function switch_set_helper(driver, device, value, command)
  local set
  local get
  local delay = constants.DEFAULT_GET_STATUS_DELAY

  set = SwitchBinary:Set({ target_value = value, duration = 0 })
  get = SwitchBinary:Get({})
  device:send_to_component(set, command.component)
  local query_device = function()
    device:send_to_component(get, command.component)
  end
  device.thread:call_with_delay(delay, query_device)
end

--- Issue a switch-on command to the specified device.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command table The capability command table
local function on_handler(driver, device, command)
  local delay = constants.DEFAULT_GET_STATUS_DELAY
  if command.component == 'main' then
    local bitmask = 3
    local switchall_cmd = 2
    for _, fingerprint in ipairs(MCOHOME_FINGERPRINT) do
      if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
        switchall_cmd = fingerprint.switchall
      end
    end
    if device.profile.components.switch4 ~= nil then bitmask = 15 end
    if switchall_cmd == 1 then
      device:send(MultiChannel:CmdEncap({ source_end_point=0, res=false, destination_end_point=bitmask, bit_address=true, command_class=cc.SWITCH_BINARY, command=SwitchBinary.SET, parameter='\xFF'}))
    else
      device:send(SwitchAll:On({}))
    end
    local query_device = function()
      local get = SwitchBinary:Get({})
      for _, comp in pairs(device.profile.components) do
        if comp.id:match("switch(%d)") then
          device:send_to_component(get, comp.id)
        end
      end
    end
    device.thread:call_with_delay(delay, query_device)
  else
    switch_set_helper(driver, device, SwitchBinary.value.ON_ENABLE, command)
  end
end

--- Issue a switch-off command to the specified device.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command table The capability command table
local function off_handler(driver, device, command)
  local delay = constants.DEFAULT_GET_STATUS_DELAY
  if command.component == 'main' then
    local bitmask = 3
    local switchall_cmd = 2
    for _, fingerprint in ipairs(MCOHOME_FINGERPRINT) do
      if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
        switchall_cmd = fingerprint.switchall
      end
    end
    if device.profile.components.switch4 ~= nil then bitmask = 15 end
    if switchall_cmd == 1 then
      device:send(MultiChannel:CmdEncap({ source_end_point=0, res=false, destination_end_point=bitmask, bit_address=true, command_class=cc.SWITCH_BINARY, command=SwitchBinary.SET, parameter='\x00'}))
    else
      device:send(SwitchAll:Off({}))
    end
    local query_device = function()
      local get = SwitchBinary:Get({})
      for _, comp in pairs(device.profile.components) do
        if comp.id:match("switch(%d)") then
          device:send_to_component(get, comp.id)
        end
      end
    end
    device.thread:call_with_delay(delay, query_device)
  else
    switch_set_helper(driver, device, SwitchBinary.value.OFF_DISABLE, command)
  end
end

--- Refresh the device.
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command table The capability command table
local function refresh_handler(driver, device, command)
  log.trace("Refresh")
  get = SwitchBinary:Get({})
  for _, comp in pairs(device.profile.components) do
    if comp.id:match("switch(%d)") then
      device:send_to_component(get, comp.id)
    end
  end
end

local function table_contains(t,v)
  for _, value in ipairs(t) do
    if value == v then
      return true
    end
  end
  return false
end

--- Association:Report handler
---
--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
--- @param command st.zwave.CommandClass.Association.Report
local function assoc_report_handler(driver, device, command)
  local lifeline_group
  for _, fingerprint in ipairs(MCOHOME_FINGERPRINT) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      lifeline_group = fingerprint.lifeline
    end
  end
  if lifeline_group and (lifeline_group == command.args.grouping_identifier) then
    local is_set = device:get_field("LIFELINE")
    if table_contains(command.args.node_ids,driver.environment_info.hub_zwave_id) then
      if is_set ~= 1 then device:set_field("LIFELINE",1,{persist = true}) end
    else
      if not is_set then
        -- Lifeline association group isn't set, and this is the first association report received, so try to set it
        device:set_field("LIFELINE",0,{persist = true})
        set_lifeline(device)
      else
        -- Lifeline association group isn't set, but we've seen an association report before. Flag it as not set but don't immediately try as we don't want to get caught in a loop
        if is_set ~= 0  then device:set_field("LIFELINE",0,{persist = true}) end
      end
    end
  end
end

-------------------------------------------------------------------------------------------
-- Register message handlers and run driver
-------------------------------------------------------------------------------------------
local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.refresh,
  },
  lifecycle_handlers = {
    init = device_init,
    infoChanged = update_preferences,
    added = device_added
  },
  zwave_handlers = {
    [cc.ASSOCIATION] = {
        [Association.REPORT] = assoc_report_handler
    },
    [cc.BASIC] = {
      [Basic.REPORT] = switch_report_handler
    },
    [cc.SWITCH_BINARY] = {
      [SwitchBinary.REPORT] = switch_report_handler
    },
    [cc.SWITCH_MULTILEVEL] = {
      [SwitchMultilevel.REPORT] = switch_report_handler
    }
  },
  capability_handlers = {
    [capabilities.switch.ID] = {
      [capabilities.switch.commands.on.NAME] = on_handler,
      [capabilities.switch.commands.off.NAME] = off_handler,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    }
},
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
--- @type st.zwave.Driver
local switch = ZwaveDriver("zwave_switch", driver_template)
switch:run()
