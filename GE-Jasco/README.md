# GE Drivers

## **ge-zwave-switch**

Profiles:

- ge-________-legacy
  - Configuration parameters available in settings
- ge-________-assoc
  - Configuration parameters available in settings
  - Association groups 2 and 3 available in settings
  - Hub added to association group 3 to support double tap
- ge-________-scene
  - Configuration parameters available in settings
  - Association groups 2 and 3 available in settings
  - Central scene for hold/tap/double tap/triple tap

### ***In-Wall Switches***

Fingerprint | Device | Profile | Tested
--- | --- | --- | ---
0063/4952/3032 | GE Smart Switch (12722 / ZW4005) | ge-switch-legacy | Yes
0063/4952/3033 | GE Smart Toggle Switch (12727 / ZW4003) | ge-switch-legacy | No
0063/4952/3034 | GE Smart Toggle Switch (12731) | ge-switch-legacy | No
0063/4952/3036 | GE Smart Switch (14291 / ZW4005) | ge-switch-assoc | Yes
0063/4952/3037 | GE Smart Toggle Switch (14292 / ZW4003) | ge-switch-assoc | Yes
0063/4952/3038 | GE Smart Toggle Switch (14293 / ZW4003) | ge-switch-assoc | No
0063/4952/3135 | GE Smart Switch (14291 / 46201 / ZW4008) | ge-switch-scene | Yes
0063/4952/3137 | GE Smart Toggle Switch (14292 / 46202 / ZW4009) | ge-switch-scene | No
0063/4952/3139 | GE Smart Switch (43072 / ZW4008DV) | ge-switch-scene | No
0063/4952/3231 | GE Smart Toggle Switch (43074 / ZW4009DV) | ge-switch-scene | No
0063/5257/3533 | GE Smart Switch (45637 / ZW4001) | ge-switch-legacy | Yes
0039/4952/3036 | Honeywell Smart Switch (39455 / ZW4005) | ge-switch-assoc | Yes
0039/4952/3037 | Honeywell Smart Toggle Switch (39354 / ZW4003) | ge-switch-assoc | No
0039/4952/3135 | Honeywell Smart Switch (39348 / ZW4008) | ge-switch-scene | No
0039/4952/3137 | Honeywell Smart Toggle Switch (39354 / ZW4009) | ge-switch-scene | No

### ***In-Wall Dimmers***

Fingerprint | Device | Profile | Tested
--- | --- | --- | ---
0063/4450/3030 | GE Smart Dimmer (45639 / ZW3101) | ge-dimmer-legacy | No
0063/4944/3031 | GE Smart Dimmer (12724 / ZW3005) | ge-dimmer-legacy | No
0063/4944/3032 | GE Smart Dimmer (12725 / ZW3006) | ge-dimmer-legacy | No
0063/4944/3033 | GE Smart Toggle Dimmer (12729 / ZW3004) | ge-dimmer-legacy | No
0063/4944/3035 | GE Smart Toggle Dimmer (12733) | ge-dimmer-legacy | No
0063/4944/3036 | GE Smart Toggle Dimmer (12734) | ge-dimmer-legacy | No
0063/4944/3037 | GE Smart Toggle Dimmer (12735) | ge-dimmer-legacy | No
0063/4944/3038 | GE Smart Dimmer (14294 / ZW3005) | ge-dimmer-assoc | Yes
0063/4944/3039 | GE Smart Dimmer (14299 / ZW3006) | ge-dimmer-assoc | No
0063/4944/3130 | GE Smart Toggle Dimmer (14295 / ZW3004) | ge-dimmer-assoc | No
0063/4944/3233 | GE Smart Touch Dimmer (14289 / ZW3009) | ge-dimmer-assoc | No
0063/4944/3235 | GE Smart Dimmer (14294 / 46203 / ZW3010) | ge-dimmer-scene | Yes
0063/4944/3237 | GE Smart Toggle Dimmer (14295 / 46204 / ZW3011) | ge-dimmer-scene | No
0063/4944/3333 | GE Smart Dimmer (52252 / 52253 / ZW3012) | ge-dimmer-scene | No
0039/4944/3038 | Honeywell Smart Dimmer (39458 / ZW3005) | ge-dimmer-assoc | No
0039/4944/3130 | Honeywell Smart Toggle Dimmer (39357 / ZW3004) | ge-dimmer-assoc | No
0039/4944/3235 | Honeywell Smart Dimmer (39351 / ZW3010) | ge-dimmer-scene | No
0039/4944/3237 | Honeywell Smart Toggle Dimmer (39357 / ZW3011) | ge-dimmer-scene | No

