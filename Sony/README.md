# SmartThings Edge Driver for Sony Bravia TVs

[Driver Folder](sony-bravia-tv)

## Overview

- UPnP discovery
- [Simple IP Control](https://pro-bravia.sony.net/develop/integrate/ssip/overview/index.html) for most commands
- [REST API](https://pro-bravia.sony.net/develop/integrate/rest-api/spec/index.html) to query/launch apps

## Installation

On your TV:
- Turn on `Network -> Remote Start`
- Turn on `Network -> Home Network -> Simple IP Control`
- Set `Network -> Home Network -> Authentication` to `Normal and Pre-Shared Key`
- Set a `Pre-Shared Key`

In SmartThings:
- Enroll in the channel and install the driver
- With the TV on, select to scan nearby for new devices in the SmartThings app
- In the settings menu of the new device, enter the pre-shared key and configure the number of inputs

## Settings

- **Passkey** - The Pre-Shared Key set up on your TV. This setting is required to be able to launch apps.
- **HDMI Inputs** - The number of HDMI inputs to include in the source list.
- **Component Inputs** - The number of Component inputs to include in the source list.
- **Composite Inputs** - The number of Composite inputs to include in the source list.
- **Screen Mirroring Inputs** - The number of Screen Mirroring inputs to include in the source list.
- **PC Inputs** - The number of PC inputs to include in the source list.
- **SCART Inputs** - The number of SCART inputs to include in the source list.
- **Re-query App List on Refresh** - The app list will be re-queried on hub reboot and when settings are changed. Enabling this setting will also re-query the app list when the device is refreshed. This generally shouldn't be necessary.
- **Remove System Apps from List** - Remove the following apps from the app list:
  - Bonus Offer
  - BRAVIA notifications
  - Help
  - Play Store
  - Sony Select
  - Timers &amp; Clock
  - TV Control with Smart Speakers
- **Remove Duplicate Apps from List** - Eliminate duplicate app names from the app list. The first uri discovered will be mapped to the app name.
- **IRCC Command Delay** - The delay (in milliseconds) between IRCC commands sent using the `Send command` automation.

## Sending IRCC Commands
Automations can use `Send command` to send a series of remote control commands. The commands should be a comma-delimited series of integers. The IRCC codes below are from the [Sony documentation](https://pro-bravia.sony.net/develop/integrate/ssip/command-definitions/index.html). There are other codes beyond these, though all codes may not work with all models.

Command | Code
--|--
Display | 5
Home | 6
Options | 7
Return | 8
Up | 9
Down | 10
Right | 11
Left | 12
Confirm | 13
Red | 14
Green | 15
Yellow | 16
Blue | 17
Num1 | 18
Num2 | 19
Num3 | 20
Num4 | 21
Num5 | 22
Num6 | 23
Num7 | 24
Num8 | 25
Num9 | 26
Num0 | 27
Volume Up | 30
Volume Down | 31
Mute | 32
Channel Up | 33
Channel Down | 34
Subtitle | 35
DOT | 38
Picture Off | 50
Wide | 61
Jump | 62
Sync Menu | 76
Forward | 77
Play | 78
Rewind | 79
Prev | 80
Stop | 81
Next | 82
Pause | 84
Flash Plus | 86
Flash Minus | 87
TV Power | 98
Audio | 99
Input | 101
Sleep | 104
Sleep Timer | 105
Video 2 | 108
Picture Mode | 110
Demo Surround | 121
HDMI 1 | 124
HDMI 2 | 125
HDMI 3 | 126
HDMI 4 | 127
Action Menu | 129
Help | 130

## Live Logging
[Instructions](../../LIVELOGGING.md)