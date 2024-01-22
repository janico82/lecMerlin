#!/bin/sh

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
##      Credit to thelonelycoder for led_control script    ##
##       and to @RMerlin for AsusWRT-Merlin firmware.      ##
#############################################################
# Last Modified: janico82 [2024-Jan-22].
#--------------------------------------------------

# Shellcheck directives #
# shellcheck disable=SC1087
# shellcheck disable=SC2086

# Script variables #
readonly script_name="lecMerlin"
readonly script_xdir="/jffs/scripts"
readonly script_version="1.0.0"

# Script environment variables
readonly env_error=127 
readonly env_enable=1
readonly env_disable=0
readonly env_regex_binary_name="(on|off)"
readonly env_file_srv_start="/jffs/scripts/services-start"

loggerEx() {

	# Send output messages to syslog by default or cli. Usage: loggerEx "Script in use"
	mtype="$(if [ $# -eq 1 ]; then echo "default"; else echo "$1"; fi)"
	message="$(if [ $# -eq 1 ]; then echo "$1"; else echo "$2"; fi)"
	pid="$(echo $$ | awk -F. '{ printf("%05d", $1); }')"
	
	if [ "$mtype" = "default" ] || [ "$mtype" = "cli" ]; then
		# Send output messages to syslog
		logger -t "$script_name[$pid]" "$message"
	fi

	# Send output message to cli
	if [ "$mtype" = "cli" ] || [ "$mtype" = "clio" ] ; then
		printf "%s\\n\\n" "$message"
	fi
}

validate_binary_name() {

	# Confirm the value is valid. Usage: validate_binary_name on/off
	if [ $# -ne 1 ] || ! echo "$1" | grep -qE "^$env_regex_binary_name$" ; then
		return $env_error # NOK
	else
		return 0 # OK
	fi
}

evfile_services_start() {
	evfile=$env_file_srv_start

	# Confirm the event files are created. Usage evfile_services_start create
	case $1 in
		create)
			
			if [ -f $evfile ]; then
				filelinecount=$(grep -c '# '"($script_name) LED Control Tool" "$evfile")
				
				if [ "$filelinecount" -gt 0 ]; then
					sed -i -e '/# ('"$script_name"')/d' "$evfile"
				fi

				echo "$script_xdir/$script_name install && $script_xdir/$script_name run-config & # ($script_name) LED Control Tool" >> "$evfile"
			else
				{
				 echo "#!/bin/sh"
				 echo ""
				 echo "$script_xdir/$script_name install && $script_xdir/$script_name run-config & # ($script_name) LED Control Tool" 
				} > "$evfile"
				chmod 0755 "$evfile"
			fi
		;;
		delete)
			
			if [ -f "$evfile" ]; then
				filelinecount=$(grep -c '# '"($script_name) LED Control Tool" "$evfile")
				
				if [ "$filelinecount" -gt 0 ]; then
					sed -i -e '/# ('"$script_name"')/d' "$evfile"
				fi
			fi
		;;
	esac
}

pcfile_cron() {

	# Confirm the cron job is created. Usage pcfile_cron create
	case $1 in
		create)
			filelinecount=$(cru l | grep -c "$script_name")
		
			lc=1
			while [ $lc -le $filelinecount ]; do
				cru d "$script_name.$lc"
				lc=$((lc + 1))
			done

			cru a "$script_name.1" "0 8 * * * $script_xdir/$script_name run-config"
			cru a "$script_name.2" "0 22 * * *  $script_xdir/$script_name run-config"
		;;
		delete)
			filelinecount=$(cru l | grep -c "$script_name")
			
			lc=1
			while [ $lc -le $filelinecount ]; do
				cru d "$script_name.$lc"
				lc=$((lc + 1))
			done
		;;
	esac
}

led_config() {

    # Confirm the function was called with the correct arguments.
    if [ $# -ne 1 ] || ! validate_binary_name "$1"; then
        loggerEx "Error: Invalid arguments. Usage: led_config on/off."
        
        exit $env_error # NOK
    fi

	case $1 in
		on)
			action=$env_disable
		;;
		off)
			action=$env_enable
		;;
	esac

    # Setup nvram variables
    nvram set "led_disable"="$action"
    nvram commit

    # Restart dnsmasq service
    service restart_leds
    
    loggerEx "Device LEDs configuration set($action)."

    return 0 # OK
}

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

