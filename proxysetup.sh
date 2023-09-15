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
source ~/mitmproxy/venv/bin/activate


# Setup based on: https://docs.mitmproxy.org/stable/howto-transparent/

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Disable ICMP redirects
sudo sysctl -w net.ipv4.conf.all.send_redirects=0



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
