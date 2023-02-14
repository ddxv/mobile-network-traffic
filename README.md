# mobile-network-traffic

Notes and how to for capturing HTTP traffic from mobile devices for security analysis and advertising ops.

## Setup Docs

- [Waydroid](https://docs.waydro.id/usage/install-on-desktops): Android Emulator for Linux
- [Waydroid Transparent Proxy](https://docs.mitmproxy.org/stable/howto-transparent/)
- [Waydroid Script](https://github.com/casualsnek/waydroid_script) Play services for using playstore and Google Play services
  - currently having issues: [Issue](https://github.com/casualsnek/waydroid_script/issues/68)

## Startup after Installation (only working for browsers)

1. Ensure iptables is working. I was able to solve this by explicitly add `/lib/x86_64-linux-gnu/xtables` to `/etc/ld.so.conf.d/x86_64-linux-gnu.conf` and rebooting. This was reported working for Debian 11 and Ubuntu 20+
2. Run `./proxysetup.sh 8080 -s` for waydroid. Use `-l` if mitm for other device
3. Start Waydroid service: `waydroid session start`
4. Start Waydroid UI: `waydroid show-full-ui` and check internet
   1. If internet can't connect try `sudo waydroid shell` and check `ip link` and `ip addr` to see if firewall blocking.
   2. If needed disable firewall by `sudo ufw disable` or open udp67? More info at: [ArchWiki Waydroid Networking](https://wiki.archlinux.org/title/Waydroid#Network)
   3. Install certs (first time per device)
      1. On target device, navigate to `mitm.it`
      2. follow instructions on mitm.it after downloading
         1. eg: `mv mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy.crt`
      3. NOTE: Firefox has SEPARTE certs from OS certs

NOTE: `proxysetup.sh` runs `sudo iptables -t nat -F` at end to clear out iptables, which can cause your connection to be blocked. But be warned, this will clear all custom iptables on your nat table.

## Startup for Apps

Let's try using (mitmproxy wireguard mode)[https://mitmproxy.org/posts/wireguard-mode/].

Run by `mitmweb --mode wireguard`
