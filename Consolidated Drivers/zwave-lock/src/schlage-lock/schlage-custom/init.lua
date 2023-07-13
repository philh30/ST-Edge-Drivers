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
local cc = require "st.zwave.CommandClass"
local constants = require "st.zwave.constants"
local json = require "dkjson"
local utils = require "st.utils"

local UserCode = (require "st.zwave.CommandClass.UserCode")({version=1})
local user_id_status = UserCode.user_id_status
local Notification = (require "st.zwave.CommandClass.Notification")({version=3})
local access_control_event = Notification.event.access_control
local Configuration = (require "st.zwave.CommandClass.Configuration")({version=2})
local Basic = (require "st.zwave.CommandClass.Basic")({version=1})
local Association = (require "st.zwave.CommandClass.Association")({version=1})
--- @type st.zwave.CommandClass.DoorLock
local DoorLock = (require "st.zwave.CommandClass.DoorLock")({version=1})
local log = require "log"

local alarmMode       = 'platinummassive43262.schlageLockAlarm'
local autoLock        = 'platinummassive43262.autoLock'
local lockAndLeave    = 'platinummassive43262.lockAndLeave'
local vacationMode    = 'platinummassive43262.vacationMode'
local keypadBeep      = 'platinummassive43262.keypadBeep'
local interiorButton  = 'platinummassive43262.schlageInteriorButton'
local unlockCodeName  = 'platinummassive43262.unlockCodeName'

local LockCodesDefaults = require "st.zwave.defaults.lockCodes"

local FINGERPRINTS = {
  {mfr = 0x003B, prod = 0x0001, model = 0x0469},  -- BE469ZP
  {mfr = 0x003B, prod = 0x6341, model = 0x5044},  -- BE469
  {mfr = 0x003B, prod = 0x0001, model = 0x0468},  -- BE468ZP
  {mfr = 0x003B, prod = 0x6349, model = 0x5044},  -- BE468
}

local SCHLAGE_LOCK_CODE_LENGTH_PARAM = {number = 16, size = 1}

local DEFAULT_COMMANDS_DELAY = 4.2 -- seconds

local METHOD = {
  KEYPAD = "keypad",
  MANUAL = "manual",
  COMMAND = "command",
  AUTO = "auto"
}

local paramMap = {
  [3]  = { comp = 'settings', cap = keypadBeep,     attr = capabilities[keypadBeep].keypadBeep,             size = 1, map = { [0] = 'off', [-1] = 'beep' }},
  [4]  = { comp = 'settings', cap = vacationMode,   attr = capabilities[vacationMode].vacationMode,         size = 1, map = { [0] = 'off', [-1] = 'vacation' }},
  [5]  = { comp = 'settings', cap = lockAndLeave,   attr = capabilities[lockAndLeave].lockAndLeave,         size = 1, map = { [0] = 'off', [-1] = 'lockandleave' }},
  [7]  = { comp = 'settings', cap = alarmMode,      attr = capabilities[alarmMode].alarmMode,               size = 1, map = { [0] = 'off', [1] = 'activity', [2] = 'tamper', [3] = 'forcedentry' }},
  [8]  = { comp = 'settings', cap = alarmMode,      attr = capabilities[alarmMode].activitySensitivity,     size = 1, map = { 1, 2, 3, 4, 5 }},
  [9]  = { comp = 'settings', cap = alarmMode,      attr = capabilities[alarmMode].tamperSensitivity,       size = 1, map = { 1, 2, 3, 4, 5 }},
  [10] = { comp = 'settings', cap = alarmMode,      attr = capabilities[alarmMode].forcedEntrySensitivity,  size = 1, map = { 1, 2, 3, 4, 5 }},
  [11] = { comp = 'settings', cap = interiorButton, attr = capabilities[interiorButton].interiorButton,     size = 1, map = { [0] = 'disable', [-1] = 'enable' }},
  [15] = { comp = 'settings', cap = autoLock,       attr = capabilities[autoLock].autoLock,                 size = 1, map = { [0] = 'off', [-1] = 'autolock' }},
}

