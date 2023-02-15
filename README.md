# mobile-network-traffic

## Emulator vs Phone
This is the first question and probably the most dependent on what you want to achieve. Working on a real device gives more space between your device and the proxy which makes things easier. The extra space is costly in other ways. For example, I would prefer to have a single instance running on the computer to collect information, but using a phone is easier but has the physical requirement of a device connected to the network.

## Phone
Physical separation allows for clearer testing. Fully functional device means your input and output work as expected.

## Emulator - Waydroid
Emulator running on the same computer causes more complicated networking to ensure you don't block your own traffic. Troubleshooting is trickier as it's more difficult to easily access parts of the emulator that a phone is easy to access. For example, I spent much more time than I would have expected to move a VPN configuration file from my computer to the virtual machine emulator than I would have ever expected. Adding the same configuration to the phone was a simple QR code scan. 

Emulator running in a virtual machine allows for a future use case of running the whole thing in the cloud without a physical device.


## Proxies
As far as I know, the only way to capture the HTTPS traffic is to use a proxy. This is in the form of an application running on a separate (virtual or physical as mentioned above) device. The hardest part here is the Certificate Authority which signs the HTTPS traffic when it leaves the app. More sophisticated apps, to prevent fraud, do a variety of actions to prevent the user or 3rd parties from capturing the data in each HTTPS request. 

## mitmproxy
## open source, [link]('https://github.com/mitmproxy/mitmproxy/')
I tried this first as it comes with Python library which would make capturing data for later analysis much easier. Mitmproxy has a few different modes, and ultimately I found that `mitmproxy --mode wireguard` which runs via VPN captured a good amount of traffic, but still had target SDK traffic unable to be opened. Mitmproxy has a built in tool to help installing the certificate in Android as a user certificate. This will capture some HTTPs traffic, but for some apps and many SDKs this does not capture their traffic. Traffic can be captured in several ways: CLI tool for analysis of live traffic in memory, CLI dump to file and in memory live in browser of choice.


## Charles Proxy
## free for 30 days, shareware, [link]('https://www.charlesproxy.com/')
I first used Charles nearly 10 years ago, and it doesn't feel like it's changed much, but is actively maintained. When I first started using Charles it was a breeze to use, CA was less of a problem. But as Android changed it also now has the problems of CA needing to be installed, and helps the user by providing it's own signed certificate which can be installed as a user certificate. Charles is a standalone program that you run and as such it does have a fair amount of issues on my linux environment related to it's display sizes. .

## Burp Suite - Community Edition 
## paid/free, [link]('https://portswigger.net/burp/communitydownload')
Community edition that is free to use. Runs in browser and comes with it's own CA tool.


## Android Certificate Authority 
These are the certificates used to sign HTTPS traffic to keep it secure. In Android there are three levels: User, System (root) and App Pinned Certificates. In Android settings you can add a CA which will be considered "user". Apps can choose whether to ignore this certificate. System CAs can only be set by a root user. While a user can install user CA's, apps do not have to use these. CAs can be set by users as root certificates. I believe this must be set regardless of device or VM. The majority of the certificates provided by the proxies don't seem to open a lot of HTTPS traffic. This is likely because Android N (API level 24) [certificate pinning]('https://developer.android.com/training/articles/security-config.html#CertificatePinning') was introduced in 2016 and at this point most SDKs and Apps use this for transferring traffic.

## JustTrustMe
open source, [link]('https://github.com/Fuzion24/JustTrustMe')
This is installed on a device or emulator. An Xposed addon that can be installed to force apps to use root authorities and prevent them from pinning their own CA.

## apk-mitm
open source, [link]('https://github.com/shroudedcode/apk-mitm')
This can be installed in a separate linux environment and is used to modify an app's apk before being installed into a VM emultator or phone. It attempts to get around the app's certificate pinning by patching the APK to disable certificate pinning.


=====================


Notes and how to for capturing HTTP traffic from mobile devices for security analysis and advertising ops.

## VM & mitmproxy Setup Notes

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
