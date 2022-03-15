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