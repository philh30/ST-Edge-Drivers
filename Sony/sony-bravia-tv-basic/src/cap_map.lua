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

local map = {
    ['main'] = {
        [caps.switch.ID] = {
            [caps.switch.switch.ID] = {
                cmd = 'POWR',
                on = '0000000000000001',
                off = '0000000000000000',
            },
        },
        [caps.audioMute.ID] = {
            [caps.audioMute.mute.ID] = {
                cmd = 'AMUT',
                muted = '0000000000000001',
                unmuted = '0000000000000000',
            },
        },
        [caps.audioVolume.ID] = {
            [caps.audioVolume.volume.ID] = {
                cmd = 'VOLU',
            },
        },
    }
}

return map