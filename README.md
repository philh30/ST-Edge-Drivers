# SmartThings Edge Drivers
As of February 2022, the entire Edge platform is in Beta.

Channel invitations are available in the linked SmartThings Community topics. Drivers that lack a SmartThings Community topic have not been shared to a publicly-available channel.

## FortrezZ

### Leak Sensor (WWA-01AA)

Driver provides configurable wake-up interval, with settings to determine whether temperature and battery are requested on each wake up.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-fortrezz-wwa-01aa-temperature-and-leak-sensor/233027)
- [Driver folder](/FortrezZ/WWA-01AA%20Leak%20Sensor/zwave-fortrezz-leak)

## GE/Jasco
- [README file for all GE-Jasco drivers](/GE-Jasco/README.md)

### Z-Wave Switches/Dimmers/Fans/Outlets
Configuration options, multi-tap events, and association groups for Jasco-manufactured (GE/Jasco/Honeywell/UltraPro) devices.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-driver-for-ge-jasco-honeywell-z-wave-switches-dimmers-fans-outlets-and-plug-ins/236733)
- [Driver folder](/GE-Jasco/ge-zwave-switch)

### Z-Wave Motion Switches/Dimmmers
Allows various configuration options (e.g. motion sensitivity, operation mode) to be set through automations.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-driver-for-ge-jasco-z-wave-motion-switches-and-dimmers-24770-26931-26932-26933/237043)
- [Driver folder](/GE-Jasco/ge-zwave-motion-switch)

### Zigbee Switches/Dimmers
Power and energy reporting, with various configuration options for the dimmer.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-ge-jasco-zigbee-switches-and-dimmers/238000)
- [Driver folder](/GE-Jasco/ge-zigbee-switch)

## Honeywell

### Envisalink/Vista Alarm Panel Direct Connection
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-honeywell-ademco-vista-panel-envisalink/233766)
- [Installation instructions](/Honeywell/Envisalink-Vista/INSTALLATION.md)
- [Driver folder](/Honeywell/Envisalink-Vista/envisalink-honeywell-release)

## Intermatic

### PE653 Pool Control System
Provides full control and configuration of the Intermatic PE653 Pool Control System.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-driver-for-intermatic-pool-control-system-pe653-pe953/239483)
- [Installation instructions](/Intermatic/PE653%20Pool%20Control%20System/README.md)
- [Driver folder](/Intermatic/PE653%20Pool%20Control%20System/intermatic-pe653)

### PE953 Remote Control
Allows the five PE953 scenes to be used as button presses that can trigger automations. Firmware version of the remote will also be displayed.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-driver-for-intermatic-pool-control-system-pe653-pe953/239483)
- [Installation instructions](/Intermatic/PE953%20Remote%20Control/README.md)
- [Driver folder](/Intermatic/PE953%20Remote%20Control/intermatic-pe953)

## Onkyo

### Onkyo/Pioneer AV Receivers
Connection to Onkyo and Pioneer AV receivers that support eISCP commands.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-onkyo-pioneer-av-receivers/239992?u=philh30)
- [Installation instructions](/Onkyo/README.md)
- [Driver folder](/Onkyo/onkyo-receiver/)

## SmartThings Node Proxy
Integrations using the SmartThings Node Proxy server developed by redloro.

### STNP/Honeywell Vista Alarm Panel

*In development*

### STNP/Salt Chlorine Generator
Driver to connect to a SmartThings Node Proxy server that monitors a chlorine generator.
- [Driver folder](/SmartThings%20Node%20Proxy/Salt%20Chlorine%20Generator/salt-stnp)

## Sony

### Sonyy Bravia TVs
Connection to Sony Bravia TVs using Simple IP Control.
- [SmartThings Community topic](https://community.smartthings.com/t/st-edge-sony-bravia-tvs/240685)
- [Installation instructions](/Sony/README.md)
- [Driver folder](/Sony/sony-bravia-tv/)

## Trane

### Thermostat
Adds Run Program/Hold option. The parameter used to change this command appears to be different depending on firmware version.
- [Driver folder](/Trane/Z-wave%20Thermostat/zwave-thermostat)

## Zooz
Zooz drivers developed for my own use and shared in case anyone finds them useful when developing their own. *I recommend that end-users install and use the official drivers that have been developed by Zooz, as I will not provide support.*

### ZEN32 Scene Controller
Supports all button scenes except *released* (ST limitation), supports setting all configuration options and association groups, and exposes indicator light configuration to automations.
- [Driver folder](/Zooz/zen32)

### Zooz Sensors
Supports the ZSE11 Q Sensor and ZSE40 4-in-1 Sensor.
- [Driver folder](/Zooz/zooz-sensor)