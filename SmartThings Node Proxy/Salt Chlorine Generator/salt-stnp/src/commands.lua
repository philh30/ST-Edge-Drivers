local log = require('log')
local cosock = require('cosock')
local http = cosock.asyncify('socket.http')
local ltn12 = require('ltn12')
local capabilities = require('st.capabilities')

http.TIMEOUT = 5

local command_handler = {}

local err_codes = {
['err_amps'] = 'Error - Amps',
['err_flow'] = 'Error - Flow',
['err_opec'] = 'Error - OPEC',
['err_ph_high'] = 'Error - pH High',
['err_prime'] = 'Error - Prime',
['err_remote'] = 'Error - Remote',
['err_salt'] = 'Error - Salt',
['err_vfd'] = 'Error - VFD',
['warn_cell'] = 'Warning - Cell',
['warn_i2c'] = 'Warning - i2c',
['warn_orp_over'] = 'Warning - ORP Over',
['warn_ph_cal'] = 'Warning - pH Cal',
['warn_ph_low'] = 'Warning - pH Low',
['warn_ph_over'] = 'Warning - pH Over',
['warn_salt'] = 'Warning - Salt',
['warn_temp'] = 'Warning - Temperature',
}

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

----------------
-- Process notification from STNP
function command_handler.notification_handler(driver, body)
  local device_list = driver:get_devices()
  if TIMERS.OFFLINE then
    driver:cancel_timer(TIMERS.OFFLINE)
    TIMERS.OFFLINE = nil
  end
  TIMERS.OFFLINE = driver:call_with_delay(60, command_handler.set_offline, 'Offline timer')
  for _, device in ipairs(device_list) do
    if device.device_network_id == 'salt|p1' then
      device:online()
      device:emit_event(capabilities.voltageMeasurement.voltage({value = tonumber(body['volts']), unit = 'V'}))
      device:emit_event(capabilities.powerMeter.power({value = tonumber(body['watts']), unit = 'W'}))
      device:emit_event(capabilities["platinummassive43262.currentMeter"].current({value = tonumber(body['amps']), unit = 'A'}))
      device:emit_event(capabilities.temperatureMeasurement.temperature({value = tonumber(body['f']), unit = 'F'}))
      if body['err_flow'] then
        --device:emit_event(capabilities["platinummassive43262.statusMessage"].statusMessage({value = 'No Flow'}))
      else
        device:emit_event(capabilities.pHMeasurement.pH({value = tonumber(body['ph']), unit = 'pH'}))
        device:emit_event(capabilities["platinummassive43262.orpMeasurement"].ORP({value = tonumber(body['orp']), unit = 'mV'}))
        device:emit_event(capabilities["platinummassive43262.phMeasurement"].pH({value = tonumber(body['ph']), unit = 'pH'}))
        device:emit_event(capabilities["platinummassive43262.saltMeasurement"].salt({value = tonumber(body['salt']), unit = 'ppm'}))
        --device:emit_event(capabilities["platinummassive43262.statusMessage"].statusMessage({value = string.format("%s\u{00B0}F  %smV  %spH",body['f'],body['orp'],body['ph'])}))
      end
      
      if (tonumber(body['errorflags']) + tonumber(body['warningflags']))>0 then
        for err_code, err_msg in pairs(err_codes) do
          if body[err_code] then
            device:emit_event(capabilities["platinummassive43262.errorReport"].errorReport({value = err_msg}))
          end
        end
      else
        device:emit_event(capabilities["platinummassive43262.errorReport"].errorReport({value = 'None'}))
      end
    end
  end
end

----------------
-- Subscribe command
function command_handler.subscribe(driver, device)
  local serverAddress = driver.server.ip .. ":" .. driver.server.port
  local success = command_handler.send_lan_command(
    device.device_network_id,
    'GET',
    'subscribe/' .. serverAddress)

  -- Check if success
  if success then
    log.debug(string.format('Subscribed to %s as %s. Device returned: %s',conf.stnp.ip .. ":" .. conf.stnp.port,serverAddress, success))
  else
    log.error('No response from device')
  end
end

------------------------
-- Send LAN HTTP Request
function command_handler.send_lan_command(url, method, path)
  log.info (string.format('Envisalink STNP send command: URL: %s Method: %s Path: %s',url,method,path))
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

function command_handler.createPrimaryDevice(driver, partnum)
  local id = conf.stnp.plugin .. '|p' .. tostring(partnum)
  local devprofile
  
  devprofile = 'salt'
    
  local create_device_msg = {
                              type = "LAN",
                              device_network_id = id,
                              label = 'Pool Pilot',
                              profile = devprofile,
                              manufacturer = 'Autopilot',
                              model = 'Pool Pilot',
                              vendor_provided_label = 'Total Control',
                            }
                        
  log.info(string.format("Creating Partition #%d Panel (%s): '%s'", partnum, id, 'one'))
  log.info(create_device_msg.type, create_device_msg.device_network_id, create_device_msg.label, create_device_msg.profile, create_device_msg.manufacturer, create_device_msg.model, create_device_msg.vendor_provided_label)
  assert (driver:try_create_device(create_device_msg), "failed to create panel device")
end

return command_handler
