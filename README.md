# Box for Root

[![ID](https://img.shields.io/badge/id-blue.svg?style=for-the-badge)](docs/index_id.md) [![EN](https://img.shields.io/badge/en-blue.svg?style=for-the-badge)](docs/index_en.md) [![ZH](https://img.shields.io/badge/zh-blue.svg?style=for-the-badge)](docs/index_zh.md)

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
`Box for Root` (BFR) is a [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), and [APatch](https://github.com/bmax121/APatch) module for running transparent proxies on rooted Android devices. It supports Clash/Mihomo, `sing-box`, `v2fly`, `xray`, and `hysteria`.

## Features
- Multiple proxy cores and network modes, with configurable app and process filtering.
- Automatic service start after boot and service control from the manager or command line.
- Optional network-state controls, scheduled updates, and cgroup resource limits.

## Installation
Download a release ZIP and install it from the Magisk, KernelSU, or APatch manager. Recovery installation is not supported. KernelSU versions below version code `10670` are not supported.

The installer offers interactive options for download acceleration and proxy-core binaries. Connect to the internet if you want it to download binaries during installation. Reboot after installation. Existing data under `/data/adb/box` is backed up and restored during an update; the installer also offers to restore supported settings from the previous `settings.ini`.

## Apk Manager
You can use the **BFR Manager** app (optional) to manage Box for Root on your device.
[Download BFR Manager](https://t.me/nothing_taamarin)
> ⚠️ If you receive continuous notifications, open Magisk Manager, navigate to SuperUser, search for `BoxForRoot`, and disable logs and notifications.

## Files and Configuration
- Module files: `/data/adb/modules/box_for_root`
- Persistent data, scripts, and proxy-core configurations: `/data/adb/box`
- Main settings: `/data/adb/box/settings.ini`
- Runtime logs and state: `/data/adb/box/run`

The selected core is set by `bin_name` in `settings.ini` (`clash`, `sing-box`, `xray`, `v2fly`, or `hysteria`). Its executable is stored in `/data/adb/box/bin`; its configuration is in the matching directory under `/data/adb/box` (for example, `/data/adb/box/clash/config.yaml`). Edit configuration files only while BFR is stopped, and keep their proxy listener ports consistent with `settings.ini`.

### Network modes
Set `network_mode` in `settings.ini` to one of the following:

| Mode | Traffic handling |
| --- | --- |
| `redirect` | Redirect TCP; UDP is direct |
| `tproxy` | TProxy for TCP and UDP |
| `mixed` | Redirect TCP and route UDP through TUN |
| `enhance` | Redirect TCP and TProxy UDP |
| `tun` | Route TCP and UDP through an auto-routed TUN interface |

Supported modes depend on the selected core. `xray` and `v2fly` use `tproxy`; `hysteria` supports `redirect`, `tproxy`, and `enhance`. `clash` and `sing-box` support the modes their configurations provide.

### App, process, and interface filters
- `/data/adb/box/package.list.cfg` controls app filtering. Choose `mode:blacklist` to proxy all apps except listed packages, or `mode:whitelist` to proxy only listed packages. Entries use Android package names; a user ID can optionally prefix a package (for example, `0:com.example.app`).
- `/data/adb/box/gid.list.cfg` contains numeric group IDs (GIDs) for process filtering. The blacklist/whitelist mode in `package.list.cfg` also determines whether listed GIDs are excluded or included.
- `/data/adb/box/ap.list.cfg` controls network interfaces. `allow <prefix>` includes an interface and `ignore <prefix>` excludes one; the file contains examples and default interface prefixes.

Clash app filters do not apply in fake-IP mode.

### Optional settings
The default settings keep these features disabled. To enable them, edit `settings.ini` while BFR is stopped:
- Network-state service control: `enable_network_service_control`, `use_module_on_wifi_disconnect`, `use_module_on_wifi`, and the SSID matching options.
- Resource limits: `cgroup_memcg` / `memcg_limit`, `cgroup_cpuset` / `allow_cpu`, and `cgroup_blkio` / `weight`.
- IPv6 support: `ipv6`.
- Scheduled Geo and subscription updates: enable `run_crontab` and the relevant update options, then set the `interva_update` schedule.

## Manage Service Start/Stop
By default, BFR starts after boot. Enable or disable the module in the manager to start or stop its service. You can also use the installed `/dev/sbfr` command:

```bash
su -c /dev/sbfr start
su -c /dev/sbfr stop
su -c /dev/sbfr help
```

The equivalent direct commands are:
```bash
su -c /data/adb/box/scripts/box.service start && su -c /data/adb/box/scripts/box.iptables enable
su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

To prevent automatic startup and manager-based service control, create `/data/adb/box/manual`. In manual mode, start and stop BFR using the commands above.

### Maintenance commands
Run `box.tool help` to see all available commands:
```bash
su -c /data/adb/box/scripts/box.tool help
```

Commands include `check`, `geosub`, `geox`, `subs`, `upkernel`, `upxui`, `upyq`, `upcurl`, `reload`, `webroot`, `memcg`, `cpuset`, `blkio`, `bond0`, `bond1`, and `all`. `subs` supports Clash configurations. Service commands are `start`, `stop`, `restart`, `status`, `cron`, and `kcron`; firewall commands are `enable`, `disable`, and `renew`.

Logs are stored in `/data/adb/box/run`. For more detailed configuration guidance, see the [English guide](docs/index_en.md), [Indonesian guide](docs/index_id.md), and [Chinese guide](docs/index_zh.md).

## Uninstall
Uninstall the module from the Magisk, KernelSU, or APatch manager. The uninstall script removes `/data/adb/box` and its service startup script. If data or service files remain, remove them manually:
```bash
su -c rm -rf /data/adb/box
su -c rm -rf /data/adb/service.d/box_service.sh
su -c rm -rf /data/adb/ksu/service.d/box_service.sh
su -c rm -rf /data/adb/modules/box_for_root
```

## Credits
- [CHIZI-0618/box4magisk](https://github.com/CHIZI-0618/box4magisk) for the original Box for Magisk module.

## License
This project is licensed under the GPL-3.0 license - see the [LICENSE](https://github.com/taamarin/box_for_magisk/blob/master/LICENSE) file for details.
