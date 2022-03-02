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

local caps = require("st.capabilities")
local config = require("config")
local get_inputs = require("inputs")

local inputCapability = config.inputCapability


--- @param device st.Device
local function map(device)
    local commands = {
        ['main'] = {
            [caps.switch.ID] = {
                [caps.switch.switch.ID] = {
                    cmd = 'PWR',
                    on = '01',
                    off = '00',
                    all = 'ALL',
                    query = 'QSTN',
                },
            },
            [caps.audioMute.ID] = {
                [caps.audioMute.mute.ID] = {
                    cmd = 'AMT',
                    muted = '01',
                    unmuted = '00',
                    query = 'QSTN',
                },
            },
            [caps.audioVolume.ID] = {
                [caps.audioVolume.volume.ID] = {
                    cmd = 'MVL',
                    query = 'QSTN'
                },
            },
            [inputCapability.ID] = {
                [inputCapability.inputSource.ID] = get_inputs(device),
            },
        },
        ['zone2'] = {
            [caps.switch.ID] = {
                [caps.switch.switch.ID] = {
                    cmd = 'ZPW',
                    on = '01',
                    off = '00',
                    query = 'QSTN',
                },
            },
            [caps.audioMute.ID] = {
                [caps.audioMute.mute.ID] = {
                    cmd = 'ZMT',
                    muted = '01',
                    unmuted = '00',
                    query = 'QSTN',
                },
            },
            [caps.audioVolume.ID] = {
                [caps.audioVolume.volume.ID] = {
                    cmd = 'ZVL',
                    query = 'QSTN'
                },
            },
            [inputCapability.ID] = {
                [inputCapability.inputSource.ID] = get_inputs(device),
            },
        }
    }
    commands['zone2'][inputCapability.ID][inputCapability.inputSource.ID].cmd = 'SLZ'
    commands['main'][inputCapability.ID][inputCapability.inputSource.ID].cmd = 'SLI'
    return commands
end

return map