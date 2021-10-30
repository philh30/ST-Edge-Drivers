# Installation of ST Edge Driver for Honeywell/Ademco Vista Panels with Envisalink

***The Envisalink interface allows only ONE connection at a time.*** If you currently have another integration connecting to the Envisalink TPI, such as the redloro STNP server, you must disable it or this integration will not be able to connect. This could be as simple as unplugging the Raspberry Pi that STNP is installed on, though you will eventually want to ensure that STNP will not restart the next time you boot up the Pi. Whichever integration connects to the Envisalink will block all others.

If you have previously integrated your Vista panel with ST, you will need to create new partition and zone devices through this integration and delete the old ones. I would suggest that you:

1. Set up this integration
2. Update any automations to use the new partition/zone devices
3. Delete the old partition/zone devices

## Installation

1. Use the following link to enroll in the channel and install the driver on your hub: https://api.smartthings.com/invitation-web/accept?id=a1a72e01-4048-41a2-bca1-275813c40cd1
2. Navigate to *Add device → Scan nearby* in the SmartThings app.
3. Wait for the app to add the *HW Primary Partition 1* device.
4. Exit discovery and find the newly added Partition 1 device. Update the partition's device settings. It's best to change settings slowly to give the system time to process between each change.
   - **Envisalink LAN Address** - Enter the IP address and port of the Envisalink device in the form of *192.168.1.100:4025*
   - **Envisalink User Password** - Enter the password used to log  into the Envisalink. The default user name and password are both *user*
   - **Alarm Code** - A valid alarm code is required to send any commands to the alarm panel.
5. After these settings have been entered, the driver will attempt to connect to the Envisalink. Wait at least 30 seconds and then verify the connection is working by checking that faulted zones display in the ST app and that you can arm/disarm the partition through the ST app. If you have difficulty at this step, stop here and move to the troubleshooting section below.
6. Continue to update the remaining device settings for Partition 1, which will include the creation of other ST devices for partitions, zones and virtual switches.
   - **STHM -> Partition Integration** - If set to true, this partition will disarm/armAway/armStay when SmartThings Home Monitor is set to those modes. This linkage is one way only - if you would prefer that STHM follow the behavior of this partition then you will need to set up routines in the ST app to do so.
   - **Zone Close Delay** - A number between zero and ten. Higher numbers will cause the driver to wait longer before declaring a faulted zone to be clear, and will have fewer false clears. Lower numbers will cause zones to be cleared faster, but will have more false clears. If you have many zones and often have multiple zones tripped, choose a higher number.
   - **Add Partition 2** - Setting to *true* will prompt the driver to create a *HW Partition 2* device. Once the device is created, this setting can be set to *false* with no ill effects (and some savings in processing time).
   - **Add Virtual Switches** - Setting to *true* will prompt the driver to create virtual switches for any enabled alarm modes. At a minimum, this will establish *disarm*, *armAway* and *armStay* switches. Switches will also be added for any modes turned on using the three settings immediately following this one. Once the switch devices are created, this setting can be set to *false* with no ill effects (and some savings in processing time).
   - **Display 'Arm Instant' mode'** - Adds armInstant (armStay with no entry delay) to the list of Alarm Mode options.
   - **Display 'Arm Max' mode'** - Adds armMax (armAway with no entry delay) to the list of Alarm Mode options.
   - **Display 'Arm Night' mode'** - Adds armNight (armStay with honestly I don't know what this does) to the list of Alarm Mode options.
   - **Add Zones** - Setting to *true* will prompt the driver to create devices for each of the zone numbers listed in the five zone settings below. Once the zone devices are created, this setting can be set to *false* with no ill effects (and some savings in processing time).
   - **Highest Wired Zone** - Zones established with zone numbers equal to or below this number will be set up as wired zones (no battery capability) while those greater than this number will be wireless zones (include battery capability). The default is 8, unless your alarm panel has a zone expander installed. Zones can also be switched between wired and wireless after being installed through the settings on each device.
   - **Contact Sensor Zones** - Enter a comma delimited list of contact sensor zones (or one zone number at a time if you prefer to take things slowly) to be created. Devices will be created for these zones if/when the *Add Zones* flag is set to *true*. For example: *5,12,20,43* or *16*. Zone numbers can be deleted from this list after the device is created with no ill effects (and some savings in processing time).
   - **Motion Sensor Zones** - Enter a comma delimited list of motion sensor zones (or one zone number at a time if you prefer to take things slowly) to be created. Devices will be created for these zones if/when the *Add Zones* flag is set to *true*. For example: *5,12,20,43* or *16*. Zone numbers can be deleted from this list after the device is created with no ill effects (and some savings in processing time).
   - **Glass Break Sensor Zones** - Enter a comma delimited list of glass break sensor zones (or one zone number at a time if you prefer to take things slowly) to be created. Devices will be created for these zones if/when the *Add Zones* flag is set to *true*. For example: *5,12,20,43* or *16*. Zone numbers can be deleted from this list after the device is created with no ill effects (and some savings in processing time).
   - **Leak Sensor Zones** - Enter a comma delimited list of leak sensor zones (or one zone number at a time if you prefer to take things slowly) to be created. Devices will be created for these zones if/when the *Add Zones* flag is set to *true*. For example: *5,12,20,43* or *16*. Zone numbers can be deleted from this list after the device is created with no ill effects (and some savings in processing time).
   - **Smoke Sensor Zones** - Enter a comma delimited list of smoke sensor zones (or one zone number at a time if you prefer to take things slowly) to be created. Devices will be created for these zones if/when the *Add Zones* flag is set to *true*. For example: *5,12,20,43* or *16*. Zone numbers can be deleted from this list after the device is created with no ill effects (and some savings in processing time).
   - **Add Triggers** - Setting to *true* will prompt the driver to create devices for *Trigger 1* and *Trigger 2*. Once the devices are created, this setting can be set to *false* with no ill effects (and some savings in processing time).
