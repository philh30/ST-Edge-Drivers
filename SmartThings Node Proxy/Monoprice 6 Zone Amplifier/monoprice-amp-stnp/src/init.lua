local Driver = require('st.driver')
local caps = require('st.capabilities')
local log = require('log')

---------------------------------------
-- local imports
local lifecycles = require('lifecycles')
local commands = require('commands')

---------------------------------------
-- variables
initialized = false

conf = {
  stnp  = {
    plugin  = 'mpr-sg6z',
    ip      = '192.168.1.nnn',
    port    = 8080,
    auth    = 'password'
  },
}

TIMERS = {}

---------------------------------------
-- driver functions
local function discovery_handler(driver, _, should_continue)
  if not initialized then
    log.info("Creating primary device")
    commands.createPrimaryDevice(driver, 1, 1)
  else
    log.info ('Primary device already created')
  end
end

---------------------------------------
-- Driver definition
local driver = Driver('Monoprice MPR-SG6Z', {
      discovery = discovery_handler,
      lifecycle_handlers = lifecycles,
      capability_handlers = {
        [caps.refresh.ID] = {
          [caps.refresh.commands.refresh.NAME] = lifecycles.do_refresh
        },
        [caps.switch.ID] = {
          [caps.switch.commands.on.NAME] = commands.on,
          [caps.switch.commands.off.NAME] = commands.off,
        },
        [caps.switchLevel.ID] = {
          [caps.switchLevel.commands.setLevel.NAME] = commands.setLevel,
        },
        [caps.audioMute.ID] = {
          [caps.audioMute.commands.mute.NAME] = commands.mute,
          [caps.audioMute.commands.unmute.NAME] = commands.unmute,
        },
        [caps.audioVolume.ID] = {
          [caps.audioVolume.commands.setVolume.NAME] = commands.volume,
        },
        [caps['platinummassive43262.monopriceSource'].ID] = {
          [caps['platinummassive43262.monopriceSource'].commands.setSource.NAME] = commands.setSource,
        },
        [caps['platinummassive43262.doNotDisturb'].ID] = {
          [caps['platinummassive43262.doNotDisturb'].commands.off.NAME] = commands.dnd_off,
          [caps['platinummassive43262.doNotDisturb'].commands.doNotDisturb.NAME] = commands.dnd_on,
        },
        [caps['platinummassive43262.monopriceAudioAdjustments'].ID] = {
          [caps['platinummassive43262.monopriceAudioAdjustments'].commands.setTreble.NAME] = commands.setTreble,
          [caps['platinummassive43262.monopriceAudioAdjustments'].commands.setBass.NAME] = commands.setBass,
          [caps['platinummassive43262.monopriceAudioAdjustments'].commands.setBalance.NAME] = commands.setBalance,
        },
        [caps['platinummassive43262.discover'].ID] = {
          [caps['platinummassive43262.discover'].commands.discover.NAME] = commands.discover,
        },
      },
    }
  )

--------------------
-- Initialize Driver
driver:run()