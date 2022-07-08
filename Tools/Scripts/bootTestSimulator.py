#!/usr/bin/python2.7

# import datetime
import os
import subprocess
import json
import argparse
# import pytz

RUNTIME_PREFIX = 'com.apple.CoreSimulator.SimRuntime.'

def device_name(device):
    return device['name']
def runtime_name(runtime):
    return runtime.replace(RUNTIME_PREFIX, '').replace('-', '.')
# def utc_offset():
#     utc_offset_string = subprocess.check_output("date +%Z", shell=True).strip()
#     hours = 0
#     minutes = 0
#     parts = utc_offset_string.split(":")
#     if len(parts) > 0:
#         hours = float(parts[0])
#     if len(parts) > 1:
#         minutes = float(parts[1])/60
#     return hours + minutes
# def utc_offset_string():
#     result = subprocess.check_output("date +%Z", shell=True).strip()
#     if len(result.split(":")) > 1:
#         return result
#     else:
#         return result + ":00"

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

            # timezone_addition = 1 # can't explain this
            # delta = timezone_addition - utc_offset()
            # desired_time = datetime.datetime(2007, 1, 9, 9, 41, 0, tzinfo=pytz.utc)
            # final_time = desired_time + datetime.timedelta(hours=delta)
            # overridden_time = final_time.isoformat() + utc_offset_string()
            dirname = os.path.dirname(os.path.abspath(__file__))
            script_path = os.path.join(dirname, 'get_simulator_time.rb')
            overridden_time = subprocess.check_output("ruby " + script_path, shell=True)
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
