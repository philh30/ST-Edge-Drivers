# SmartThings Edge Driver for Intermatic PE653 Pool Control

[Product Website](https://www.intermatic.com/Product/PE653)

[Driver Folder](intermatic-pe653)

## Overview

This driver includes both a configuration view and operation view, which can be toggled between in settings.

  - The configuration view allows full setup without the PE953 remote. All configuration options except for the RS485 screen are available and will show current states. Changes made with the PE953 will also be reflected here after a refresh. Note that temperature offsets are located in settings (both in configuration and operation mode), but the current values will show on the configuration view.

  - The operation view can (to an extent) be customized to match the device configuration by choosing an appropriate profile. Support is included for 1/2/variable speed pumps, both thermostats, all circuits, and all 3 temperature probes. Schedules can be set directly from this view, and all current schedules are displayed.

*This driver has been tested on firmware version 3.4.*

## Installation

1. Install the driver using the channel invitation.
2. Follow the [PE653 pairing instructions](../PAIRING.md)
3. Navigate to the device in the SmartThings app.
4. The device will be added to SmartThings in configuration mode. If any of the configuration options fail to populate, swipe down on the screen to refresh.
5. Update configuration options one at a time, waiting for the new value to show on the screen before moving to another option. Some configuration options are interrelated, and moving too quickly can cause entries to be overwritten.
6. In the settings menu, choose an appropriate profile that matches how your device is set up (see Profiles section below).
7. In the settings menu, change the mode to 'Operation Mode' when you are done changing configuration options. After changing modes, you will need to exit to the dashboard (and may need to close/reopen the app) for the display to update. A different profile can be selected by returning to the configuration view.

## Profiles
Profile names follow the format `PS-SSSSS-V-H-WAS` to represent the capabilities that should be supported.

- `PS` - (P) Pool mode / (S) Spa mode
- `SSSSS` - Circuits 1-5
- `V` - Variable Speed Pump
- `H` - Heater
- `WAS` - (W)ater, (A)ir and (S)olar temperature sensors

Capabilities that are omitted from the profile are replaced with an underscore (_). For example, a pool-only configuration with a single-speed pump, a heater (connected to circuit 5), and all three temperature probes would use profile `P_-SSSS_-_-H-WAS`.

## Live Logging
[Instructions](../../LIVELOGGING.md)