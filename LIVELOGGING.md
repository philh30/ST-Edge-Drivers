# Live Logging (CLI)

To view live logging for Edge drivers, you must use the SmartThings Command Line Interface (CLI).

1. Download the most recent release from https://github.com/SmartThingsCommunity/smartthings-cli/releases.
2. Open a Command Prompt window and navigate to the directory where the CLI was downloaded.
3. The first time you use the CLI, you will be prompted to log into your SmartThings account. Run a list of your devices by typing:
```
smartthings devices
```
4. After authenticating the CLI, start live logging by running the command below, entering the IP address of your ST Hub in place of \<HubIP>:
```
smartthings edge:drivers:logcat --hub-address <HubIP>
```
5. Choose the driver to log from the menu and hit Enter, or hit Enter with no selection to log all drivers.