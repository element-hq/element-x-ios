#!/usr/bin/python2.7

import os
import subprocess
import sys
import json

if len(sys.argv) != 2:
    print('Usage: ./bootTestSimulator.py \'Simulator Name\'')
    exit(1)

simulator_name=sys.argv[1]

os_version='15-5'
runtimes_map=subprocess.check_output("/usr/bin/xcrun simctl list --json devices available", shell=True)
runtime='com.apple.CoreSimulator.SimRuntime.iOS-' + os_version
json_object=json.loads(runtimes_map)
devices=json_object['devices'][runtime]

for device in devices:
    if device['name'] == simulator_name:
        UDID=device['udid']
        print("Found device UDID: " + UDID)
        os.system("/usr/bin/xcrun simctl boot '" + UDID + "' > /dev/null 2>&1")
        os.system("/usr/bin/xcrun simctl status_bar '" + UDID + "' override --time '2007-01-09T09:41:00+00:00' --dataNetwork 'wifi' --wifiMode 'active' --wifiBars 3 --cellularMode 'active' --cellularBars 4 --batteryState 'charged' --batteryLevel 100 > /dev/null 2>&1")
        os.system("/usr/bin/xcrun simctl status_bar '" + UDID + "' override --time '09:41' > /dev/null 2>&1")
        break