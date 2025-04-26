# 2025: How to Sniff Mobile HTTPs from Apps

This README is a recipe for setting up a man in the middle attack to see your emulated device's encrypted HTTPS outgoing requests and their responses in clear text. This is useful for security, journalism and of course troubleshooting mobile advertising. To see previous notes you can check `/old-docs/`.

## Waydroid Setup

[Waydroid](https://docs.waydro.id/usage/install-on-desktops): Android Emulator for Linux



1. Install Waydroid (requires Wayland)
2. Init: `waydroid init -s GAPPS`
3. Launch Waydroid and select to install GAPPS by setting these values:
  - System OTA: https://ota.waydro.id/system
  - Vendor OTA: https://ota.waydro.id/vendor

### Troubleshooting Waydroid

First, you can see the errors by:
```sh
sudo waydroid shell
#now inside waydroid shell
logcat
```

To install the errors you can 

### Installing APK (install fails with no message)

This is likely caused by Waydroid running on x86 like AMD or Intel CPU. Use CasualSnek's [Waydroid Script](https://github.com/casualsnek/waydroid_script) helped to do the installation of Magisk into Waydroid
      1. After following CasualSnek's installation into it's own environment run:
        2. `sudo venv/bin/python3 main.py install libndk`  - Native Android libraries
        2. `sudo venv/bin/python3 main.py install libhoudini`  - ARM translation layer

### Waydroid doesn't open (after already having been opened earlier)
Sometimes Just `sudo systemctl restart waydroid-container.service` works but other times I need to do the full:
```sh
sudo waydroid session stop
sudo waydroid container stop
sudo systemctl stop waydroid-container.service
sudo systemctl start waydroid-container.service
```

### Waydroid has no internet connection

#### Firewall
Allow Waydroid through firewall https://docs.waydro.id/debugging/networking-issues

#### Interaction with pre-existing Docker network interface
Interaction with an existing docker network, might need to delete or remove docker0 https://wiki.archlinux.org/title/Waydroid

#### Issues with Waydroid on Fedora nftables
https://github.com/waydroid/waydroid/issues/509
`/usr/lib/waydroid/data/scripts/waydroid-net.sh`
```sh
LXC_USE_NFT="false"
```

#### Waydroid no internet because MITM is not running
This only applies if you've already run `./proxysetup.sh` or set the `iptable` forwarding rules. Once you set this, waydroid0 is forwarding all traffic to your local 8080 `mitm-proxy` port. If you want waydroid internet without running mitm you can delete the rules forwarding waydroid traffic to mitm. Of course, when you want to see traffic in mitm, you'll need to set these rules again with `./proxysetup.sh`
```sh
# IPv4 rules
sudo iptables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo iptables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080

# IPv6 rules
sudo ip6tables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 80 -j REDIRECT --to-port 8080
sudo ip6tables -t nat -D PREROUTING -i waydroid0 -p tcp --dport 443 -j REDIRECT --to-port 8080
```

## Install Magisk

While in the past few years I had been using CasualSnek's [Waydroid Script](https://github.com/casualsnek/waydroid_script) in 2025 I was having quite a few issues with this. Specifically I couldn't seem to reliably set the Zygisk option in Magisk.

So looking around on the Waydroid Telegram I found [mistrmochov/magiskWaydroid](https://github.com/mistrmochov/magiskWaydroid) which seems to have oneshotted my issue by just following the install instructions:
```sh
git clone https://github.com/mistrmochov/magiskWaydroid
cd magiskWaydroid
./magisk install --modules # This option will install Magisk with lsposed and magisk builtinbusybox modules
```

The awesome thing about mistrmochov is that it installs lsposed as well, which is a later requirment anyways.

## Install Magisk Modules
For each Module you'll need to get the .zip file from the GitHub Releases page onto waydroid, for example, using a browser. 
Recommended use Firefox one, the default browser seems to default downloading `.zip` to an empty `.bin` from GitHub repos. Also it's quite difficult to use.

To install Firefox get an APK:
```sh
waydroid app install ./Downloads/justdownloadedfirefox.apk
```


### Magisk Module(s)
1. Visit URL in your waydroid browser, download .zip from releases
2. Open Magisk
3. Press Modules
4. Select Install from Storage > Select the .zip file you download

1. [pwnlogs/cert-fixer](https://github.com/pwnlogs/cert-fixer) Another new option, this replaced the previous NVISOsecurity/MagiskTrustUserCerts module which I couldn't get working this year. This Magisk module will take your user CA certs and move them to system or 'root' CA certifications which more apps will then trust.


## MITM Setup

[Download MITM Binary](https://mitmproxy.org/) or [Install MITM from Source/GitHub](https://github.com/mitmproxy/mitmproxy/blob/main/CONTRIBUTING.md)

### From source
1. Clone repo to ~/mitmproxy
2. Setup your virtual env: `python3.11 -m venv ~/mobile-network-traffic/mitm-env`
   1. if needed change location in proxysetup.sh & tmuxlauncher.sh
3. Setup mitm's virtual environment: `pip install -e ".[dev]"`


### From binary
1. Download
2. Unzip: `tar -xf archive.tar.gz`
3. Move files to `mv mitmweb mitmdump mitmproxy /usr/local/bin/` or other suitable place
4. `chmod +x /usr/local/bin/mitmweb` and other files

### Setup Transparent Proxy
4. Setup [MITM Transparent Proxy](https://docs.mitmproxy.org/stable/howto-transparent/). These steps, including a launch step, are inside `proxysetup.sh`, so from inside your mitm Python environment, run `proxysetup.sh 8080 -w`.
   1. `proxysetup.sh` runs the following commands, so feel free to run them yourself:

         ```sh
         #!/bin/bash
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

### Finally, start MITM
If not yet started, start via:
`proxysetup.sh -w` OR `mitmweb --mode transparent --showhost --set block_global=false`



## Checking traffic

Open your local browser `http://127.0.0.1:8081/#/flows` and then on waydroid open the target app to see live traffic. A quick launch of the above tools once installed can be found with:
`./proxysetup.sh -w`
OR
`./tmuxlauncher.sh`



## Play Certification

Unfortunately, Google continues to make it difficult to see the data leaving your device. The newest issue is that Google now requires your device to be signed by a manufacturer, which for Waydroid definitely is difficult. This seems like it's getting tied to Google services, so many apps now will show an error if you do not have Play Certification. 

There is a flow to fix this, but I struggled to get it working, as it takes a fair amount of time to be successful, has a captcha and needs to be done all over if you stop the Waydroid Container.

https://docs.waydro.id/faq/google-play-certification

    Run `sudo waydroid shell`

    Inside the shell run this command:
      ```
      ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"
      ```




## OTHER OPTIONS:

https://github.com/mitmproxy/android-unpinner This looks great, creates an unpinned APK but can't work in waydroid?



### Charles Proxy

free for 30 days, shareware, [link]('https://www.charlesproxy.com/')

I first used Charles nearly 10 years ago, and it doesn't feel like it's changed much, but is actively maintained. When I first started using Charles it was a breeze to use, CA was less of a problem. But as Android changed it also now has the problems of CA needing to be installed, and helps the user by providing it's own signed certificate which can be installed as a user certificate. Charles is a standalone program that you run and as such it does have a fair amount of issues on my linux environment related to it's display sizes.

### Burp Suite - Community Edition

paid/free, [link]('https://portswigger.net/burp/communitydownload')

Community edition that is free to use. Runs in browser and comes with it's own CA tool.

### Android Certificate Authority

These are the certificates used to sign HTTPS traffic to keep it secure. In Android there are three levels: User, System (root) and App Pinned Certificates. In Android settings you can add a CA which will be considered "user". Apps can choose whether to ignore this certificate. System CAs can only be set by a root user. While a user can install user CA's, apps do not have to use these. CAs can be set by users as root certificates. I believe this must be set regardless of device or VM. The majority of the certificates provided by the proxies don't seem to open a lot of HTTPS traffic. This is likely because Android N (API level 24) [certificate pinning]('https://developer.android.com/training/articles/security-config.html#CertificatePinning') was introduced in 2016 and at this point most SDKs and Apps use this for transferring traffic.

### JustTrustMe

open source, [link]('https://github.com/Fuzion24/JustTrustMe')

This is installed on a device or emulator. An Xposed addon that can be installed to force apps to use root authorities and prevent them from pinning their own CA.

### apk-mitm

open source, [link]('https://github.com/shroudedcode/apk-mitm')

This can be installed in a separate linux environment and is used to modify an app's apk before being installed into a VM emultator or phone. It attempts to get around the app's certificate pinning by patching the APK to disable certificate pinning.

## Still can't unpin? Frida and Objection

Blog for [getting around Google pinning using pentesting tools](https://blog.nviso.eu/2019/04/02/circumventing-ssl-pinning-in-obfuscated-apps-with-okhttp/)
[Objection](https://github.com/sensepost/objection)
