-- Author: philh30
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local evlDefs = {}

evlDefs.ArmCommands = {
	disarm			= '1',
	armAway			= '2',
	armStay			= '3',
	armNight 		= '33',
	armMax			= '4',
	armInstant		= '7',
	chime			= '9',
	bypass			= '6',
	triggerOneOn	= '#717',
	triggerOneOff	= '#817',
	triggerTwoOn	= '#718',
	triggerTwoOff	= '#818',
}

evlDefs.Commands = {
    KeepAlive 				= '00',
    ChangeDefaultPartition 	= '01',
    DumpZoneTimers 			= '02',
    PartitionKeypress 		= '03'
}

evlDefs.ResponseTypes = {
	['Login:'] = {
		name 		= 'Login Prompt',
		description	= 'Sent During Session Login Only.',
		handler 	= 'handle_login',
	},
	['OK'] = {
		name		= 'Login Success',
		description	= 'Send During Session Login Only, successful login',
		handler 	= 'handle_login_success',
	},
	['FAILED'] = {
		name		= 'Login Failure',
		description	= 'Sent During Session Login Only, password not accepted',
		handler 	= 'handle_login_failure',
	},
	['Timed Out!'] = {
		name		= 'Login Interaction Timed Out',
		description	= 'Sent during Session Login Only, socket connection is then closed',
		handler 	= 'handle_login_timeout',
	},
	['%00'] = {
		name		= 'Virtual Keypad Update',
		description	= 'The panel wants to update the state of the keypad',
		handler 	= 'handle_keypad_update',
	},
	['%01'] = {
		name		= 'Zone State Change',
		description	= 'A zone change-of-state has occurred',
		handler 	= 'handle_zone_state_change',
		type 		= 'zone',
	},
	['%02'] = {
		name		= 'Partition State Change',
		description	= 'A partition change-of-state has occured',
		handler 	= 'handle_partition_state_change',
		type 		= 'partition',
	},
	['%03'] = {
		name		= 'Realtime CID Event',
		description	= 'A system event has happened that is signaled to either the Envisalerts servers or the central monitoring station',
		handler 	= 'handle_realtime_cid_event',
		type 		= 'system',
	},
	['%FF'] = {
		name		= 'Envisalink Zone Timer Dump',
		description	= 'This command contains the raw zone timers used inside the Envisalink. The dump is a 256 character packed HEX string representing 64 UINT16 (little endian) zone timers. Zone timers count down from 0xFFFF (zone is open) to 0x0000 (zone is closed too long ago to remember). Each tick of the zone time is actually 5 seconds so a zone timer of 0xFFFE means 5 seconds ago. Remember, the zone timers are LITTLE ENDIAN so the above example would be transmitted as FEFF.',
		handler 	= 'handle_zone_timer_dump',
	},
	['^00'] = {
		name		= 'Poll',
		description	= 'Envisalink poll',
		handler 	= 'handle_poll_response',
		type 		= 'envisalink',
	},
	['^01'] = {
		name		= 'Change Default Partition',
		description	= 'Change the partition which keystrokes are sent to when using the virtual keypad.',
		handler 	= 'handle_command_response',
		type 		= 'envisalink',
	},
	['^02'] = {
		name		= 'Dump Zone Timers',
		description	= 'This command contains the raw zone timers used inside the Envisalink. The dump is a 256 character packed HEX string representing 64 UINT16 (little endian) zone timers. Zone timers count down from 0xFFFF (zone is open) to 0x0000 (zone is closed too long ago to remember). Each tick of the zone time is actually 5 seconds so a zone timer of 0xFFFE means 5 seconds ago. Remember, the zone timers are LITTLE ENDIAN so the above example would be transmitted as FEFF.',
		handler 	= 'handle_command_response',
		type 		= 'envisalink',
	},
	['^03'] = {
		name		= 'Keypress to Specific Partition',
		description	= 'This will send a keystroke to the panel from an arbitrary partition. Use this if you dont want to change the TPI default partition.',
		handler 	= 'handle_command_response',
		type 		= 'envisalink',
	},
	['^0C'] = {
		name		= 'Response for Invalid Command',
		description	= 'This response is returned when an invalid command number is passed to Envisalink',
		handler 	= 'handle_command_response',
		type 		= 'envisalink',
	}
}

evlDefs.Response_Codes = {
    ['00'] = 'Command Accepted',
    ['01'] = 'Receive Buffer Overrun (a command is received while another is still being processed)',
    ['02'] = 'Unknown Command',
    ['03'] = 'Syntax Error. Data appended to the command is incorrect in some fashion',
    ['04'] = 'Receive Buffer Overflow',
    ['05'] = 'Receive State Machine Timeout (command not completed within 3 seconds)'
}

evlDefs.LED_Flags = {
	alarm 					= 1,
    alarm_in_memory 		= 2,
    armed_away 				= 4,
    ac_present				= 8,
    bypass					= 16,
    chime					= 32,
    not_used1				= 64,
    armed_zero_entry_delay	= 128,
    alarm_fire_zone			= 256,
    system_trouble			= 512,
    not_used2				= 1024,
    not_used3				= 2048,
    ready					= 4096,
    fire					= 8192,
    low_battery 			= 16384,
    armed_stay 				= 32768
}

evlDefs.Partition_Status_Codes = {
    ['00'] = {
				name 			= 'NOT_USED',
				description 	= "Partition is not used or doesn't exist"
			},
    ['01'] = {
				name 			= 'READY',
				description 	= 'Ready',
				pluginhandler 	= 'disarmed'
			},
    ['02'] = {
				name 			= 'READY_BYPASS',
				description 	= 'Ready to Arm (Zones are Bypasses)',
				pluginhandler 	= 'disarmed'
			},
    ['03'] = {
				name 			= 'NOT_READY',
				description 	= 'Not Ready',
				pluginhandler 	= 'disarmed'
			},
    ['04'] = {
				name 			= 'ARMED_STAY',
				description 	= 'Armed in Stay Mode',
				pluginhandler 	= 'armedHome'
			},
    ['05'] = {
				name 			= 'ARMED_AWAY',
				description 	= 'Armed in Away Mode',
				pluginhandler 	= 'armedAway'
			},
    ['06'] = {
				name 			= 'ARMED_MAX',
				description		= 'Armed in Away Mode',
				pluginhandler 	= 'armedInstant'
			},
    ['07'] = {
				name 			= 'EXIT_ENTRY_DELAY',
				description 	= 'Entry or Exit Delay'
			},
    ['08'] = {
				name 			= 'IN_ALARM',
				description 	= 'Partition is in Alarm',
				pluginhandler 	= 'alarmTriggered'
			},
    ['09'] = {
				name 			= 'ALARM_IN_MEMORY',
				description 	= 'Alarm Has Occurred (Alarm in Memory)',
				pluginhandler 	= 'alarmCleared'
			}
}

evlDefs.Beep = {
    ['00'] = 'off',
    ['01'] = 'beep 1 time',
    ['02'] = 'beep 2 times',
    ['03'] = 'beep 3 times',
    ['04'] = 'continous fast beep',
    ['05'] = 'continuous slow beep'
}

return evlDefs