### ***In-Wall Fan Controls***

Fingerprint | Device | Profile | Tested
--- | --- | --- | ---
0063/4944/3034 | GE Z-Wave In-Wall Smart Fan Control (12730 / ZW4002) | ge-fan-legacy | No
0063/4944/3131 | GE Z-Wave In-Wall Smart Fan Control (14287 / ZW4002) | ge-fan-assoc | Yes
0039/4944/3131 | Honeywell Smart Fan Control (39358 / ZW4002) | ge-fan-assoc | No

### ***In-Wall Outlets***

Fingerprint | Device | Profile | Tested
--- | --- | --- | ---
0063/4952/3031 | GE Smart Outlet (12721 / ZW1001) | ge-outlet-legacy | Yes
0063/4952/3035 | GE Smart Outlet (14286 / ZW1001) | ge-outlet-assoc | No
0063/4952/3133 | GE Smart Outlet (14288 / ZW1002) | ge-outlet-assoc | Yes
0063/4952/3134 | GE Smart Outlet (14288 / ZW1002) | ge-outlet-assoc | No
0063/5252/3530 | GE Smart Outlet (45636 / ZW1001) | ge-outlet-legacy | No
0039/4952/3133 | Honeywell Smart Outlet (39456 / ZW1002) | ge-outlet-assoc | Yes

### ***Plug-In Switches***

Fingerprint | Device | Profile | Tested
--- | --- | --- | ---
0063/4F50/3031 | GE Smart Outdoor Plug In Switch (12720) | ge-plugin-legacy | Yes
0063/4F50/3032 | GE Smart Outdoor Plug In Switch (14284 / ZW4201) | ge-plugin-assoc | No
0063/4F50/3034 | GE Smart Outdoor Plug In Switch (14298 / ZW4202) | ge-plugin-scene | No
0063/5052/3031 | GE Smart Plug In Switch (12719 / ZW4101) | ge-plugin-legacy | Yes
0063/5052/3033 | GE Smart Plug In Switch (14282 / ZW4106) | ge-plugin-assoc | No
0063/5052/3038 | GE Smart Plug In Switch (28169 / ZW4103) | ge-plugin-assoc | No
0063/5052/3130 | GE Smart Plug In Switch (28173 / ZW4104) | ge-plugin-assoc | No
0063/5052/3132 | GE Smart Plug In Switch (28177 / ZW4105) | ge-plugin-assoc | No
0039/4F50/3032 | Honeywell Smart Outdoor Plug In Switch (39346 / ZW4201) | ge-plugin-assoc | No
0039/4F50/3034 | Honeywell Smart Outdoor Plug In Switch (39363 / ZW4203) | ge-plugin-scene | No
0039/5052/3033 | Honeywell Smart Plug In Switch (39449  / ZW4106) | ge-plugin-assoc | No
0039/5052/3038 | Honeywell Smart Plug In Switch (39444  / ZW4103) | ge-plugin-assoc | No

### ***Plug-In Dimmers***

Fingerprint | Device | Profile | Tested
--- | --- | --- | ---
0063/5044/3031 | GE Smart Plug In Dimmer (12718 / ZW3101) | ge-plugdim-legacy | No
0063/5044/3033 | GE Smart Plug In Dimmer (14280 / ZW3107) | ge-plugdim-assoc | No
0063/5044/3038 | GE Smart Plug In Dimmer (28167 / ZW3104) | ge-plugdim-assoc | No
0063/5044/3130 | GE Smart Plug In Dimmer (28171 / ZW3105) | ge-plugdim-assoc | No
0063/5044/3132 | GE Smart Plug In Dimmer (28175 / ZW3106) | ge-plugdim-assoc | No
0039/5044/3033 | Honeywell Smart Plug In Dimmer (39446 / ZW3107) | ge-plugdim-assoc | No
0039/5044/3038 | Honeywell Smart Plug In Dimmer (39443 / ZW3104) | ge-plugdim-assoc | No