# GE Drivers

[GE Zigbee Switch/Dimmer](#ge-zigbee-switchdimmer-ge-zigbee-switch)

[GE Z-Wave Motion Switch/Dimmer](#ge-z-wave-motion-switchdimmer-ge-zwave-motion-switch)

[GE Z-Wave Switch/Dimmer/Fan/Outlet](#ge-z-wave-switchdimmerfanoutlet-ge-zwave-switch)

## **GE Zigbee Switch/Dimmer (ge-zigbee-switch)**

Provides power/energy reporting for models that support it. The GE/Jasco Zigbee switches and dimmers have little to no configuration options. There's no reason this driver shouldn't work for devices besides the GE/Jasco models (I have two plug-in switches from other manufacturers using it), though other models may have better configuration options that a specifically-tailored driver could take advantage of. The LED indicators don't even seem to be configurable by Zigbee, though I've seen that they can be changed with a sequence of quick button taps (up x3 followed by down x1).

### Switch (Jasco 45856)
Basic functionality with properly scaled power/energy metering.

### Dimmer (Jasco 45857)
The following options are available for configuration in the settings menu:
- **Default Dim Level** - The default dimming level when the device is turned on (a tap on the physical switch or an ON command from the hub). A value of 0 restores the dimmer to the previous level when the switch was last on. Values from 1-100% will scale based on the minimum and maximum dimming settings. *This is the only configurable option that I've found that is stored in the device - all other settings are programmatic and will apply only to commands originating from the hub.*
- **Dimming Transition Time** - The time in tenths of seconds to transition to a new level when a set level command is sent. Values can range from instant (0) to 1 hour 49 minutes 13.4 seconds (65534). A setting of 65535 uses the default transition time configured in the dimmer hardware, which for the 45857 is instant. *This setting applies only to commands originating from the hub.*
- **Transition Time Scaling** - Enabling this setting will use the *Dimming Transition Time* as the time to move from 0 to 100%, and will scale any smaller change to take a proportional amount of time. For example, if the *Dimming Transition Time* is set to 10 minutes and the level is changed from 25 to 75% (a 50% change), the transition will take 5 minutes. This setting does not apply if the *Dimming Transition Time* is set to 65535. *This setting applies only to commands originating from the hub.*
- **Maximum and Minimum Dim Level** - Configurable maximum and minimum dimming levels. The device uses dimming levels of 0 to 255 instead of the 0 to 100% displayed in the app. In order to provide greater granularity in setting these limits to match the performance of your light bulbs, these settings use the 0 to 255 values native to the hardware. *This setting applies only to commands originating from the hub. Note that, if the physical buttons are used to dim below the minimum level, the app will show a dim level of 0 and the switch in the ON state. A minimum dim level that is set greater than the maximum dim level will be ignored, with 0 being used as the minimum instead.*


## **GE Z-Wave Motion Switch/Dimmer (ge-zwave-motion-switch)**

Adds custom capabilities to control configuration parameters on motion switch/dimmer:
- Operating Mode (Occupancy/Vacancy/Manual)
- Light Sensing (On/Off)
- Motion Sensor Sensitivity (High/Medium/Low)
- Light Duration After Motion Stops (5s/1m/5m/15m/30m)
- Default Dim Level (0=Previous/1-100%)

### ***In-Wall Motion Switches***
Fingerprint | Device | Profile
--- | --- | ---
0063/494D/3031 | GE Smart Motion Sensor Switch (24770 / ZW4006) | ge-motionswitch-assoc
0063/494D/3032 | GE Smart Motion Sensor Switch (26931 / ZW4006) | ge-motionswitch-assoc

### ***In-Wall Motion Dimmers***
Fingerprint | Device | Profile
--- | --- | ---
0063/494D/3033 | GE Smart Motion Sensor Switch (26932) | ge-motiondimmer-assoc
0063/494D/3034 | GE Smart Motion Sensor Switch (26933) | ge-motiondimmer-assoc

## **GE Z-Wave Switch/Dimmer/Fan/Outlet (ge-zwave-switch)**

Profiles:

- ge-________-legacy
  - Configuration parameters available in settings
- ge-________-assoc
  - Configuration parameters available in settings
  - Association groups 2 and 3 available in settings
  - Hub added to association group 3 to support double tap (does not apply to motion switch/dimmer)
- ge-________-scene
  - Configuration parameters available in settings
  - Association groups 2 and 3 available in settings
  - Central scene for hold/tap/double tap/triple tap

### ***In-Wall Switches***

Fingerprint | Device | Profile
--- | --- | ---
0063/4952/3032 | GE Smart Switch (12722 / ZW4005) | ge-switch-legacy
0063/4952/3033 | GE Smart Toggle Switch (12727 / ZW4003) | ge-switch-legacy
0063/4952/3034 | GE Smart Toggle Switch (12731) | ge-switch-legacy
0063/4952/3036 | GE Smart Switch (14291 / ZW4005) | ge-switch-assoc
0063/4952/3037 | GE Smart Toggle Switch (14292 / ZW4003) | ge-switch-assoc
0063/4952/3038 | GE Smart Toggle Switch (14293 / ZW4003) | ge-switch-assoc
0063/4952/3130 | GE Smart Switch (14318 / ZW4005) | ge-switch-scene
0063/4952/3135 | GE Smart Switch (14291 / 46201 / ZW4008) | ge-switch-scene
0063/4952/3136 | GE Smart Switch (46562 / ZW4008) | ge-switch-scene
0063/4952/3137 | GE Smart Toggle Switch (14292 / 46202 / ZW4009) | ge-switch-scene
0063/4952/3139 | GE Smart Switch (43072 / ZW4008DV) | ge-switch-scene
0063/4952/3231 | GE Smart Toggle Switch (43074 / ZW4009DV) | ge-switch-scene
0063/4952/3237 | UltraPro Smart Switch (39348 /54890 /54891/ ZW4008) | ge-switch-scene
0063/4952/3238 | UltraPro Smart Toggle Switch (39354 / 54912 / ZW4009) | ge-switch-scene
0063/5257/3533 | GE Smart Switch (45637 / ZW4001) | ge-switch-legacy
0039/4952/3036 | Honeywell Smart Switch (39455 / ZW4005) | ge-switch-assoc
0039/4952/3037 | Honeywell Smart Toggle Switch (39354 / ZW4003) | ge-switch-assoc
0039/4952/3135 | Honeywell Smart Switch (39348 / ZW4008) | ge-switch-scene
0039/4952/3137 | Honeywell Smart Toggle Switch (39354 / ZW4009) | ge-switch-scene

### ***In-Wall Motion Switches***
Fingerprint | Device | Profile
--- | --- | ---
0063/494D/3031 | GE Smart Motion Sensor Switch (24770 / ZW4006) | ge-motionswitch-assoc
0063/494D/3032 | GE Smart Motion Sensor Switch (26931 / ZW4006) | ge-motionswitch-assoc

### ***In-Wall Dimmers***

Fingerprint | Device | Profile
--- | --- | ---
0063/4450/3030 | GE Smart Dimmer (45639 / ZW3101) | ge-dimmer-legacy
0063/4944/3031 | GE Smart Dimmer (12724 / ZW3005) | ge-dimmer-legacy
0063/4944/3032 | GE Smart Dimmer (12725 / ZW3006) | ge-dimmer-legacy
0063/4944/3033 | GE Smart Toggle Dimmer (12729 / ZW3004) | ge-dimmer-legacy
0063/4944/3035 | GE Smart Toggle Dimmer (12733) | ge-dimmer-legacy
0063/4944/3036 | GE Smart Toggle Dimmer (12734) | ge-dimmer-legacy
0063/4944/3037 | GE Smart Toggle Dimmer (12735) | ge-dimmer-legacy
0063/4944/3038 | GE Smart Dimmer (14294 / ZW3005) | ge-dimmer-assoc
0063/4944/3039 | GE Smart Dimmer (14299 / ZW3006) | ge-dimmer-assoc
0063/4944/3130 | GE Smart Toggle Dimmer (14295 / ZW3004) | ge-dimmer-assoc
0063/4944/3132 | GE Smart Toggle Dimmer (14296 / ZW3011) | ge-dimmer-scene
0063/4944/3135 | GE Smart Dimmer (14321 / ZW3005) | ge-dimmer-assoc
0063/4944/3136 | GE Smart Dimmer (14326 / ZW3006) | ge-dimmer-assoc
0063/4944/3233 | GE Smart Touch Dimmer (14289 / ZW3009) | ge-dimmer-assoc
0063/4944/3235 | GE Smart Dimmer (14294 / 46203 / ZW3010) | ge-dimmer-scene
0063/4944/3237 | GE Smart Toggle Dimmer (14295 / 46204 / ZW3011) | ge-dimmer-scene
0063/4944/3333 | GE Smart Dimmer (52252 / 52253 / ZW3012) | ge-dimmer-scene
0063/4944/3334 | GE Smart Dimmer (56590 / 56592 / ZW3012) | ge-dimmer-scene
0063/4944/3339 | UltraPro Smart Dimmer (39351 / 54897 / 54898 / ZW3010) | ge-dimmer-scene
0039/4944/3038 | Honeywell Smart Dimmer (39458 / ZW3005) | ge-dimmer-assoc
0039/4944/3130 | Honeywell Smart Toggle Dimmer (39357 / ZW3004) | ge-dimmer-assoc
0039/4944/3235 | Honeywell Smart Dimmer (39351 / ZW3010) | ge-dimmer-scene
0039/4944/3237 | Honeywell Smart Toggle Dimmer (39357 / ZW3011) | ge-dimmer-scene

### ***In-Wall Motion Dimmers***
Fingerprint | Device | Profile
--- | --- | ---
0063/494D/3033 | GE Smart Motion Sensor Switch (26932) | ge-motiondimmer-assoc
0063/494D/3034 | GE Smart Motion Sensor Switch (26933) | ge-motiondimmer-assoc

### ***In-Wall Fan Controls***

Fingerprint | Device | Profile
--- | --- | ---
0063/4944/3034 | GE Z-Wave In-Wall Smart Fan Control (12730 / ZW4002) | ge-fan-legacy
0063/4944/3131 | GE Z-Wave In-Wall Smart Fan Control (14287 / ZW4002) | ge-fan-assoc
0063/4944/3138 | GE Z-Wave In-Wall Smart Fan Control (14314 / ZW4002) | ge-fan-assoc
0063/4944/3337 | GE Z-Wave In-Wall Smart Fan Control (55258 / ZW4002) | ge-fan-scene
0039/4944/3131 | Honeywell Smart Fan Control (39358 / ZW4002) | ge-fan-assoc

### ***In-Wall Outlets***

Fingerprint | Device | Profile
--- | --- | ---
0063/4952/3031 | GE Smart Outlet (12721 / ZW1001) | ge-outlet-legacy
0063/4952/3035 | GE Smart Outlet (14286 / ZW1001) | ge-outlet-assoc
0063/4952/3133 | GE Smart Outlet (14288 / ZW1002) | ge-outlet-assoc
0063/4952/3134 | GE Smart Outlet (14288 / ZW1002) | ge-outlet-assoc
0063/4952/3233 | GE Smart Outlet (???) | ge-outlet-scene
0063/4952/3234 | GE Smart Outlet (55256 / ZW1002) | ge-outlet-scene
0063/4952/3235 | GE Smart Outlet (55257 / ZW1002) | ge-outlet-scene
0063/5252/3530 | GE Smart Outlet (45636 / ZW1001) | ge-outlet-legacy
0039/4952/3133 | Honeywell Smart Outlet (39456 / ZW1002) | ge-outlet-assoc

### ***Plug-In Switches***

Fingerprint | Device | Profile
--- | --- | ---
0063/4F50/3031 | GE Smart Outdoor Plug In Switch (12720 / ZW4201) | ge-plugin-legacy
0063/4F50/3032 | GE Smart Outdoor Plug In Switch (14284 / ZW4201) | ge-plugin-assoc
0063/4F50/3034 | GE Smart Outdoor Plug In Switch (14298 / ZW4202) | ge-plugin-scene
0063/5052/3031 | GE Smart Plug In Switch (12719 / ZW4101) | ge-plugin-legacy
0063/5052/3033 | GE Smart Plug In Switch (14282 / ZW4106) | ge-plugin-assoc
0063/5052/3038 | GE Smart Plug In Switch (28169 / ZW4103) | ge-plugin-assoc
0063/5052/3130 | GE Smart Plug In Switch (28173 / ZW4104) | ge-plugin-assoc
0063/5052/3132 | GE Smart Plug In Switch (28177 / ZW4105) | ge-plugin-assoc
0063/5250/3030 | GE Fluorescent Light and Appliance Module (12719 / ZW4101) | ge-plugin-legacy
0063/5250/3130 | GE Outdoor Light and Appliance Module (12720 / ZW4201) | ge-plugin-legacy
0039/4F50/3032 | Honeywell Smart Outdoor Plug In Switch (39346 / ZW4201) | ge-plugin-assoc
0039/4F50/3034 | Honeywell Smart Outdoor Plug In Switch (39363 / ZW4203) | ge-plugin-scene
0039/5052/3033 | Honeywell Smart Plug In Switch (39449  / ZW4106) | ge-plugin-assoc
0039/5052/3038 | Honeywell Smart Plug In Switch (39444  / ZW4103) | ge-plugin-assoc

### ***Plug-In Dimmers***

Fingerprint | Device | Profile
--- | --- | ---
0063/5044/3031 | GE Smart Plug In Dimmer (12718 / ZW3101) | ge-plugdim-legacy
0063/5044/3033 | GE Smart Plug In Dimmer (14280 / ZW3107) | ge-plugdim-assoc
0063/5044/3038 | GE Smart Plug In Dimmer (28167 / ZW3104) | ge-plugdim-assoc
0063/5044/3130 | GE Smart Plug In Dimmer (28171 / ZW3105) | ge-plugdim-assoc
0063/5044/3132 | GE Smart Plug In Dimmer (28175 / ZW3106) | ge-plugdim-assoc
0039/5044/3033 | Honeywell Smart Plug In Dimmer (39446 / ZW3107) | ge-plugdim-assoc
0039/5044/3038 | Honeywell Smart Plug In Dimmer (39443 / ZW3104) | ge-plugdim-assoc

### ***Direct-Wire Outdoor Switches***
Fingerprint | Device | Profile
--- | --- | ---
0063/4F44/3032 | GE Direct-Wire Outdoor Switch (14285 / ZW4007) | ge-heavyswitch-scene

## Live Logging
[Instructions](../LIVELOGGING.md)
