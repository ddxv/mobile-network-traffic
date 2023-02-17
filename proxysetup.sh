#!/bin/bash
# User input
port=$1
local=$2 # local for mitm traffic running on same device, don't include to mitm a different device

# hardcoded variables
user="mitmproxyuser"
location="/usr/share/mitm-data"



# Check port is a port, arbitrary between 8000-9000
if [ "$port" -gt "8000" ] && [ "$port" -lt "9000" ];
then
    echo "Set ports 80, 443 to redirect to $port."
else
    echo 'Port must be between 8000-9000';
    exit
fi



# MITM virtualenv 
source ~/mitmproxy/.virtualenv/bin/activate


# Set forwarding and redirects
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv4.conf.all.send_redirects=0



if [ "$local" = "-l" ]; # check if is local
then
    if id "$user" &>/dev/null; then # check if our user exists
        echo "user $user found"
    else
        echo "user $user not found, creating"  # error messages should go to stderr
        sudo useradd --create-home $user
        sudo -u mitmproxyuser -H bash -c 'cd ~ && pip install --user mitmproxy'
    fi
    echo 'Setting traffic for local user mitmproxyuser. Not outside traffic.';
    sudo iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner mitmproxyuser --dport 80 -j REDIRECT --to-port $port
    sudo iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner mitmproxyuser --dport 443 -j REDIRECT --to-port $port
    sudo ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner mitmproxyuser --dport 80 -j REDIRECT --to-port $port
    sudo ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner mitmproxyuser --dport 443 -j REDIRECT --to-port $port
    
    
    echo "Start and log traffic to $location/traffic.log";
    sudo mkdir -p $location
    sudo groupadd mitm-reports
    sudo usermod -a -G mitm-reports $user
    sudo chgrp -R mitm-reports $location
    sudo chmod -R 2775 $location
    
    
    sudo -u mitmproxyuser -H bash -c '/usr/bin/mitmproxy --mode transparent --showhost --set block_global=false -w /usr/share/mitm-data/traffic.log'
fi

if [ "$local" = "-r" ]; # check if is via router
then
    echo "Setting all proxied router traffic for port 8080."
    sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p udp --dport 80 -j REDIRECT --to-port $port
    sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p udp --dport 443 -j REDIRECT --to-port $port
    sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 80 -j REDIRECT --to-port $port
    sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 443 -j REDIRECT --to-port $port
    mitmproxy --mode transparent --showhost --set block_global=false -w ~/traffic.log
fi

if [ "$local" = "-w" ]; # check if is local waydroid vm, simple
then
    echo "Waydroid VM traffic routed to port 8080"
    sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port $port
    sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port $port
    sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port $port
    sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port $port


    mitmweb --mode transparent --showhost --set block_global=false -w ~/traffic.log
fi


echo "Setting ports 80, 443 to redirect to $port. Finished"
sudo iptables -t nat -F
