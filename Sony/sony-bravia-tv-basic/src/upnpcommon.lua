--[[
  Copyright 2021 Todd Austin

  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
  except in compliance with the License. You may obtain a copy of the License at:

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software distributed under the
  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
  either express or implied. See the License for the specific language governing permissions
  and limitations under the License.


  DESCRIPTION
  
  Common UPnP library routines (used across modules)
  
  Several of these routines heavily borrowed from SmartThings example LAN drivers; much credit to Patrick Barrett

--]]

-- Create table of msg headers from SSDP response
local function process_response(resp, types)
  local info = {}
  
  local prefix = string.match(resp, "^([%g ]*)\r\n", 1)
  local match = false
  
  for _, resptype in ipairs(types) do
		if string.find(prefix, resptype, nil, "plaintext") ~= nil then
			match = true
		end
  end

	if match then

    local resp2 = string.gsub(resp, "^([%g ]*)\r\n", "")
  
    for k, v in string.gmatch(resp2, "([%g]*):([%g ]*)\r\n") do
      v = string.gsub(v, "^ *", "", 1)  -- strip off any leading spaces
      info[string.lower(k)] = v
    end
    return info
    
  else
    return nil
  end
end

return {
	process_response = process_response,
}