local function can_handle_schlage_be469(opts, self, device, cmd, ...)
  for _, fingerprint in ipairs(FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

local function call_parent_handler(handlers, self, device, event, args)
  if type(handlers) == "function" then
    handlers = { handlers }  -- wrap as table
  end
  for _, func in ipairs( handlers or {} ) do
      func(self, device, event, args)
  end
end

local function configuration_report(self, device, cmd)
  local param = cmd.args.parameter_number
  local value = cmd.args.configuration_value
  if param == SCHLAGE_LOCK_CODE_LENGTH_PARAM.number then
    local reported_code_length = value
    local current_code_length = device:get_latest_state("main", capabilities.lockCodes.ID, capabilities.lockCodes.codeLength.NAME)
    if current_code_length ~= nil and current_code_length ~= reported_code_length then
      local all_codes_deleted_mocked_command = Notification:Report({
        notification_type = Notification.notification_type.ACCESS_CONTROL,
        event = access_control_event.ALL_USER_CODES_DELETED
      })
      LockCodesDefaults.zwave_handlers[cc.NOTIFICATION][Notification.REPORT](self, device, all_codes_deleted_mocked_command)
    end
    device:emit_event(capabilities.lockCodes.codeLength(reported_code_length))
  elseif ((paramMap[param] or {}).map or {})[value] then
    local comp = device.profile.components[paramMap[param].comp]
    local cap = paramMap[param].cap
    local evt = paramMap[param].attr(paramMap[param].map[value])
    if device:supports_capability_by_id(cap,comp.id) then
      device:emit_component_event(comp,evt)
    end
  end
end

local function get_param(cap)
  for p, v in pairs(paramMap) do
      if v.cap == cap then
          return p
      end
  end
  return nil
end

local function indexOf(array, value)
  for i, v in pairs(array) do
      if v == value then
          return i
      end
  end
  return nil
end

local function schlage_feature_handler(self, device, cmd)
  local cmd_map = { -- identify setter commands here. do not list enumerated commands
    [alarmMode] = { setAlarmMode = 'mode', setActivitySensitivity = 'sensitivity', setTamperSensitivity = 'sensitivity', setForcedSensitivity = 'sensitivity' },
  }
  local alarmMode_map = { setAlarmMode = 7, setActivitySensitivity = 8, setTamperSensitivity = 9, setForcedSensitivity = 10 } --disambiguation for multi-attribute capability
  local cap = cmd.capability
  local param
  if cap == alarmMode then
    param = alarmMode_map[cmd.command]
  else
    param = get_param(cap)
  end
  if param then
    local arg = (cmd_map[cap] or {})[cmd.command]  -- nil for enumerated commands
    local state = arg and cmd.args[arg] or cmd.command
    local value = indexOf(paramMap[param].map,state)
    local size = paramMap[param].size
    if value then
      device:send(Configuration:Set({parameter_number = param,configuration_value = value,size = size}))
    end
  end
end

local function refresh_handler(self, device, args)
  device:send(DoorLock:OperationGet({}))
  if device.preferences.refreshCodes then
    LockCodesDefaults.get_refresh_commands(self,device,'main',0)
  end
  for param, map in pairs(paramMap) do
    if device:supports_capability_by_id(map.cap,map.comp) then
      device:send(Configuration:Get({parameter_number = param}))
    end
  end
end

local function info_changed(self, device, event, args)
  if device.preferences.codeLength then
    local current_code_length = device:get_latest_state("main", capabilities.lockCodes.ID, capabilities.lockCodes.codeLength.NAME)
    if current_code_length == nil then
      device:send(Configuration:Get({parameter_number = SCHLAGE_LOCK_CODE_LENGTH_PARAM.number}))
    elseif current_code_length ~= device.preferences.codeLength then
      log.trace(string.format('Updating code length from %s to %s',current_code_length, device.preferences.codeLength))
      device:send(Configuration:Set({parameter_number = SCHLAGE_LOCK_CODE_LENGTH_PARAM.number, configuration_value = device.preferences.codeLength, size = SCHLAGE_LOCK_CODE_LENGTH_PARAM.size}))
      device:send(Configuration:Get({parameter_number = SCHLAGE_LOCK_CODE_LENGTH_PARAM.number}))
    else
      log.trace('No change to code length')
    end
  else
    log.trace('Code length not set in preferences')
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Notification.Report
local function notification_report(self, device, cmd)
  if (cmd.args.notification_type == Notification.notification_type.HOME_SECURITY) and (cmd.args.event == Notification.event.home_security.INTRUSION) then
    device:emit_event(capabilities.tamperAlert.tamper.detected())
    local delay = 120
    local clear_tamper = function()
      device:emit_event(capabilities.tamperAlert.tamper.clear())
    end
    device.thread:call_with_delay(delay, clear_tamper)
  elseif (cmd.args.notification_type == Notification.notification_type.ACCESS_CONTROL) then
    local event
    local event_code = cmd.args.event
    local lock_action
    if ((event_code >= access_control_event.MANUAL_LOCK_OPERATION and
          event_code <= access_control_event.KEYPAD_UNLOCK_OPERATION) or
            event_code == access_control_event.AUTO_LOCK_LOCKED_OPERATION) then
      -- even event codes are unlocks, odd event codes are locks
      local events = {[0] = capabilities.lock.lock.unlocked(), [1] = capabilities.lock.lock.locked()}
      event = events[event_code & 1]
      local lock_actions = {[0] = nil, [1] = 'Locked'}
      lock_action = lock_actions[event_code & 1]
    elseif (event_code >= access_control_event.MANUAL_NOT_FULLY_LOCKED_OPERATION and
            event_code <= access_control_event.LOCK_JAMMED) then
      event = capabilities.lock.lock.unknown()
    end

    if (event ~= nil) then
      local method_map = {
        [access_control_event.MANUAL_UNLOCK_OPERATION] = METHOD.MANUAL,
        [access_control_event.MANUAL_LOCK_OPERATION] = METHOD.MANUAL,
        [access_control_event.MANUAL_NOT_FULLY_LOCKED_OPERATION] = METHOD.MANUAL,
        [access_control_event.RF_LOCK_OPERATION] = METHOD.COMMAND,
        [access_control_event.RF_UNLOCK_OPERATION] = METHOD.COMMAND,
        [access_control_event.RF_NOT_FULLY_LOCKED_OPERATION] = METHOD.COMMAND,
        [access_control_event.KEYPAD_LOCK_OPERATION] = METHOD.KEYPAD,
        [access_control_event.KEYPAD_UNLOCK_OPERATION] = METHOD.KEYPAD,
        [access_control_event.AUTO_LOCK_LOCKED_OPERATION] = METHOD.AUTO,
        [access_control_event.AUTO_LOCK_NOT_FULLY_LOCKED_OPERATION] = METHOD.AUTO
      }

      event["data"] = {method = method_map[event_code]}

      -- SPECIAL CASES:
      if (event_code == access_control_event.MANUAL_UNLOCK_OPERATION and cmd.args.event_parameter == 2) then
        -- functionality from DTH, some locks can distinguish being manually locked via keypad
        event.data.method = METHOD.KEYPAD
      elseif (event_code == access_control_event.KEYPAD_LOCK_OPERATION or event_code == access_control_event.KEYPAD_UNLOCK_OPERATION) then
        if (device:supports_capability(capabilities.lockCodes)) then
          local lock_codes = device:get_field(constants.LOCK_CODES)
          local code_id = tostring(cmd.args.v1_alarm_level)
          if cmd.args.event_parameter ~= nil and string.len(cmd.args.event_parameter) ~= 0 then
            local event_params = {cmd.args.event_parameter:byte(1,-1)}
            code_id = (#event_params == 1) and tostring(event_params[1]) or tostring(event_params[3])
          end
          local code_name = lock_codes[code_id] or "Code " .. code_id
          event["data"] = { codeId = code_id, codeName = code_name, method = event["data"].method}
        end
      end
      device:emit_event(event)
      device:emit_event(capabilities[unlockCodeName].unlockCodeName({value = lock_action or event.data.codeName or event.data.method or 'Unknown'}))
    end
  else
    call_parent_handler(self.zwave_handlers[cc.NOTIFICATION][Notification.REPORT], self, device, cmd)
  end
end

local function added_handler(self, device, event, args)
  call_parent_handler(self.lifecycle_handlers.added, self, device, event, args)
end

local schlage_lock = {
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
    [capabilities[alarmMode].ID] = {
      [capabilities[alarmMode].commands.setAlarmMode.NAME] = schlage_feature_handler,
      [capabilities[alarmMode].commands.off.NAME] = schlage_feature_handler,
      [capabilities[alarmMode].commands.activity.NAME] = schlage_feature_handler,
      [capabilities[alarmMode].commands.tamper.NAME] = schlage_feature_handler,
      [capabilities[alarmMode].commands.forcedentry.NAME] = schlage_feature_handler,
      [capabilities[alarmMode].commands.setActivitySensitivity.NAME] = schlage_feature_handler,
      [capabilities[alarmMode].commands.setTamperSensitivity.NAME] = schlage_feature_handler,
      [capabilities[alarmMode].commands.setForcedSensitivity.NAME] = schlage_feature_handler,
    },
    [capabilities[autoLock].ID] = {
      [capabilities[autoLock].commands.autolock.NAME] = schlage_feature_handler,
      [capabilities[autoLock].commands.off.NAME] = schlage_feature_handler,
    },
    [capabilities[interiorButton].ID] = {
      [capabilities[interiorButton].commands.enable.NAME] = schlage_feature_handler,
      [capabilities[interiorButton].commands.disable.NAME] = schlage_feature_handler,
    },
    [capabilities[keypadBeep].ID] = {
      [capabilities[keypadBeep].commands.beep.NAME] = schlage_feature_handler,
      [capabilities[keypadBeep].commands.off.NAME] = schlage_feature_handler,
    },
    [capabilities[lockAndLeave].ID] = {
      [capabilities[lockAndLeave].commands.lockandleave.NAME] = schlage_feature_handler,
      [capabilities[lockAndLeave].commands.off.NAME] = schlage_feature_handler,
    },
    [capabilities[vacationMode].ID] = {
      [capabilities[vacationMode].commands.vacation.NAME] = schlage_feature_handler,
      [capabilities[vacationMode].commands.off.NAME] = schlage_feature_handler,
    },
  },
  zwave_handlers = {
    [cc.CONFIGURATION] = {
      [Configuration.REPORT] = configuration_report
    },
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = notification_report
    },
  },
  lifecycle_handlers = {
    infoChanged = info_changed,
    added = added_handler,
  },
  NAME = "Schlage BE469",
  can_handle = can_handle_schlage_be469,
}

return schlage_lock
