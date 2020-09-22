#! /bin/bash

###############################################################################
## author: morin@fluidone.it
## name: Wifi Watchdog for Raspberry Pi
##
## Ensures a continuous connection to a wifi network.
##
## At start this script checks if you are connected to a Wifi network.
## If not, it reads a list of passwords from a text file. (Passwords must be
## unquoted).
## Detects all wifi networks and try to connect to each of these with collected
## passwords via wpa supplicant. It try also a without password connection.
##
###############################################################################

## Version constant for versionig
version="1.0.1-dev"
## Write here the path of log file
log="/root/wifi_watchdog/wifi_watchdog.log"
## The WPA Supplicant Congifuration file's path
wpa_supplicant_conf="/etc/wpa_supplicant/wpa_supplicant.conf"

log_message () {
    msg=$@
    echo "$(date +"%Y-%m-%d %T") ${msg}" >> ${log}
}

try_wifi () {
    ## Write here the path of list of password file
    passwords_file="/root/wifi_watchdog/wifi_pwd_list.txt"
    list_of_passwords=()

    ## Reads passwords_file, and store them into an array
    while read password
    do
        ## If a row is empty skip it
        if [ -z "${password}" ]; then
            continue
        fi
        ## Quotes password
        quoted_password="\"${password}\""
        ## Put password in array
        list_of_passwords+=("psk=${quoted_password}")
    done <<<$(cat ${passwords_file})
    ## Put the NONE keyword into array. It is used for a without password
    ## connection
    list_of_passwords+=("key_mgmt=NONE")
    log_message "${#list_of_passwords[@]} passwords in array"

    ## Collect wifi network names into a string
    string_of_networks=$(iw dev wlan0 scan | grep SSID);

    ## Populate an array with rows into the previous variable
    array=()
    while read -r line; do
       array+=("${line}")
    done <<< "${string_of_networks}"

    log_message ${string_of_networks}
    ## Trim strings and populate an array with network names
    list_of_networks=()
    for element in "${array[@]}"
    do
        name_of_network_to_trim="${element#"SSID: "}"
        name_of_network="$(echo -e "${name_of_network_to_trim}" | sed -e 's/^[[:space:]]*//')"
        log_message "Detected: ${name_of_network}"
        list_of_networks+=("${name_of_network}")
    done

    ## Start the loop through network and password. Try connection with all
    ## combinations
    log_message "Try ${#list_of_networks[@]} networks in combination of ${#list_of_passwords[@]} passwords"
    for network_name in "${list_of_networks[@]}"
    do
        for password in "${list_of_passwords[@]}"
        do
            ## Writes configuration to the wpa supplicant file
            echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" > "${wpa_supplicant_conf}"
            echo "update_config=1" >> "${wpa_supplicant_conf}"
            echo "country=IT" >> "${wpa_supplicant_conf}"
            echo "" >> "${wpa_supplicant_conf}"
            echo "network={" >> "${wpa_supplicant_conf}"
        	echo -e "\tssid=\"${network_name}\"" >> "${wpa_supplicant_conf}"
        	echo -e "\t${password}" >> "${wpa_supplicant_conf}"
            echo "}" >> "${wpa_supplicant_conf}"

            log_message "Try ${network_name} with password ${password}"

            ## Shutdown wlan0
            log_message "Shutdown wlan0..."
            ifconfig wlan0 down >/dev/null

            ## Reload daemon configurations
            log_message "Reload daemon configurations..."
            systemctl daemon-reload >/dev/null

            ## Restart wlan0
            log_message "Restart wlan0..."
            ifconfig wlan0 up >/dev/null

            ## Restart dhcp service
            log_message "Restart dhcp service..."
            systemctl restart dhcpcd >/dev/null

            ## "Restart networking service
            log_message "Restart networking service ..."
            service networking restart >/dev/null

            ## Get the router ip
            router_ip=$(route -n | grep 'wlan0$' | grep '^0\.0\.0\.0' | awk '{print $2}')

            ## Write ifconfig output to log file
            ifconfig >> "${log}"

            ## If router ip is empty try with another combination
            if [ -z "${router_ip}" ]; then
                log_message "NOT CONNECTED! Try with another combination ..."
            ## Else you are connected and exit
            else
                log_message "ONLINE !"
                exit
            fi
        done
        ## Password loop done
    done
    ## Networks loop is done
    exit
}

## Init the log file
echo "$(date +"%Y-%m-%d %T") Starting Fluid-Wifi Watchdog service..." >> "${log}"
## Get the router ip. If it's not empty we assume to be connected
router_ip=$(route -n | grep 'wlan0$' | grep '^0\.0\.0\.0' | awk '{print $2}')
## If router ip is empty start the try connection function
if [ -z "${router_ip}" ]; then
    try_wifi
else
    log_message "ONLINE"
fi
log_message "Ended Fluid-Wifi Watchdog service"
exit
