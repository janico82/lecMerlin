# lecMerlin - automatically control AsusWRT-Merlin LEDs
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/20ebd532514c43d38b44834ccd528bb5)](https://app.codacy.com?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
![Shellcheck](https://github.com/janico82/lecMerlin/actions/workflows/shellcheck.yml/badge.svg)

## v1.0.0
### Updated on 2024-01-22
## About
Feature expansion to automatically control device LEDs based on the device time.

lecMerlin is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?business=7GJ9GM39PF3NS&no_recurring=0&item_name=for+support+of+continued+development+of+Asuswrt-Merlin+addons&currency_code=EUR)

## Supported firmware versions
### Core lecMerlin features
You must be running firmware no older than:
*   [Asuswrt-Merlin](https://www.asuswrt-merlin.net/) 384.5
*   [john9527 fork](https://www.snbforums.com/threads/fork-asuswrt-merlin-374-43-lts-releases-v37ea.18914/) 374.43_32D6j9527

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl -fsL --retry 3 "https://janico82.gateway.scarf.sh/asuswrt-merlin/lecMerlin/master/lecMerlin.sh" -o /jffs/scripts/lecMerlin && chmod 0755 /jffs/scripts/lecMerlin && /jffs/scripts/lecMerlin install
```

Please then follow instructions shown on-screen.

## Usage
### Command Line
To launch the lecMerlin menu after installation, use:
```sh
sh /jffs/scripts/lecMerlin
```
```sh
#############################################################
##          _           __  __           _ _               ##
##         | | ___  ___|  \/  | ___ _ __| (_)_ __          ##
##         | |/ _ \/ __| |\/| |/ _ \ '__| | | '_ \         ##
##         | |  __/ (__| |  | |  __/ |  | | | | | |        ##
##         |_|\___|\___|_|  |_|\___|_|  |_|_|_| |_|        ##
##                                                         ##
##          https://github.com/janico82/lecMerlin          ##
##                                                         ##
#############################################################
   lecMerlin Main menu - version: 1.0.0
   1.   Turn device LEDs on
   2.   Turn device LEDs off
   e.   Exit
   z.   Uninstall
#############################################################
Choose an option: 
```

## FAQs
### Details of lecMerlin configuration items:
lecMerlin is hardcoded to change the device LEDs at 8:00 (8:00 AM) and 22:00 (10:00 PM). If you wont to change the time please edit the lecMerlin file in the folloing function:

```sh
configEx() {

    # Get the device current hour
    current=$(date +%H)

    # Check if the current hour is between 8:00 (8:00 AM) and 22:00 (10:00 PM)
    if [ "$current" -ge 8 ] && [ "$current" -lt 22 ]; then
        led_config on
    else
        led_config off
    fi 
}
```

## Scarf Gateway
Installs and updates for this addon are redirected via the [Scarf Gateway](https://about.scarf.sh/scarf-gateway) by [Scarf](https://about.scarf.sh/about). This allows gather data on the number of new installations of this addon or how often users check for updates. Scarf Gateway functions similarly to a link shortener like bit.ly, redirecting traffic as a domain gateway.

Please refer to Scarf's [Privacy Policy](https://about.scarf.sh/privacy) for more information about the data that is collected and how it is processed.
