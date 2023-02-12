# mobile-network-traffic

Notes and how to for capturing HTTP traffic from mobile devices for security analysis and advertising ops.

## Setup

- [Waydroid](https://docs.waydro.id/usage/install-on-desktops): Android Emulator for Linux 
- [Waydroid Script](https://github.com/casualsnek/waydroid_script) Play services for using playstore and Google Play services
  - currently having issues: [Issue](https://github.com/casualsnek/waydroid_script/issues/68)

## Running after Setup

1. Start Waydroid: `waydroid show-full-ui`
2. Start Proxy:
   1. I was able to solve this by explicitly add /lib/x86_64-linux-gnu/xtables to /etc/ld.so.conf.d/x86_64-linux-gnu.conf and rebooting.
   2.  `sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8081`
   3.  `iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8081`