7. The *Partition 2* device, if added, has a subset of the above settings.
8. Zone devices offer the following settings, which will typically only need to be altered if a zone needs to be assigned to a different partition:
   - **Partition** - Choose the partition that this zone is assigned. This must match the partition assigned in the Vista panel programming or the zone will not clear properly.
   - **Change Sensor Wired/Wireless** - Adds or removes the *Battery* capability from the device.
   - **Change Zone Type** - Adds and removes capabilities to change the zone to a different type, e.g. from a *Contact Sensor* to a *Motion Sensor*. This can also be done by deleting the existing device and creating a new device through the *Partition 1* settings screen.

## Troubleshooting

Some options for troubleshooting if you cannot connect include:

- Ensure that you do not have another device, such as a STNP server, connected to the Envisalink.
- Confirm that the Partition 1 settings include the correct IP:Port for your Envisalink.
- Open live logging (instructions below) and look for errors in the logs.
- Reboot your ST Hub (Edge drivers run on the hub, so this will restart the driver).
- Delete all devices created by this driver and start over with live logging running.

### Live Logging (CLI)

To view live logging for Edge drivers, you must use the SmartThings Command Line Interface (CLI).

1. Download the most recent release from https://github.com/SmartThingsCommunity/smartthings-cli/releases.
2. Open a Command Prompt window and navigate to the directory where the CLI was downloaded.
3. The first time you use the CLI, you will be prompted to log into your SmartThings account. Run a list of your devices by typing:
```
smartthings devices
```
4. After authenticating the CLI, find the Driver ID for this driver by running:
```
smartthings edge:drivers
```
5. Now start live logging by running the command below, entering the Driver ID found above and the IP address of your ST Hub in place of \<DriverID> and \<HubIP>:
```
smartthings edge:drivers:logcat <DriverID> --hub-address <HubIP>
```
