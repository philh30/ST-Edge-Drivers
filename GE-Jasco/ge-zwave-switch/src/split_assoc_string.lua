-- Author: philh30
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

local log = require "log"

local function splitAssocString (inputstr, sep, maxnodes, addhub)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    if tonumber(str,16) and ((tonumber(str,16) ~= 1) or not addhub) then table.insert(t, tonumber(str,16)) end
  end
  if #t > maxnodes then
    local temp = {}
    for x = 1, maxnodes, 1 do
      temp[x] = t[x]
    end
    t = temp
    log.warn(string.format('Too many node IDs - ignoring any beyond limit of %s',maxnodes))
  end
  return t
end

return splitAssocString