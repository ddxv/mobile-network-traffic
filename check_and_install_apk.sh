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
else
	lines=$(echo "$waydroidinstalledapps" | grep "packageName: $app")
	echo "Matches $linecount already installed apps: $lines"
fi
echo "store_id: $app installing"
waydroid app install "apks/$app.apk"
echo "store_id: $app launching"



echo "Setting up MITM proxy for $app..."
./proxysetup.sh -w -s "$app" &
proxy_pid=$!

# Give the proxy a moment to start up
sleep 4
waydroid app launch "apks/$app.apk"

sleep 2

# Check if proxy started successfully
if ! ps -p $proxy_pid > /dev/null; then
    echo "Error: MITM proxy failed to start"
    exit 1
fi

echo "MITM proxy started with PID $proxy_pid"

# Launch the app
echo "Launching $app..."
waydroid app launch "$apk_path"

# Prompt user about proxy
echo ""
echo "The MITM proxy is running in the background with PID $proxy_pid"
echo "When you're done, you can stop it with: kill $proxy_pid"
echo "And clean up the iptables rules with: ./proxysetup.sh -d"



