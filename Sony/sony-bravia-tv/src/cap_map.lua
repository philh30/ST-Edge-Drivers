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
local cap_defs = require("cap_defs")

local map = {
    ['main'] = {
        [caps.switch.ID] = {
            [caps.switch.switch.ID] = {
                cmd = 'POWR',
                on = '0000000000000001',
                off = '0000000000000000',
                type = 'binary',
                query = true,
            },
        },
        [caps.audioMute.ID] = {
            [caps.audioMute.mute.ID] = {
                cmd = 'AMUT',
                muted = '0000000000000001',
                unmuted = '0000000000000000',
                type = 'binary',
                query = true,
            },
        },
        [caps.audioVolume.ID] = {
            [caps.audioVolume.volume.ID] = {
                cmd = 'VOLU',
                type = 'integer',
                query = true,
            },
        },
        [cap_defs.pictureMute.ID] = {
            [cap_defs.pictureMute.pictureMute.ID] = {
                cmd = 'PMUT',
                muted = '0000000000000001',
                unmuted = '0000000000000000',
                type = 'binary',
                query = true,
            },
        },
        [cap_defs.irccCommand.ID] = {
            [cap_defs.irccCommand.irccCommand.ID] = {
                cmd = 'IRCC',
                type = 'integer',
                query = false,
            },
        },
        [cap_defs.tvChannel.ID] = {
            [cap_defs.tvChannel.tvChannel.ID] = {
                cmd = 'CHNN',
                type = 'decimal',
                query = true,
            },
        },
        [cap_defs.inputSource.ID] = {
            [cap_defs.inputSource.inputSource.ID] = {
                cmd = 'INPT',
                TV = '0000000000000000',
                HDMI1 = '0000000100000001',
                HDMI2 = '0000000100000002',
                HDMI3 = '0000000100000003',
                HDMI4 = '0000000100000004',
                HDMI5 = '0000000100000005',
                HDMI6 = '0000000100000006',
                HDMI7 = '0000000100000007',
                HDMI8 = '0000000100000008',
                HDMI9 = '0000000100000009',
                HDMI10 = '0000000100000010',
                SCART1 = '0000000200000001',
                SCART2 = '0000000200000002',
                SCART3 = '0000000200000003',
                SCART4 = '0000000200000004',
                SCART5 = '0000000200000005',
                SCART6 = '0000000200000006',
                SCART7 = '0000000200000007',
                SCART8 = '0000000200000008',
                SCART9 = '0000000200000009',
                SCART10 = '0000000200000010',
                COMPOSITE1 = '0000000300000001',
                COMPOSITE2 = '0000000300000002',
                COMPOSITE3 = '0000000300000003',
                COMPOSITE4 = '0000000300000004',
                COMPOSITE5 = '0000000300000005',
                COMPOSITE6 = '0000000300000006',
                COMPOSITE7 = '0000000300000007',
                COMPOSITE8 = '0000000300000008',
                COMPOSITE9 = '0000000300000009',
                COMPOSITE10 = '0000000300000010',
                COMPONENT1 = '0000000400000001',
                COMPONENT2 = '0000000400000002',
                COMPONENT3 = '0000000400000003',
                COMPONENT4 = '0000000400000004',
                COMPONENT5 = '0000000400000005',
                COMPONENT6 = '0000000400000006',
                COMPONENT7 = '0000000400000007',
                COMPONENT8 = '0000000400000008',
                COMPONENT9 = '0000000400000009',
                COMPONENT10 = '0000000400000010',
                MIRROR1 = '0000000500000001',
                MIRROR2 = '0000000500000002',
                MIRROR3 = '0000000500000003',
                MIRROR4 = '0000000500000004',
                MIRROR5 = '0000000500000005',
                MIRROR6 = '0000000500000006',
                MIRROR7 = '0000000500000007',
                MIRROR8 = '0000000500000008',
                MIRROR9 = '0000000500000009',
                MIRROR10 = '0000000500000010',
                PC1 = '0000000600000001',
                PC2 = '0000000600000002',
                PC3 = '0000000600000003',
                PC4 = '0000000600000004',
                PC5 = '0000000600000005',
                PC6 = '0000000600000006',
                PC7 = '0000000600000007',
                PC8 = '0000000600000008',
                PC9 = '0000000600000009',
                PC10 = '0000000600000010',
                type = 'input',
                query = true,
            },
        },
    }
}

return map