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

local json = require('dkjson')

local function process_multiline(resp_array)
    local str = ''
    for _, resp in ipairs(resp_array) do
        str = str .. resp
    end
    local t = json.decode(str,1,nil)
    if t.result then t = t.result[1] end
    return t
end

return process_multiline