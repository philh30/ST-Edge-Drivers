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

local inputCapability = config.inputCapability

local function format_hex(n)
    n = n and n or -1
    return (n==-1 and '') or ((n<10 and '0' or '') .. string.format('%x',n))
end

--- @param device st.Device
local map = {
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
            [inputCapability.inputSource.ID] = {
                cmd = 'SLI',
                BDDVD = '10',
                CABLE = '01',
                GAME = '02',
                NET = '2B',
                PC = '05',
                STREAMINGBOX = '11',
                TV = '12',
                USB = '29',
                AUX = '03',
                BLUETOOTH = '2E',
                AM = '25',
                FM = '24',
                CD = '23',
                PHONO = '22',
                UNKNOWN = '80',
                query = 'QSTN',
            },
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
            [inputCapability.inputSource.ID] = {
                cmd = 'SLZ',
                BDDVD = '10',
                CABLE = '01',
                GAME = '02',
                NET = '2B',
                PC = '05',
                STREAMINGBOX = '11',
                TV = '12',
                USB = '29',
                AUX = '03',
                BLUETOOTH = '2E',
                AM = '25',
                FM = '24',
                CD = '23',
                PHONO = '22',
                UNKNOWN = '80',
                query = 'QSTN',
            },
        },
    }
}

return map