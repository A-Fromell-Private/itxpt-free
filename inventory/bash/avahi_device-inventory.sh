#!/bin/bash
export PATH=/sbin:/bin:/usr/bin:/usr/sbin
#==============================================================#
## Avahi ITxPT device inventory updater ver. 1.0.5            ##
# name: avahi_device-inventory.sh                              #
# Written by: Anders Fromell                                   #
# This is verified to work on:                                 #
# - x86 PC with ubuntu 16.04                                   #
# - x86 PC with ubuntu 20.04                                   #
# - Raspberry PI 2B with ubuntu 16.04 server armv7l            #
# - Raspberry PI 2B with ubuntu 20.04 server armv7l            #
#==============================================================#

# ToDos...
# autodetect LAN interface
# add boottime key and commandline parameter to trigger it
# .....

# Default variables you might want to change...
APPVERS=1.0.5
SERVICE_FILE=inventory.service
SERVICE_PATH=/etc/avahi/services/
LAN=enp2s0
#LAN=enp0s8
#LAN=eth0


# internal defaults, constants and vars ; do not change..
TXT_SUFFIX="</txt-record>"
FAILED=0
VERBOSE=0

# get command line parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -i|--interface)
    LAN="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--path)
    SERVICE_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo
    echo "Usage: avahi_device-inventory.sh [arguments] {value}"
    echo Arguments:
	echo " -f | --file       ; sets the filename of the avahi service to manipulate,if not given it defaults to: inventory.service"
    echo " -i | --interface  ; sets the LAN interface to receive the MAC address for, if not given it defaults to: eth0"
    echo " -p | --path       ; sets the path to the avahi service file to manipulate,if not given it defaults to: /etc/avahi/services/"
	echo " -v | --verbose    ; prints additional output to consol"
    echo " -h | --help       ; shows this help screen"
    shift # past argument
    exit 0
    ;;
    -f|--servicefile)
    SERVICE_FILE="$2"
    shift # past argument
    shift # past value
    ;;
    -v|--verbose)
    VERBOSE=1
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    echo "Unknown argument ! Use -h or --help to find out more.."
    exit 0
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# check if service file and path exists
if [ ! -d "$SERVICE_PATH" ]; then
	logger "$0 - The path to: $SERVICE_FILE do not exist"
	[ "$VERBOSE" != "0" ] && echo " - The path to: $SERVICE_FILE do not exist"
	exit 1
else
	[ "$VERBOSE" != "0" ] && echo " - The path to: $SERVICE_FILE exist"
fi

if [ ! -f "$SERVICE_PATH$SERVICE_FILE" ]; then
	logger "$0 - The file: $SERVICE_FILE do not exist, trying to create one from a template"
	[ "$VERBOSE" != "0" ] && echo " - The file: $SERVICE_FILE do not exist, trying to create one from a template"
	if [ -f "/opt/inventory/inventory.service.template" ]; then
		msg=$(cp /opt/inventory/inventory.service.template $SERVICE_PATH$SERVICE_FILE 2>&1)
		[ "$?" != "0" ] &&  logger "$0 - inventory.service template update failed: $msg" && [ "$VERBOSE" != "0" ] && echo "- inventory.service template update failed: $msg" && exit 1 || :
		[ "$VERBOSE" != "0" ] && echo inventory.service template update done..
	else
		logger "$0 - The file /opt/inventory/inventory.service.template is missing"
		[ "$VERBOSE" != "0" ] && echo The file /opt/inventory/inventory.service.template is missing
		exit 1
	fi

fi

# print some if verbose..
if [ "$VERBOSE" != "0" ]; then
	echo
	echo Inventory service version  = "${APPVERS}"
	echo LAN INTERFACE   = "${LAN}"
	echo SERVICE PATH    = "${SERVICE_PATH}"
	echo SERVICE FILE    = "${SERVICE_FILE}"
fi

# Grab the OS version and cpu serial and hardware type and MAC
KRNL=$(uname -srp)
DIST=$(lsb_release --description | grep ^Description| cut -d":" -f2 | xargs)
SWVERS="$DIST $KRNL"

# cpu model
CPU_MODEL=$(cat /proc/cpuinfo|grep -m 1 "model name"|cut -d":" -f2 | xargs)

# check what architecture we are on and rip out the neede info in different ways

