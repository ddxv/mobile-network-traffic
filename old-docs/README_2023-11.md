
# 2023: How to Sniff Mobile HTTPs from Apps

Want to see how to do a Man in the Middle attack to see your devices encrypted HTTPS outgoing requests and their responses? This flow is for troubleshooting mobile advertising and checking the security of apps on your phone. To see the previous notes you can check `/old-docs/`.

## Waydroid Setup

[Waydroid](https://docs.waydro.id/usage/install-on-desktops): Android Emulator for Linux

1. Install Waydroid (launch in Wayland for Ubuntu)
2. Use Waydroid to install GAPPS after first launch
3. Install [Magisk](https://github.com/topjohnwu/Magisk) a suite of open source software for customizing Android, supporting devices higher than Android 5.0.
   1. To install Magisk in Waydroid, I used CasualSnek's [Waydroid Script](https://github.com/casualsnek/waydroid_script) helped to do the installation of Magisk into Waydroid
      1. After following CasualSnek's installation into it's own environment run:
         1. `sudo venv/bin/python3 main.py install magisk`
         2. `sudo venv/bin/python3 main.py install libndk` (optional for x86) not related to Magisk, but this will be used later to install ARM APKs which are easier to find than x86 APKs
   2. Once Magisk is installed I enabled Zygisk in the Magisk settings menu, then restarted Wayrdoid
4. Using Magisk, install [MagiskTrustUserCerts](https://github.com/NVISOsecurity/MagiskTrustUserCerts)
   1. This Magisk module will take your user CA certs and move them to system or 'root' CA certifications which more apps will trust.
5. For SSL Unpinning we will install [LSPosed](https://github.com/LSPosed/LSPosed) in Magisk.
   1. As of 2023-09 there appear to be issues with the LSPosed manager app. After installing in Magisk I still did not see the app, so extracted `manager.apk` from the zip file used to install LSPosed.
   2. Installation of this is quite easy, but has a few steps, I found [this YouTube Video helpful to watch](https://www.youtube.com/watch?v=BT77z5HPZ6k)
6. Finally we can install our SSL Unpinning tool [tehcneko.sslunpinning](https://github.com/Xposed-Modules-Repo/io.github.tehcneko.sslunpinning) This LSPosed module helps to unpin apps during runtime.

## MITM Setup

[Install MITM from GitHub](https://github.com/mitmproxy/mitmproxy/blob/main/CONTRIBUTING.md)

1. Clone repo to ~/mitmproxy
2. Setup your virtual env: `python3.11 -m venv ~/mobile-network-traffic/mitm-env`
   1. if needed change location in proxysetup.sh & tmuxlauncher.sh
3. Setup mitm's virtual environment: `pip install -e "[.dev]"`
4. Setup [MITM Transparent Proxy](https://docs.mitmproxy.org/stable/howto-transparent/). These steps, including a launch step, are inside `proxysetup.sh`, so from inside your mitm Python environment, run `proxysetup.sh 8080 -w`.
   1. `proxysetup.sh` runs the following commands, so feel free to run them yourself:

         ```#!/bin/bash
         sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port $port
         sudo iptables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port $port
         sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port $port
         sudo ip6tables -t nat -A PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port $port
         sudo sysctl -w net.ipv4.ip_forward=1
         sudo sysctl -w net.ipv6.conf.all.forwarding=1
         sudo sysctl -w net.ipv4.conf.all.send_redirects=0
         mitmweb --mode transparent --showhost --set block_global=false
         ```

5. While mitm is running, open `https://127.0.0.1:8081/`
6. Check that the proxy is working: Open Waydroid > Browser > and navigate to `http://mitm.it` (note: no https here). This is the a setup page for installing certificate. We don't need to do anything here as we will be installing certificates via Magisk/Lsposed modules. The certificates from mitm do not generally work for what we would like to do.
7. Open your Browser at 8081 and ensure you see the HTTP (not HTTPS) traffic from Waydroid > `http://mitm.it`.

Once everything is installed, shut down and open Waydroid and mitmproxy one more time. After this you should be able to see clear text HTTPS requests from your Waydroid VM inside MITM.

## Checking traffic

This part is easy simply open waydroid, install the target app and browse. Then open your local browser to see the traffic that was captured. A quick launch of the above tools once installed can be found with:
`./proxysetup.sh -w`
OR
`./tmuxlauncher.sh`

## Other Tools

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

### open source, [link]('https://github.com/mitmproxy/mitmproxy/')

I tried this first as it comes with Python library which would make capturing data for later analysis much easier. Mitmproxy has a few different modes, and ultimately I found that `mitmproxy --mode wireguard` which runs via VPN captured a good amount of traffic, but still had target SDK traffic unable to be opened. Mitmproxy has a built in tool to help installing the certificate in Android as a user certificate. This will capture some HTTPs traffic, but for some apps and many SDKs this does not capture their traffic. Traffic can be captured in several ways: CLI tool for analysis of live traffic in memory, CLI dump to file and in memory live in browser of choice.

## Charles Proxy

### free for 30 days, shareware, [link]('https://www.charlesproxy.com/')

I first used Charles nearly 10 years ago, and it doesn't feel like it's changed much, but is actively maintained. When I first started using Charles it was a breeze to use, CA was less of a problem. But as Android changed it also now has the problems of CA needing to be installed, and helps the user by providing it's own signed certificate which can be installed as a user certificate. Charles is a standalone program that you run and as such it does have a fair amount of issues on my linux environment related to it's display sizes.

## Burp Suite - Community Edition

### paid/free, [link]('https://portswigger.net/burp/communitydownload')

Community edition that is free to use. Runs in browser and comes with it's own CA tool.

## Android Certificate Authority

These are the certificates used to sign HTTPS traffic to keep it secure. In Android there are three levels: User, System (root) and App Pinned Certificates. In Android settings you can add a CA which will be considered "user". Apps can choose whether to ignore this certificate. System CAs can only be set by a root user. While a user can install user CA's, apps do not have to use these. CAs can be set by users as root certificates. I believe this must be set regardless of device or VM. The majority of the certificates provided by the proxies don't seem to open a lot of HTTPS traffic. This is likely because Android N (API level 24) [certificate pinning]('https://developer.android.com/training/articles/security-config.html#CertificatePinning') was introduced in 2016 and at this point most SDKs and Apps use this for transferring traffic.

## JustTrustMe

### open source, [link]('https://github.com/Fuzion24/JustTrustMe')

This is installed on a device or emulator. An Xposed addon that can be installed to force apps to use root authorities and prevent them from pinning their own CA.

## apk-mitm

### open source, [link]('https://github.com/shroudedcode/apk-mitm')

This can be installed in a separate linux environment and is used to modify an app's apk before being installed into a VM emultator or phone. It attempts to get around the app's certificate pinning by patching the APK to disable certificate pinning.

## Still can't unpin? Frida and Objection

Blog for [getting around Google pinning using pentesting tools](https://blog.nviso.eu/2019/04/02/circumventing-ssl-pinning-in-obfuscated-apps-with-okhttp/)
[Objection](https://github.com/sensepost/objection)
