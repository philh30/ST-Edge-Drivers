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

local config = {}

config.inputCapability = caps['platinummassive43262.onkyoInputSource']
config.commandCapability = caps['platinummassive43262.onkyoRawCommand']

config.DEVICE_PROFILE='onkyo'
config.DEVICE_TYPE='LAN'
config.MC_ADDRESS='239.255.255.250'
config.MC_PORT=60128
config.MC_TIMEOUT=2
config.MSEARCH_ONKYO= 'ISCP' .. '\x00\x00\x00\x10\x00\x00\x00' .. string.char(10) .. '\x01\x00\x00\x00' .. '!xECNQSTN' .. '\x0D'
config.MSEARCH_PIONEER= 'ISCP' .. '\x00\x00\x00\x10\x00\x00\x00' .. string.char(10) .. '\x01\x00\x00\x00' .. '!pECNQSTN' .. '\x0D'
config.SCHEDULE_PERIOD=300

return config
