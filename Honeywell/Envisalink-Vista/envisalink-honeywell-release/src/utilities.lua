local log = require('log')

local utilities = {}

---------------------------------------
-- Parses string inputstr using sep as delimeter, returns a table of results
function utilities.splitString (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

---------------------------------------
-- Iterate through and log.debug all levels of a table. Pass '  ' to function as tab
function utilities.disptable(table, tab)
  
  for key, value in pairs(table) do
    log.debug (tab .. key, value)
    if type(value) == 'table' then
      utilities.disptable(value, '  ' .. tab)
    end
  end
end

---------------------------------------
-- Check IP:Port address for proper format & values
function utilities.validate_address(lanAddress)

  local valid = true
  
  local ip = lanAddress:match('^(%d.+):')
  local port = tonumber(lanAddress:match(':(%d+)$'))
  
  if ip then
    local chunks = {ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")}
    if #chunks == 4 then
      for i, v in pairs(chunks) do
        if tonumber(v) > 255 then 
          valid = false
          break
        end
      end
    else
      valid = false
    end
  else
    valid = false
  end
  
  
  if port then
    if type(port) == 'number' then
      if (port < 1) or (port > 65535) then 
        valid = false
      end
    else
      valid = false
    end
  else
    valid = false
  end
  
  if valid then
    return ip, port
  else
    return nil
  end
end

---------------------------------------
-- Set all child devices online or offline
function utilities.set_online(driver, status)
	local device_list = driver:get_devices()
  for _, dev in ipairs(device_list) do
		if status == 'online' then
			dev:online()
		elseif status == 'offline' then
			dev:offline()
		end
	end
end

return utilities