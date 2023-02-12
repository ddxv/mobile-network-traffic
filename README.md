# mobile-network-traffic

Notes and how to for capturing HTTP traffic from mobile devices for security analysis and advertising ops.

## Setup

- [Waydroid](https://docs.waydro.id/usage/install-on-desktops): Android Emulator for Linux
- [Waydroid Script](https://github.com/casualsnek/waydroid_script) Play services for using playstore and Google Play services
  - currently having issues: [Issue](https://github.com/casualsnek/waydroid_script/issues/68)

## Running after Setup

1. Start Waydroid: `waydroid show-full-ui`
2. Start Proxy:
   1. Run setuproxy.sh
   2. I was able to solve this by explicitly add /lib/x86_64-linux-gnu/xtables to /etc/ld.so.conf.d/x86_64-linux-gnu.conf and rebooting.
   3. navigate in FF or device to mitm.it
      1. Install certs:
      2. follow instructions on mitm.it after downloading eg: `mv mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy.crt`
      3. NOTE: Firefox has SEPARTE certs from OS certs

To flush all iptables in nat: `sudo iptables -t nat -F`
