#!/usr/bin/python3

from encodings import utf_8
import os
import subprocess
import json
import argparse
from datetime import datetime

RUNTIME_PREFIX = 'com.apple.CoreSimulator.SimRuntime.'

def device_name(device):
    return device['name']
def runtime_name(runtime):
    return runtime.replace(RUNTIME_PREFIX, '').replace('-', '.')

parser = argparse.ArgumentParser()
parser.add_argument('--name', type=str, help='Simulator name (like \'iPhone 13 Pro Max\')', required=True)
parser.add_argument('--version', type=str, default='iOS.15.5', help='OS version (defaults to \'iOS.15.5\')', required=False)

args = vars(parser.parse_args())

simulator_name = args['name']
os_version = args['version'].replace('.', '-')

runtimes_map = subprocess.check_output("/usr/bin/xcrun simctl list --json devices available", shell=True)
runtime = RUNTIME_PREFIX + os_version
json_object = json.loads(runtimes_map)
if runtime in json_object['devices']:
    devices = json_object['devices'][runtime]

    device_found=False
    for device in devices:
        if device_name(device) == simulator_name:
            UDID=device['udid']
            print("Found device UDID: " + UDID)

            dirname = os.path.dirname(os.path.abspath(__file__))
            overridden_time = datetime(2007, 1, 9, 9, 41, 0).astimezone().isoformat()
            print("Will override simulator with time: " + overridden_time)
            os.system("/usr/bin/xcrun simctl boot '" + UDID + "' > /dev/null 2>&1")
            os.system("/usr/bin/xcrun simctl status_bar '" + UDID + "' override --time '" + overridden_time + "' --dataNetwork 'wifi' --wifiMode 'active' --wifiBars 3 --cellularMode 'active' --cellularBars 4 --batteryState 'charged' --batteryLevel 100 > /dev/null 2>&1")
            print("Simulator booted and status bar overriden")
            device_found=True
            break
    
    if device_found == False:
        print("Device could not be found. \n\nAvailable devices: " + ', '.join(map(device_name, devices)))
        exit(1)
else:
    print("Runtime could not be found. \n\nAvailable runtimes: " + ', '.join(map(runtime_name, json_object['devices'].keys())))
    exit(1)
