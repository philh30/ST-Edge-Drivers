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

## Live Logging
[Instructions](../../LIVELOGGING.md)