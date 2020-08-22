# Wifi Fluid-Watchdog Service

Ensures a continuous connection to a wifi network via DHCP.

### Prerequisites

* bash
* wpa supplicant

### Install

* Clone the repository into /root dir;
* If you prefer another path, change log path and wifi_watchdog.sh path in wifi_watchdog.sh and wifi_watchdog_daemon.sh scripts;
* Populate the wifi_pwd_list.txt file with your passwords;
* Change sleeping seconds with your favorite amount of seconds;
* move wifi_watchdog.service file into /etc/systemd/system/;

<pre>
$ sudo systemctl enable wifi_watchdog
$ sudo systemctl start wifi_watchdog
</pre>

## Authors

* **Fluidone MorinMoto** - *Develop* - [Github](https://github.com/fluidone-morinmoto/)
