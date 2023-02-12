#!/bin/bash
port=$1
local=$2
user="mitmproxyuser"

if [ "$port" -gt "8000" ] && [ "$port" -lt "9000" ];
then
    echo "Set ports 80, 443 to redirect to $port."
else
    echo 'Port must be between 8000-9000';
    exit
fi



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
sudo -u mitmproxyuser -H bash -c '/usr/bin/mitmproxy --mode transparent --showhost --set block_global=false'
else
    echo "Setting all traffic from 8080. No local traffic."
sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 80 -j REDIRECT --to-port $port
sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 443 -j REDIRECT --to-port $port
sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 80 -j REDIRECT --to-port $port
sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 443 -j REDIRECT --to-port $port
fi

echo "Setting ports 80, 443 to redirect to $port. Finished"
