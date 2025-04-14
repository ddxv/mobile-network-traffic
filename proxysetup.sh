#!/bin/bash
# User input
local=$1 # local for mitm traffic running on same device, don't include to mitm a different device


# MITM virtualenv
if [ -d "mitm-env" ]; then
source mitm-env/bin/activate
fi

# Setup based on: https://docs.mitmproxy.org/stable/howto-transparent/

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Disable ICMP redirects
sudo sysctl -w net.ipv4.conf.all.send_redirects=0

if [ "$local" = "-r" ]; then # if is via router
	echo "Setting all proxied router traffic for port 8080"
	sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p udp --dport 80 -j REDIRECT --to-port 8080
	sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p udp --dport 443 -j REDIRECT --to-port 8080
	sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 80 -j REDIRECT --to-port 8080
	sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 443 -j REDIRECT --to-port 8080
	mitmproxy --mode transparent --showhost --set block_global=false -w ~/traffic.log --listen-port 8080
fi

if [ "$local" = "-w" ]; then
	echo "Waydroid VM traffic routed to port 8080"
	sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
	sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080
	sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
	sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080
    echo "Setting ports 80, 443 to redirect to 8080. Finished"

	mitmweb --mode transparent --showhost --set block_global=false -w ~/traffic.log --listen-port 8080
fi
if [ "$local" = "-d" ]; then
	# TO DELETE THE RULES
	# IPv4 rules
	sudo iptables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
	sudo iptables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080

	# IPv6 rules
	sudo ip6tables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
	sudo ip6tables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080
    echo "Removed ports 80, 443 redirect to 8080. Finished"

fi


sudo iptables -t nat -F
