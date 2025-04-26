#!/bin/bash

# Help function to display usage information
Help() {
    echo "Description: Script to set up MITM proxy for traffic inspection."
    echo
    echo "Syntax: $(basename "$0") [-h] [-w|-d|-r] [-s <store_id>]"
    echo "options:"
    echo "h    Print this Help."
    echo "w    Set up Waydroid VM traffic routing."
    echo "d    Delete routing rules."
    echo "r    Set up router traffic routing."
    echo "s    Enter a store_id for logging (optional)."
    echo
}

# Default values
mode=""
app=""

# Process the options
while getopts "hwdrs:" option; do
    case $option in
        h) # display Help
            Help
            exit 0
            ;;
        w) # Waydroid mode
            [ -n "$mode" ] && { echo "Error: Only one mode (-w, -d, -r) can be specified"; exit 1; }
            mode="waydroid"
            ;;
        d) # Delete rules mode
            [ -n "$mode" ] && { echo "Error: Only one mode (-w, -d, -r) can be specified"; exit 1; }
            mode="delete"
            ;;
        r) # Router mode
            [ -n "$mode" ] && { echo "Error: Only one mode (-w, -d, -r) can be specified"; exit 1; }
            mode="router"
            ;;
        s) # Enter a store_id
            app=$OPTARG
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            Help
            exit 1
            ;;
    esac
done

# Check if a mode was specified
if [ -z "$mode" ]; then
    echo "Error: You must specify one mode (-w, -d, or -r)"
    Help
    exit 1
fi

# Create log filename based on app if provided
if [ -n "$app" ]; then
    log_file=~traffic_${app}.log
    echo "App store ID is set to: $app"
    echo "Log will be saved to: $log_file"
else
    log_file=~/traffic.log
    echo "No app store ID provided"
    echo "Log will be saved to: $log_file"
fi

# Activate MITM virtualenv if it exists
if [ -d "mitm-env" ]; then
    source mitm-env/bin/activate
    echo "MITM virtual environment activated"
fi

# Common setup for non-delete modes
if [ "$mode" != "delete" ]; then
    # Setup based on: https://docs.mitmproxy.org/stable/howto-transparent/
    # Enable IP forwarding
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sysctl -w net.ipv6.conf.all.forwarding=1
    # Disable ICMP redirects
    sudo sysctl -w net.ipv4.conf.all.send_redirects=0
fi

# Mode-specific operations
case $mode in
    "router")
        echo "Setting all proxied router traffic for port 8080"
        sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p udp --dport 80 -j REDIRECT --to-port 8080
        sudo iptables -t nat -A PREROUTING -i wlp0s20f3 -p udp --dport 443 -j REDIRECT --to-port 8080
        sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 80 -j REDIRECT --to-port 8080
        sudo ip6tables -t nat -A PREROUTING -i wlp0s20f3 -p tcp --dport 443 -j REDIRECT --to-port 8080
        echo "Starting mitmproxy in transparent mode"
        mitmproxy --mode transparent --showhost --set block_global=false -w "$log_file" --listen-port 8080
        ;;
        
    "waydroid")
        echo "Waydroid VM traffic routed to port 8080"
        sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
        sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080
        sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
        sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080
        echo "Setting ports 80, 443 to redirect to 8080. Finished"
        echo "Starting mitmweb in transparent mode"
        mitmweb --mode transparent --showhost --set block_global=false -w "$log_file" --listen-port 8080
        ;;
        
    "delete")
        echo "Deleting iptables rules..."
        # IPv4 rules
        sudo iptables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080 2>/dev/null || echo "IPv4 port 80 rule not found or already removed"
        sudo iptables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080 2>/dev/null || echo "IPv4 port 443 rule not found or already removed"
        # IPv6 rules
        sudo ip6tables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080 2>/dev/null || echo "IPv6 port 80 rule not found or already removed"
        sudo ip6tables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080 2>/dev/null || echo "IPv6 port 443 rule not found or already removed"
        # Also try to remove router rules if they exist
        sudo iptables -t nat -D PREROUTING -i wlp0s20f3 -p udp --dport 80 -j REDIRECT --to-port 8080 2>/dev/null
        sudo iptables -t nat -D PREROUTING -i wlp0s20f3 -p udp --dport 443 -j REDIRECT --to-port 8080 2>/dev/null
        sudo ip6tables -t nat -D PREROUTING -i wlp0s20f3 -p tcp --dport 80 -j REDIRECT --to-port 8080 2>/dev/null
        sudo ip6tables -t nat -D PREROUTING -i wlp0s20f3 -p tcp --dport 443 -j REDIRECT --to-port 8080 2>/dev/null
        echo "Removed port redirections. Finished"
        ;;
esac

# Flush iptables if in delete mode
if [ "$mode" = "delete" ]; then
    sudo iptables -t nat -F
    echo "Flushed iptables nat table"
fi

exit 0