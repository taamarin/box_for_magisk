## WARNING
This project is not responsible for damage to devices or SD cards, or for burned-out SoCs.

**Make sure your configuration files do not create traffic loops, which could cause your phone to restart continuously.**

If you have no idea how to configure this module, you may need applications such as **ClashForAndroid, ClashMetaForAndroid, v2rayNG, Surfboard, SagerNet, AnXray, NekoBox,** etc.

## Installation
- Download the module ZIP from [Releases](https://github.com/taamarin/box_for_magisk/releases) and install it through `Magisk/KernelSU`. During installation, you will be asked whether to download the complete package. You can either download it all at once or download the files separately later. Reboot your device after installation.
- This module supports direct updates through `Magisk/KernelSU Manager`; updates take effect without rebooting the device.

### Kernel Updates
This module includes the following kernels:
- [clash](https://github.com/Dreamacro/clash) (the master branch has been deleted)
- [clash.meta](https://github.com/MetaCubeX/Clash.Meta) (archived; branches have changed, but the content is still available)
- [sing-box](https://github.com/SagerNet/sing-box)
- [v2ray-core](https://github.com/v2fly/v2ray-core)
- [Xray-core](https://github.com/XTLS/Xray-core)

Set `bin_name` in `settings.ini` to the core you want to use: `clash`, `sing-box`, `xray`, `v2fly`, or `hysteria` (the default is `clash`). For Clash, `xclash_option` selects `mihomo` (the default) or `premium`.

Each core runs from `/data/adb/box/bin/${bin_name}`. Its configuration is in the matching directory under `/data/adb/box`: for example, `clash/config.yaml`, `sing-box/config.json`, or `hysteria/config.yaml`. Edit core configurations only while BFM is stopped, and keep their listener ports consistent with `tproxy_port` (`9898`) and `redir_port` (`9797`) in `settings.ini`.

Make sure you are connected to the internet and run the following command to update the kernel file:

```shell
# Update the selected kernel, based on `${bin_name}`.
su -c /data/adb/box/scripts/box.tool upkernel
```

If you selected `clash` or `sing-box`, you may also need to run the following command to install the control panel:

```shell
# Update the control panel for `clash`/`sing-box`.
su -c /data/adb/box/scripts/box.tool upxui
```

Alternatively, you can update everything at once, although this may use more storage than necessary.

```shell
# Update all files, including various kernel types.
su -c /data/adb/box/scripts/box.tool all
```

## Configuration
**The module's core services are collectively referred to as BFM.**
- You can start or stop BFM services in real time by enabling or disabling the module in Magisk/KernelSU Manager; no reboot is required. Starting the services may take a few seconds, while stopping them takes effect immediately.

### Core configuration
- For information about selecting a core with `bin_name`, see **Kernel Updates**.
- Customize each core's configuration file. The service checks it at startup; see `/data/adb/box/run/runs.log` for service logs.
- **Tip:** `clash` and `sing-box` include scripts for transparent proxying. For further configuration, see the official documentation: [Clash](https://github.com/Dreamacro/clash/wiki/configuration) (the master branch has been deleted) and [sing-box](https://sing-box.sagernet.org/configuration/outbound).

### App, process, and interface filters
- By default, BFM proxies traffic from all apps belonging to all Android users.
- App filtering is configured in `/data/adb/box/package.list.cfg`, not `settings.ini`. Set `mode:blacklist` (the default) to proxy all apps except listed packages, or `mode:whitelist` to proxy only listed packages. Add one Android package name per line; an optional user ID can prefix a package (for example, `0:com.example.app`).
- Process filtering uses numeric GIDs in `/data/adb/box/gid.list.cfg`. The `mode` in `package.list.cfg` also determines whether listed GIDs are excluded or included. Android's iptables does not match processes by PID.
- Network-interface filters are in `/data/adb/box/ap.list.cfg`: `allow <prefix>` includes an interface and `ignore <prefix>` excludes it. The default allow-list includes `ap+`, `wlan+`, `rndis+`, `swlan+`, `ncm+`, and `eth+`; add an `ignore` entry to exclude an interface.
- Set `network_mode` in `settings.ini` to `tun` to route TCP and UDP through an auto-routed TUN interface. TUN mode is supported by `clash` and `sing-box`.
> **Note:** If package or GID filters, or an `ignore` interface rule, are configured while Clash uses fake-IP mode, BFM switches to redir-host at startup for supported network modes.

### Change BFM's network mode
- The default is `tproxy`. Set `network_mode` in `settings.ini` to one of these modes:
- `redirect`: redirect TCP; UDP is direct.
- `tproxy`: TPROXY for TCP and UDP.
- `mixed`: redirect TCP and route UDP through TUN.
- `enhance`: redirect TCP and TPROXY UDP.
- `tun`: route TCP and UDP through an auto-routed TUN interface.
- Mode support depends on the selected core: `xray` and `v2fly` require `tproxy`; `hysteria` supports `redirect`, `tproxy`, and `enhance`. `clash` and `sing-box` support modes allowed by their configurations.
- Save the configuration file, then restart the BFM service or reboot the device for the change to take effect.

### Bypass the transparent proxy on Wi-Fi or hotspots
- By default, BFM transparently proxies localhost and hotspot traffic, including USB tethering.
- To bypass the proxy for Wi-Fi connections, add `ignore wlan+` to `/data/adb/box/ap.list.cfg`.
- To proxy hotspot traffic, make sure the relevant interface prefix is included with an `allow` entry in `ap.list.cfg`. MediaTek devices may use **ap+** or **wlan+**.
- If you are unsure which interface name to use, run `ifconfig` in a terminal to identify it.

### Schedule automatic Geo and subscription updates
- Edit `/data/adb/box/settings.ini` and set `run_crontab="true"`.
- Set `update_geo="true"` and/or `update_subscription="true"` to enable the updates you want. The `subs` command documents subscription updates for `clash` only.
- Set `interva_update` to your preferred cron schedule. The default is `0 0,6,12,18 * * *` (four times a day), not `@daily`.
- Optional custom cron tasks can be added to `/data/adb/box/crontab.cfg`.
- Save the changes to the configuration file.
- To start the scheduled job and trigger updates, run:

```shell
  # Start the scheduled job
  su -c /data/adb/box/scripts/box.service cron
```

- This command starts the scheduler. Geo and subscription updates run according to the configured schedule and enabled update options.
- To run an update manually, use `su -c /data/adb/box/scripts/box.tool geox`, `subs`, or `geosub`.

## Start and Stop
### Manual mode
- To manage BFM by running commands manually, create `/data/adb/box/manual`. In this mode, BFM will not start automatically when the device boots, and you cannot start or stop the service through Magisk/KernelSU Manager.
- Changes to system files require appropriate permissions. Make manual changes with care.

### Start and stop the management service
- The BFM service script is `/data/adb/box/scripts/box.service`.

```shell
# Start BFM
  su -c /data/adb/box/scripts/box.service start &&  su -c /data/adb/box/scripts/box.iptables enable

# Stop BFM
  su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

- These commands print log messages in the terminal and write them to the log file.

## Geo database subscriptions and updates
To update the subscription and Geo database at the same time, run:

```shell
  # Update the subscription and Geo database
  su -c /data/adb/box/scripts/box.tool geosub
```

You can also update them separately:

### Update the subscription:

```shell
  # This command will update the subscription data.
  su -c /data/adb/box/scripts/box.tool subs
```

Run these commands whenever you need to update the subscription or Geo database.

### Update the Geo database:

```shell
  # This command will update the Geo database.
  su -c /data/adb/box/scripts/box.tool geox
```

## Additional instructions
- When editing a core configuration file, make sure its TPROXY-related settings match those in `/data/adb/box/settings.ini`.
- If your device has a public IP address, you can add it to the internal network in `/data/adb/box/scripts/box.iptables` to prevent traffic loops.
- BFM service logs are stored in `/data/adb/box/run`.
- Editing these files requires appropriate permissions. Follow the instructions carefully and verify any configuration changes.
- IPv6 support (`ipv6`) is disabled by default. Network-state service control is also disabled by default; its settings can enable service control based on Wi-Fi connection state and optional SSID matching.
- Optional memory, CPU-set, and I/O cgroup limits are disabled by default (`cgroup_memcg`, `cgroup_cpuset`, and `cgroup_blkio`). Configure their related limit values in `settings.ini` before enabling them.

Run the following commands to view additional usage instructions:

```shell
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|memcg|cpuset|blkio|bond0|bond1|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|webroot|all}
  su -c /data/adb/box/scripts/box.service
  # usage: $0 {start|stop|restart|status|cron|kcron}
  su -c /data/adb/box/scripts/box.iptables
  # usage: $0 {enable|disable|renew}
```

## Uninstall
- Uninstalling this module through Magisk/KernelSU Manager removes `/data/adb/service.d/box_service.sh` and the BFM data directory at `/data/adb/box`.
- To remove the remaining BFM files manually, run:

```shell
  # Remove the BFM data directory
  su -c rm -rf /data/adb/box
  su -c rm -rf /data/adb/service.d/box_service.sh
  su -c rm -rf /data/adb/modules/box_for_root
```