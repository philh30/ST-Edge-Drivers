local commands = require('commands')
local server = require('server')
local log = require('log')
local socket = require "cosock.socket"
local caps = require "st.capabilities"

local lifecycle_handler = {}

---------------------------------------
-- node proxy configuration
-- Check IP:Port address for proper format & values
local function validate_address(lanAddress)

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

local function initconfig(device)

  local ip
  local port
  local addr_is_valid = false
      
  ip, port = validate_address(device.preferences.lanAddress)
  if ip ~= nil then
    conf.stnp.ip = ip
    conf.stnp.port = port
    addr_is_valid = true
  else
    log.warn ('Invalid LAN address')
  end

  conf.stnp.auth = device.preferences.authCode
      
  log.info (string.format('Using config prefs: %s:%d, authcode: %s, plugin: %s', conf.stnp.ip, conf.stnp.port, conf.stnp.auth, conf.stnp.plugin))
  return(addr_is_valid)

end

function lifecycle_handler.do_refresh(driver, device)
  if device.device_network_id:match('mpr%-sg6z|c1|z1') then
    local serverRunning = false
    if driver.server then
      if driver.server.sock then
        serverRunning=true
      end
    end
    if not serverRunning then server.start(driver, device) end
    if initconfig(device) then 
      commands.subscribe(driver,device)
    end
  end
  local controller = device.device_network_id:match('mpr%-sg6z|c(%d+)')
  local zone = device.device_network_id:match('mpr%-sg6z|c%d+|z(%d+)')
  if controller and zone then
    commands.send_lan_command('GET', "plugins/mpr-sg6z/controllers/" .. controller .. "/zones/" .. zone)
  end
  --[[
  if TIMERS.OFFLINE then
    driver:cancel_timer(TIMERS.OFFLINE)
    TIMERS.OFFLINE = nil
  end
  TIMERS.OFFLINE = driver:call_with_delay(60, commands.set_offline, 'Offline timer')
  --]]
end

function lifecycle_handler.init(driver, device)
  log.debug(device.id .. ": " .. device.device_network_id .. " > INITIALIZING")
  if device.device_network_id:match('mpr%-sg6z|c1|z1') then
    initialized = true
    socket.sleep(5)
  end
  lifecycle_handler.do_refresh(driver, device)
  if not TIMERS.REFRESH then
    TIMERS.REFRESH = driver:call_on_schedule(5*60, commands.set_offline, 'Offline timer')
  end
end

function lifecycle_handler.added(driver, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > ADDED")
  log.debug ('added lifecycle event')
  device:online()
  --[[
  device:emit_event(caps.switch.switch.on())
  device:emit_event(caps.audioVolume.volume({value = 20}))
  device:emit_event(caps.audioMute.mute.unmuted())
  device:emit_event(caps['platinummassive43262.monopriceAudioAdjustments'].treble({value=7}))
  device:emit_event(caps['platinummassive43262.monopriceAudioAdjustments'].bass({value=7}))
  device:emit_event(caps['platinummassive43262.monopriceAudioAdjustments'].balance({value=10}))
  device:emit_event(caps['platinummassive43262.doNotDisturb'].doNotDisturb({value = 'off'}))
  device:emit_event(caps['platinummassive43262.monopriceSource'].source({value = 1}))
  device:emit_event(caps['platinummassive43262.sourceName'].name({value = 'Source 1'}))
  --]]
  lifecycle_handler.do_refresh(driver, device)
end

function lifecycle_handler.driverSwitched(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > DRIVER SWITCHED")
end

function lifecycle_handler.infoChanged(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > INFO CHANGED")
  if device.device_network_id:match('mpr%-sg6z|c1|z1') and initconfig(device) then
    commands.subscribe(driver,device)
  end
end

function lifecycle_handler.doConfigure(driver,device)
  log.info(device.id .. ": " .. device.device_network_id .. " > DO CONFIGURE")
end

function lifecycle_handler.removed(_, device)
  log.info(device.id .. ": " .. device.device_network_id .. " > REMOVED")
end

return lifecycle_handler
