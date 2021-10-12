local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 1 })
local SensorMultilevel = (require "st.zwave.CommandClass.SensorMultilevel")({ version = 1 })
local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local cc = require "st.zwave.CommandClass"
local log = require "log"
local zw = require "st.zwave"

local ZWAVE_TEMP_LEAK_SENSOR_FINGERPRINTS = {
  {mfr = 0x0084, prod = 0x0053, model = 0x0216} -- FortrezZ Temperature and Leak Sensor
}

local function can_handle_zwave_temp_leak_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZWAVE_TEMP_LEAK_SENSOR_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

local function update_preferences(self, device, args)
  if args.old_st_store.preferences.wakeUpInterval ~= device.preferences.wakeUpInterval then
    log.debug ('Updating Wake Up Interval')
    device:send(WakeUp:IntervalSet({node_id = self.environment_info.hub_zwave_id, seconds = 60 * device.preferences.wakeUpInterval}))
    device:send(WakeUp:IntervalGet({}))
  end
end

local function dev_init(self, device)
  device:set_update_preferences_fn(update_preferences)
end

local function wakeup_notification(driver, device, cmd)
  log.debug ('Woke up')
  -- Device only sends temperature reports if queried on wake up
  if device.preferences.requestTemperature == "on" then
    device:send(SensorMultilevel:Get({}))
  end
  if device.preferences.requestBattery == "on" then
    device:send(Battery:Get({}))
  end
  --Send WakeUp.WAKE_UP_NO_MORE_INFORMATION. Not sure if this part is working since there's no TRANSMIT_COMPLETE_OK
  local cmd = zw.Command(0x84, 0x08, "")
  cmd.err = nil
  cmd.args={}
  device:send(cmd)
end

local function basic_set(driver,device,cmd)
  device:emit_event(capabilities.waterSensor.water({ value = cmd.args.value == 0 and "dry" or "wet" }))
end

local function sensor_binary_report(driver,device,cmd)
  -- Freeze alarm triggers at 39F (not configurable)
  device:emit_event(capabilities.temperatureAlarm.temperatureAlarm({ value = cmd.args.value == 0 and "cleared" or "freeze" }))
end

local function temperature_report(self, device, cmd)
  if (cmd.args.sensor_type == SensorMultilevel.sensor_type.TEMPERATURE) then
    local scale = 'C'
    if (cmd.args.scale == SensorMultilevel.scale.temperature.FAHRENHEIT) then scale = 'F' end
    local evt = capabilities.temperatureMeasurement.temperature({value = cmd.args.sensor_value, unit = scale})
    evt.state_change = true
    device:emit_event_for_endpoint(cmd.src_channel, evt)
  end
end

local function dev_added(self, device)
  log.debug('Device added')
  device:emit_event(capabilities.temperatureAlarm.temperatureAlarm({ value = "cleared" }))
  device:emit_event(capabilities.waterSensor.water({ value = "dry" }))
end

local driver_template = {
  zwave_handlers = {
    [cc.WAKE_UP] = {
      [WakeUp.NOTIFICATION] = wakeup_notification,
    },
    [cc.BASIC] = {
      [Basic.SET] = basic_set,
    },
    [cc.SENSOR_BINARY] = {
      [SensorBinary.REPORT] = sensor_binary_report,
    },
    [cc.SENSOR_MULTILEVEL] = {
      [SensorMultilevel.REPORT] = temperature_report,
    },
  },
  supported_capabilities = {
    capabilities.waterSensor,
    capabilities.temperatureMeasurement,
    capabilities.temperatureAlarm,
    capabilities.battery,
  },
  lifecycle_handlers = {
    init = dev_init,
    added = dev_added
  },
  NAME = "zwave fortrezz temp leak sensor",
  can_handle = can_handle_zwave_temp_leak_sensor,
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local leakSensor = ZwaveDriver("zwave-fortezz-leak", driver_template)
leakSensor:run()