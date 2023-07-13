local cosock = require('cosock')
local http = cosock.asyncify('socket.http')
local ltn12 = require('ltn12')
local capabilities = require('st.capabilities')
local log = require('log')
http.TIMEOUT = 5

local command_handler = {}

function command_handler.set_offline(driver)
  local device_list = driver:get_devices()
  for _, device in ipairs(device_list) do
    device:offline()
  end
  if TIMERS.OFFLINE then
    driver:cancel_timer(TIMERS.OFFLINE)
    TIMERS.OFFLINE = nil
  end
end

local function build_command(device, attr, val)
  local controller = device.device_network_id:match('mpr%-sg6z|c(%d+)')
  local zone= device.device_network_id:match('mpr%-sg6z|c%d+|z(%d+)')
  command_handler.send_lan_command('GET', "plugins/" .. conf.stnp.plugin .. "/controllers/" .. controller .. "/zones/" .. zone .. "/" .. attr .. "/" .. val)
end

local function createDevice(driver, controller, zone, name, devprofile)
  local id = conf.stnp.plugin .. '|c' .. tostring(controller) .. '|z' .. tostring(zone)
    
  local create_device_msg = {
                              type = "LAN",
                              device_network_id = id,
                              label = name,
                              profile = devprofile,
                              manufacturer = 'Monoprice',
                              model = 'MPR-SG6Z',
                              vendor_provided_label = 'Monoprice Zone',
                            }
                        
  log.info(string.format("Creating Zone #%d: '%s'", zone, id))
  log.info(create_device_msg.type, create_device_msg.device_network_id, create_device_msg.label, create_device_msg.profile, create_device_msg.manufacturer, create_device_msg.model, create_device_msg.vendor_provided_label)
  assert (driver:try_create_device(create_device_msg), "failed to create zone device")
end

function command_handler.on(driver, device, command)
  build_command(device,'state',1)
end

function command_handler.off(driver, device, command)
  build_command(device,'state',0)
end

function command_handler.mute(driver, device, command)
  build_command(device,'mute',1)
end

function command_handler.unmute(driver, device, command)
  build_command(device,'mute',0)
end

function command_handler.volume(driver, device, command)
  build_command(device,'volume',tostring(command.args.volume))
end

function command_handler.setLevel(driver, device, command)
  build_command(device,'volume',tostring(command.args.level))
end

function command_handler.setSource(driver, device, command)
  build_command(device,'source',tostring(command.args.source))
end

function command_handler.setTreble(driver, device, command)
  build_command(device,'treble',tostring(command.args.treble))
end

function command_handler.setBass(driver, device, command)
  build_command(device,'bass',tostring(command.args.bass))
end

function command_handler.setBalance(driver, device, command)
  build_command(device,'balance',tostring(command.args.balance))
end

function command_handler.dnd_on(driver, device, command)
  build_command(device,'dnd',1)
end

function command_handler.dnd_off(driver, device, command)
  build_command(device,'dnd',0)
end

function command_handler.discover(driver, device, command)
  command_handler.send_lan_command('GET','plugins/mpr-sg6z/discover')
end

local function handle_discovery(driver, body)
  log.trace('Discovery message received')
  for _,c in ipairs(body.controllers) do
    for _,z in ipairs(c.zones) do
      if c.controller and z.zone and z.name then
        log.trace("Found zone! Controller: " .. c.controller, "Zone: " .. z.zone .. " - " .. z.name)
        createDevice(driver,c.controller,z.zone,'MPR: ' .. z.name,'monoprice-zone')
      end
    end
  end
end

----------------
-- Process notification from STNP
function command_handler.notification_handler(driver, body)
  local device_list = driver:get_devices()
  --[[
  if TIMERS.OFFLINE then
    driver:cancel_timer(TIMERS.OFFLINE)
    TIMERS.OFFLINE = nil
  end
  TIMERS.OFFLINE = driver:call_with_delay(60, command_handler.set_offline, 'Offline timer')
  --]]
  if body.type == 'discover' then
    handle_discovery(driver, body)
  elseif body.type == 'zone' then
    for _, device in ipairs(device_list) do
      if device.device_network_id == conf.stnp.plugin .. '|c' .. body.controller .. '|z' .. body.zone then
        device:online()
        if body.state then
          device:emit_event(capabilities.switch.switch({value = (body.state == 1) and 'on' or 'off'}))
        end
        if body.volume then
          device:emit_event(capabilities.audioVolume.volume({value = tonumber(body.volume)}))
          device:emit_event(capabilities.switchLevel.level({value = tonumber(body.volume)}))
        end
        if body.mute then
          device:emit_event(capabilities.audioMute.mute({value = (body.mute == 1) and 'muted' or 'unmuted'}))
        end
        if body.doNotDisturb then
          device:emit_event(capabilities['platinummassive43262.doNotDisturb'].doNotDisturb({value = (body.doNotDisturb == 1) and 'doNotDisturb' or 'off'}))
        end
        if body.source then
          device:emit_event(capabilities['platinummassive43262.monopriceSource'].source({value = tonumber(body.source)}))
          device:emit_event(capabilities['platinummassive43262.sourceName'].name({value = body.sourceName}))
        end
        if body.treble then
          device:emit_event(capabilities['platinummassive43262.monopriceAudioAdjustments'].treble({value = tonumber(body.treble)}))
        end
        if body.bass then
          device:emit_event(capabilities['platinummassive43262.monopriceAudioAdjustments'].bass({value = tonumber(body.bass)}))
        end
        if body.balance then
          device:emit_event(capabilities['platinummassive43262.monopriceAudioAdjustments'].balance({value = tonumber(body.balance)}))
        end
      end
    end
  end
end

----------------
-- Subscribe command
function command_handler.subscribe(driver, device)
  local serverAddress = driver.server.ip .. ":" .. driver.server.port
  local success = command_handler.send_lan_command('GET','subscribe/' .. serverAddress)

  -- Check if success
  if success then
    log.debug(string.format('Subscribed to %s as %s. Device returned: %s',conf.stnp.ip .. ":" .. conf.stnp.port,serverAddress, success))
  else
    log.error('No response from device')
  end
end

------------------------
-- Send LAN HTTP Request
function command_handler.send_lan_command(method, path)
  log.info (string.format('STNP send command: Method: %s Path: %s',method,path))
  --local dest_url = '/plugins/'.. conf.stnp.plugin ..'/'..path
  local dest_url = '/' .. path
  local res_body = {}

  -- HTTP Request
  local _, code = http.request({
    method=method,
    url=dest_url,
    host=conf.stnp.ip,
    port=conf.stnp.port,
    sink=ltn12.sink.table(res_body),
    headers={
      ['HOST'] = conf.stnp.ip .. ':' .. conf.stnp.port,
      ['Content-Type'] = 'application/json',
      ['stnp-auth'] = conf.stnp.auth
    }})
  log.debug (string.format("Sending http request Method: %s URL: %s HOST: %s Auth: %s", method, dest_url, conf.stnp.ip .. ':' .. conf.stnp.port, conf.stnp.auth))
  log.debug ("Code: " .. code)
  -- Handle response
  if code == 200 then
    return true, res_body
  end
  return false, nil
end

function command_handler.createPrimaryDevice(driver, controller, zone)
  createDevice(driver, controller, zone, 'MPR: Zone 1', 'monoprice-primary-zone')
end

return command_handler
