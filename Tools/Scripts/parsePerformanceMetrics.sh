#!/bin/bash

# Parses performance metrics from the full report of a IntegrationTest run (do not use xcpretty first!)
# This file can normally be found in `~/Library/Logs/scan/IntegrationTests-IntegrationTests.log`

# Provide file as $1
# Provide identifier (eg, date, GITHUB_SHA) as $2

echo "Parsing $1 for test results with identifier $2" >&2

NOW=`date -u -Iminutes`

# Find all the measurement lines in the file, then strip out the gumph into a CSV-like format.
grep ".*measured.*values" $1 | sed -e "s/.*Test Case .*-\[//" -e "s/\]' measured \[/,/" -e "s/\].*values: \[/,/" -e "s/\], performance.*//" -e "s/^/$2,/" \
   -e "s/IntegrationTests.PerformanceTests testLoginFlow,Duration .AppLaunch., s/launchPerformance/" \
   -e "s/IntegrationTests.PerformanceTests testLoginFlow,Duration .Login., s/loginPerformance/" \
   -e "s/IntegrationTests.PerformanceTests testLoginFlow,Duration .RoomFlow., s/roomFlowPerformance/" \
   -e "s/IntegrationTests.PerformanceTests testLoginFlow,Duration .FirstRooms., s/firstRoomsPerformance/" \
   -e "s/IntegrationTests.PerformanceTests testLoginFlow,Duration .FirstSync., s/firstSyncPerformance/" \
   -e "s/IntegrationTests.PerformanceTests testLoginFlow,Clock Monotonic Time, s/totalTime/" \
   -e "s/^/$NOW,/"

# The output should contain fields for the identifier, name, type, unit, then a list of recorded values (normally 5)

# Put this into a file somewhere for later usage.
