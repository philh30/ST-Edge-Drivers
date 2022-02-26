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

config.DEVICE_PROFILE='sony-tv'
config.DEVICE_TYPE='LAN'
config.MC_ADDRESS='239.255.255.250'
config.MC_PORT=1900
config.MC_TIMEOUT=5
config.PORT=20060
config.ST = 'urn:schemas-sony-com:service:ScalarWebAPI:1'
config.MSEARCH= table.concat({
    'M-SEARCH * HTTP/1.1',
    'HOST: 239.255.255.250:1900',
    'MAN: "ssdp:discover"',
    'MX: 4',
    'ST: ' .. config.ST,
    '\r\n'
  }, '\r\n')
config.SCHEDULE_PERIOD=300

return config