case "$KRNL" in
		*x86*)
			# It seams like we are on a x86 box
			[ "$VERBOSE" != "0" ] && echo "x86 present"
			MODEL="x86 $CPU_MODEL"
			MAN=$(dmidecode -t 2|grep -m 1 "Manufacturer"|cut -d":" -f2|xargs)
			REV=$(dmidecode -t 2|grep -m 1 "Version"|cut -d":" -f2|xargs)
			# x86 (from dbus) installation CCID not hw CCID
			SERIAL=$(cat /var/lib/dbus/machine-id)
			;;
		*raspi*)
			# It seams like we are on a RaspberryPi
			[ "$VERBOSE" != "0" ] && echo "raspi present"
			HW=$(cat /proc/cpuinfo | grep ^Hardware | cut -d":" -f2 | xargs)
			REV=$(cat /proc/cpuinfo | grep ^Revision | cut -d":" -f2 | xargs)
			MODEL="RPI2B $HW $CPU_MODEL"
			# (cpu serial)
			SERIAL=$(cat /proc/cpuinfo | grep ^Serial | cut -d":" -f2 | xargs)
			;;
		*Placeholder*)
			# This is a placeholder for new targets
			[ "$VERBOSE" != "0" ] && echo "raspi present"
			;;
		*)
			# we dont have a clue
			[ "$VERBOSE" != "0" ] && echo "unknown hardware"
			;;
esac


# remove any commas from MODEL
MODEL=$(echo $MODEL| tr -d ,)

# make sure  $MAN is populated
if [ -z "$MAN" ]; then
	MAN="NA"
	[ "$VERBOSE" != "0" ] && echo "unable to read hardware manufacturer, defaults to: NA"
	logger "$0 - unable to read hardware manufacturer, defaults to: NA"
else
	[ "$VERBOSE" != "0" ] && echo "sucessfully read hardware manufacturer, $MAN"
        logger "$0 - hardware manufacturer was detected, $MAN  rev. $REV"
fi

## get MAC for LAN interface
LAN_MAC=$(cat /sys/class/net/$LAN/address)

## timestamp ## (this is optional but recomended..
UPDATE=$(date --iso-8601=seconds)


# if verbose, print raw data after formatting..
if [ "$VERBOSE" != "0" ]; then
	echo
	echo "Manufacturer: $MAN"
	echo "Hardware version: $REV"
	echo "Model: $MODEL"
	echo "Serial: $SERIAL"
	echo "Software version: $SWVERS"
	echo "MAC address for $LAN: $LAN_MAC"
	echo "Timestamp: $UPDATE"
fi

# updating the inventory.service file
# /^[[:blank:]]*YourRegx/  ; ignores leading space

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>serialnumber[ ]*=\).*,\1'$SERIAL$TXT_SUFFIX',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service serialnr update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo serial done..

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>macaddress[ ]*=\).*,\1'$LAN_MAC$TXT_SUFFIX',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service MACaddr update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo mac done..

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>manufacturer[ ]*=\).*,\1'"$MAN$TXT_SUFFIX"',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service manufacturer update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo manufacturer info done..

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>model[ ]*=\).*,\1'"$MODEL$TXT_SUFFIX"',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service model update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo model info done..

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>hardwareversion[ ]*=\).*,\1'"$REV$TXT_SUFFIX"',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service hardwareversion update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo hw done..

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>softwareversion[ ]*=\).*,\1'"$SWVERS$TXT_SUFFIX"',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service softwareversion update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo sw done..

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>swvers[ ]*=\).*,\1'"$APPVERS$TXT_SUFFIX"',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service swvers update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo sw done..

msg=$(sed -i 's,^\([[:blank:]]*<txt-record>update[ ]*=\).*,\1'"$UPDATE$TXT_SUFFIX"',g' $SERVICE_PATH$SERVICE_FILE 2>&1)
[ "$?" != "0" ] &&  logger "$0 - inventory.service timestamp update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo timestamp info done..

# a final toutch to flush avahi cache
touch $SERVICE_PATH$SERVICE_FILE
[ "$?" != "0" ] &&  logger "$0 - unable to touch inventory.service file.. update failed: $msg" && FAILED=1 || :
[ "$VERBOSE" != "0" ] && echo inventory.service file touch done..

# if verbose, output xml data
[ "$VERBOSE" != "0" ] && echo && cat $SERVICE_PATH$SERVICE_FILE && echo



#exit
# [ "$FAILED" != "0" ] &&  logger "$0 - inventory.service might be corrupt" || logger "$0 - inventory.service updated successfully" :

if [ "$FAILED" != "0" ]; then
	logger "$0 - $SERVICE_PATH$SERVICE_FILE might be corrupt"
	[ "$VERBOSE" != "0" ] && echo "STATUS: - $SERVICE_PATH$SERVICE_FILE might be corrupt"
	exit 1
else
	logger "$0 - inventory.service updated successfully"
	[ "$VERBOSE" != "0" ] && echo "STATUS: - $SERVICE_PATH$SERVICE_FILE updated successfully"

fi

exit 0
