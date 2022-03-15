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
local disco = require("disco")
local cap_defs = require("cap_defs")
local lifecycle = require("lifecycle_handlers")
local command_handlers = require("command_handlers")

DEVICE_MAP = {}

local driver = Driver('sony-tv', {
    discovery = disco.start,
    capability_handlers = {
      [caps.refresh.ID] = {
        [caps.refresh.commands.refresh.NAME] = command_handlers.refresh_handler,
      },
      [caps.switch.ID] = {
        [caps.switch.commands.on.NAME] = command_handlers.set_switch,
        [caps.switch.commands.off.NAME] = command_handlers.set_switch,
      },
      [caps.audioMute.ID] = {
        [caps.audioMute.commands.mute.NAME] = command_handlers.set_mute,
        [caps.audioMute.commands.unmute.NAME] = command_handlers.set_mute,
        [caps.audioMute.commands.setMute.NAME] = command_handlers.set_mute,
      },
      [caps.audioVolume.ID] = {
        [caps.audioVolume.commands.setVolume.NAME] = command_handlers.set_volume,
        [caps.audioVolume.commands.volumeUp.NAME] = command_handlers.volume_up,
        [caps.audioVolume.commands.volumeDown.NAME] = command_handlers.volume_down,
      },
      [caps.mediaPresets.ID] = {
        [caps.mediaPresets.commands.playPreset.NAME] = command_handlers.launch_app,
      },
      [cap_defs.inputSource.ID] = {
        [cap_defs.inputSource.commands.setInputSource.NAME] = command_handlers.set_input,
      },
      [cap_defs.pictureMute.ID] = {
        [cap_defs.pictureMute.commands.mute.NAME] = command_handlers.set_pmute,
        [cap_defs.pictureMute.commands.unmute.NAME] = command_handlers.set_pmute,
        [cap_defs.pictureMute.commands.setMute.NAME] = command_handlers.set_pmute,
      },
      [cap_defs.irccCommand.ID] = {
        [cap_defs.irccCommand.commands.sendCommand.NAME] = command_handlers.ircc_command,
      },
      [cap_defs.homeButton.ID] = {
        [cap_defs.homeButton.commands.home.NAME] = command_handlers.set_home,
      },
      [cap_defs.tvChannel.ID] = {
        [cap_defs.tvChannel.commands.setTvChannel.NAME] = command_handlers.set_channel,
        [cap_defs.tvChannel.commands.channelUp.NAME] = command_handlers.channel_up,
        [cap_defs.tvChannel.commands.channelDown.NAME] = command_handlers.channel_down,
      },
    },
    lifecycle_handlers = lifecycle,
  }
)

driver:run()