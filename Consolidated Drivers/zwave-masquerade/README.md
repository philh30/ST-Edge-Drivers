# Z-Wave Masquerade

Allows simple z-wave devices, such as switches and binary sensors, to act as a different type of device. As an example, an z-wave contact sensor with external contacts that is set up to monitor a smoke detector relay could be reflected in the SmartThings app as a smoke detector.

More complex z-wave devices that report multiple different attributes may give unexpected results with this driver.

## Settings
- **Choose Profile** - Select the profile to be used (e.g. Contact Sensor, Smoke Detector). After changing this setting, you may need to do some combination of exiting back to the dashboard, closing the app, force closing the app, or clearing app cache in order for the profile change to be displayed in the app. The Battery capability will automatically be added if the device supports the Battery z-wave command class.
- **Invert Status** - Toggle to swap how the device's state is reflected in the displayed capability. For example, a contact sensor masquerading as a smoke detector will default to Closed = Clear, but toggling this option will result in Closed = Detected.
- **State 1/2** *(not available on all profiles)* - For profiles that use a non-binary capability, these settings allow you to choose the two values that will be displayed in the app. For example, the Water Level profile uses a capability that allows Low, Normal and High, and this setting allows you to choose two of these options to be mapped to the Open/Closed states of a contact sensor.