script_install () {

	loggerEx clio "Starting installation of script($script_name $script_version)."
	sleep 1

	evfile_services_start create 2>/dev/null
	pcfile_cron create 2>/dev/null

	loggerEx clio "Script($script_name $script_version) installation complete."
	while true; do
		printf "Do you want to run config? (y/n): "
		read -r key
		case "$key" in
			y|Y)
				sh "$script_xdir/$script_name" run-config

				loggerEx clio "Configuration complete."
				break
			;;
			n|N)
				break
			;;
			*)
				printf "\\nPlease choose a valid option.\\n\\n"
			;;
		esac
	done
}

script_uninstall() {

	loggerEx clio "Starting script($script_name $script_version) uninstall."
	sleep 1

	pcfile_cron delete 2>/dev/null
	evfile_services_start delete 2>/dev/null

    # Remove script file
	rm -f "$script_xdir/$script_name" 2>/dev/null

	loggerEx clio "Script($script_name $script_version) uninstall complete."
}

show_about() {
	cat <<EOF
About
  $script_name is a feature expansion for AsusWRT-Merlin that automatically enables 
  and disables device LEDs.
License
  $script_name is free to use under the GNU General Public License
  version 3 (GPL-3.0) https://opensource.org/licenses/GPL-3.0
Help & Support
  
Source code
  https://github.com/janico82/$script_name
EOF
	printf "\\n"
}

show_help() {
	cat <<EOF
Available commands: \\n"
  $script_name about              explains $script_name functionality
  $script_name install            installs script
  $script_name uninstall          uninstalls script
  $script_name run-config         apply $script_name configuration
EOF
	printf "\\n"
}

show_banner() {
	clear
	printf "\\n"
	printf "#############################################################\\n"
	printf "##          _           __  __           _ _               ##\\n"
	printf "##         | | ___  ___|  \/  | ___ _ __| (_)_ __          ##\\n"
    printf "##         | |/ _ \/ __| |\/| |/ _ \ '__| | | '_ \         ##\\n"
    printf "##         | |  __/ (__| |  | |  __/ |  | | | | | |        ##\\n"
    printf "##         |_|\___|\___|_|  |_|\___|_|  |_|_|_| |_|        ##\\n"
	printf "##                                                         ##\\n"
	printf "##          https://github.com/janico82/lecMerlin          ##\\n"
	printf "##                                                         ##\\n"
	printf "#############################################################\\n"
	printf "\\n"
}

show_menu() {
	printf "  %s Main menu - version: %s \\n" "$script_name" "$script_version"
	printf "  1.   Turn device LEDs on \\n"
	printf "  2.   Turn device LEDs off \\n"
	printf "  e.   Exit \\n"
	printf "  z.   Uninstall \\n"
	printf "\\n"
	printf "#############################################################\\n"
	printf "\\n"

	while true; do
		printf "Choose an option: "
		read -r key
		case $key in
			1)
                led_config on
			;;
			2)
                led_config off
			;;
			e)
				show_banner
				printf "\\nThanks for using %s!\\n\\n" "$script_name"
				exit 0
			;;
			z)
				show_banner
				while true; do
					printf "\\nAre you sure you want to uninstall %s? (y/n): " "$script_name"
					read -r conf
					case "$conf" in
						y|Y) 
							script_uninstall 
							exit 0
						;;
						n|N) break ;;
						*) 
							printf "\\nPlease choose a valid option.\\n\\n"
						;;
					esac
				done
			;;
			*)
				printf "\\nPlease choose a valid option.\\n\\n"
			;;
		esac
	done

	show_banner
	show_menu
}

#############################################################################################

# Confirm the script was called with no arguments
if [ $# -eq 0 ] || [ -z "$1" ]; then

	show_banner
	show_menu
	exit 0
fi

# Run script argument commands
case "$1" in
	install)
		
		# Execute the script install instructions.
		script_install
		exit 0
	;;
	rc|run-config)

		# Execute the config logic function.
		configEx
		exit 0
	;;
	uninstall)

		# Execute the script removal instructions.
		script_uninstall
		exit 0
	;;
	about)

		show_banner
		show_about
		exit 0
	;;
	help)
		show_banner
		show_help
		exit 0
	;;
	*)
		printf "Error: Invalid script arguments"
		exit $env_error
	;;
esac