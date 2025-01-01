# Box for Root

[![ID](https://img.shields.io/badge/id-blue.svg?style=for-the-badge)](docs/index_id.md) [![EN](https://img.shields.io/badge/en-blue.svg?style=for-the-badge)](docs/index_en.md) [![CN](https://img.shields.io/badge/cn-blue.svg?style=for-the-badge)](docs/index_cn.md)

<h1 align="center">
  <img src="https://github.com/taamarin/box_for_magisk/blob/master/docs/box.svg" alt="BOX" width="200">
  <br>BOX<br>
</h1>
<h4 align="center">Transparent Proxy for Android (Root)</h4>

<div align="center">
  <a href="https://github.com/taamarin/box_for_magisk/releases">
    <img src="https://img.shields.io/github/downloads/taamarin/box_for_magisk/total.svg?style=for-the-badge" alt="Releases">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  </a>
</div>

## Introduction

`Box for Root` (BFR) is a [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), [APatch](https://github.com/bmax121/APatch), module that provides a suite of proxy tools, including `clash`, `sing-box`, `v2ray`, `hysteria` and `xray`. It allows you to configure a transparent proxy on Android devices with root access.

## Features

- Support for multiple proxy tools: `clash`, `sing-box`, `v2ray`, `hysteria`, and `xray`.
- Transparent proxy for Android with root access.
- Seamless integration with Magisk, KernelSU, and APatch.
- Manage proxy services with ease.

## Apk Manager

You can use the **BFR Manager** app (optional) to manage Box for Root on your device.

[Download BFR Manager](https://github.com/taamarin/box.manager)

> **Note**: If you receive continuous notifications, open Magisk Manager, navigate to SuperUser, search for `BoxForRoot`, and disable logs and notifications.

## Module Directory

The core files of the module are stored in the following directories:

- `MODDIR=/data/adb/box`
- `MODLOG=/data/adb/box/run`
- `SETTINGS=/data/adb/box/settings.ini`

> **Note**: Before editing the `settings.ini` file located at `/data/adb/box/settings.ini`, ensure that BFR is turned off to avoid configuration issues.

## Manage Service Start/Stop

The following core services are collectively referred to as **BFR**. By default, the BFR service auto-starts after a system boot. You can manage the service through Magisk/KernelSU Manager App, with the service start taking a few seconds, and stopping it taking effect immediately.

### To start the service:
```bash
su -c /data/adb/box/scripts/box.service start && su -c /data/adb/box/scripts/box.iptables enable
```
### To stop the service:
```bash
su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

## Here are some additional instructions:
- When modifying any of the core configuration files, ensure that the tproxy-related configurations match the definitions in the **/data/adb/box/settings.ini** file.
- If your device has a public IP address, you can add that IP address to the internal network in the **/data/adb/box/scripts/box.iptables** file to prevent loopback traffic.
- The logs for the BFM service can be found in the directory **/data/adb/box/run**.
- Please note that modifying these files requires appropriate permissions. Make sure to carefully follow the instructions and validate any changes made to the configuration files.

You can run the following command to get other related operating instructions:
```bash
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|all}
  su -c /data/adb/box/scripts/box.service
  # usage: $0 {start|stop|restart|status|cron|kcron}
  su -c /data/adb/box/scripts/box.iptables
  # usage: $0 {enable|disable|renew}
```

## Uninstall
Remove the module from `Magisk/KernelSU/APatch Manager` and run the following command to wipe the data:
```bash
su -c rm -rf /data/adb/box
su -c rm -rf /data/adb/service.d/box_service.sh
su -c rm -rf /data/adb/modules/box_for_root
```

## Credits
- [CHIZI-0618/box4magisk](https://github.com/CHIZI-0618/box4magisk) for the original Box for Magisk module.

## License
This project is licensed under the GPL-3.0 license - see the [LICENSE](https://github.com/taamarin/box_for_magisk/blob/master/LICENSE) file for details.
