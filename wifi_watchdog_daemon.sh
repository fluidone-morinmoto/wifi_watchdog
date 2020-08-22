#! /bin/bash

###############################################################################
## author: morin@fluidone.it
## name: Wifi Watchdog for Raspberry Pi
##
## Continuous check of a wifi network connection.
##
## Put the name of this script into your service ExecStart.
##
###############################################################################

## Write here the path of log file
log="/root/wifi_watchdog/wifi_watchdog.log"
## Write here the path of wifi watchdog script file
wifi_watchdog_script="/root/wifi_watchdog/wifi_watchdog.sh"
## Infinite loop
while [ 1 ]; do
    ## Define amount of seconds to sleep
    sleeping_seconds=50
    ## Get the wifi_watchdog.sh process ID
    process_id=`/bin/ps -fu $USER| grep "wifi_watchdog.sh" | grep -v "grep" | awk '{print $2}'`
    if [ -z "${process_id}" ]; then
        ## If the process doesnt exist try to check wifi connection
        echo "Service not running. Check wifi..." >> "${log}"
        bash "${wifi_watchdog_script}"
    else
        ## Else the process is already running. Try the next time
        echo "Service already running. Sleep some time ..." >> "${log}"
    fi
    echo "Sleep ${sleeping_seconds} secs..." >> "${log}"
    ## Sleep
    sleep "${sleeping_seconds}"
done
