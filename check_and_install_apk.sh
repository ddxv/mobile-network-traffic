#!/bin/bash

set -e

Help() {
	# Display Help
	echo "Description of the script functions."
	echo
	echo "Syntax: scriptTemplate [-h|s <store_id>]"
	echo "options:"
	echo "h     Print this Help."
	echo "s     Enter a store_id."
	echo
}

while getopts hs: option; do
	case $option in
	h) # display Help
		Help
		exit
		;;
	s) # Enter a store_id
		app=$OPTARG ;;
	\?) # Invalid option
		echo "Error: Invalid option"
		exit
		;;
	esac
done

if [ -z "$app" ]; then
	echo "${app:?Missing -s}"
else
	echo "App is set to: $app"
fi

waydroidinstalledapps=$(waydroid app list)

linecount=$(echo "$waydroidinstalledapps" | grep -c "packageName: $app" || true)
# echo "Line count " "$linecount" " and lines " "$lines"
if [ "$linecount" = 0 ]; then
	echo "store_id: $app not yet installed"
	python download_apk.py -s "$app"
	echo "store_id: $app installing"
	waydroid app install "apks/$app.apk"
else
	lines=$(echo "$waydroidinstalledapps" | grep "packageName: $app")
	echo "Matches $linecount already installed apps: $lines"
fi




