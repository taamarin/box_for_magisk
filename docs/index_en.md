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

Set `${bin_name}` to the name of the core you want to use: `clash`, `xray`, `v2ray`, or `sing-box`.

Each core runs from `/data/adb/box/bin/${bin_name}`. The core name is set by `bin_name` in `/data/adb/box/settings.ini`.

Make sure you are connected to the internet and run the following command to update the kernel file:

```shell
# Update the selected kernel, based on `${bin_name}`.
su -c /data/adb/box/scripts/box.tool upkernel
```

If you selected `clash` or `sing-box`, you may also need to run the following command to install the control panel:

```shell
# Update the admin panel for `clash/sing-box`.
su -c /data/adb/box/scripts/box.tool upyacd
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
- Customize each core's configuration file. The script checks whether the configuration is valid and saves the results to `/data/adb/box/run/runs.log`.
- **Tip:** `clash` and `sing-box` include scripts for transparent proxying. For further configuration, see the official documentation: [Clash](https://github.com/Dreamacro/clash/wiki/configuration) (the master branch has been deleted) and [sing-box](https://sing-box.sagernet.org/configuration/outbound).

### Filter apps with a blacklist or whitelist
- By default, BFM proxies traffic from all apps belonging to all Android users.
- To proxy all apps except specific ones, open `/data/adb/box/settings.ini`, set `proxy_mode` to `blacklist` (the default), and add the apps to exclude to `packages_list`. For example: **packages_list=("com.termux" "org.telegram.messenger")**.
- To proxy only specific apps, use `whitelist` mode.
- When `proxy_mode` is set to `TUN`, transparent proxying is disabled and only the selected core's TUN mode is used. Currently, **only clash and sing-box support this mode**.
> **Note:** When using Clash, the blacklist and whitelist do not apply in fake-IP mode.

### Transparent Proxies for Specific Processes
- By default, BFM transparently proxies traffic from all processes.
- To proxy traffic from all processes except specific ones, open `/data/adb/box/settings.ini`, set `proxy_mode` to `blacklist` (the default), and add the relevant GIDs to the `gid_list` array, separated by spaces. Processes with those GIDs **will not be proxied**.

- To proxy traffic only from specific processes, set `proxy_mode` to `whitelist` and add the relevant GIDs to the `gid_list` array, separated by spaces. Only processes with those GIDs will be **proxied**.

> **Tip:** Android's iptables does not support PID matching extensions, so Box matches processes indirectly by GID. On Android, you can use the BusyBox `setuidgid` command to start a process with a specific UID and any GID.

### Change BFM's network mode
- By default, BFM uses TPROXY to transparently proxy TCP and UDP traffic. If your device does not support TPROXY, open `/data/adb/box/settings.ini` and set `network_mode` to `redirect`, which proxies TCP only.
- You can set `network_mode` to `redirect`, `tproxy`, or `mixed`:
- `redirect`: proxies TCP using redirect mode.
- `tproxy`: proxies TCP and UDP using TPROXY.
- `mixed`: proxies TCP using redirect and UDP using TUN.
- Save the configuration file, then restart the BFM service or reboot the device for the change to take effect.

### Bypass the transparent proxy on Wi-Fi or hotspots
- By default, BFM transparently proxies localhost and hotspot traffic, including USB tethering.
- To bypass the proxy for Wi-Fi connections, open `/data/adb/box/settings.ini` in a text editor, find `ignore_out_list`, and add `wlan+` to its value.
- To proxy hotspot traffic, find `ap_list` in `settings.ini` and add `wlan+` to its value. MediaTek devices may use **ap+** or **wlan+**.
- If you are unsure which interface name to use, run `ifconfig` in a terminal to identify it.

### Schedule automatic Geo and subscription updates
- Open the file **/data/adb/box/settings.ini** using a text editor.
- Find the `run_crontab` parameter.
- Change the value of `run_crontab` to true.
- Set `interval_update` to your preferred schedule. The default value, **@daily**, runs updates once a day. You can choose another interval using cron syntax.
- Save the changes to the configuration file.
- To start the scheduled job and trigger updates, run:

```shell
  # Start the scheduled job
  su -c /data/adb/box/scripts/box.service cron
```

- This command starts the scheduled job and updates Geo data and subscriptions according to the configured schedule.
- Make sure you have permission to run the command. Once enabled and started, updates will run automatically on the configured schedule.

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

Run the following commands to view additional usage instructions:

```shell
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|bond0|bond1|memcg|cpuset|blkio|geosub|geox|subs|upkernel|upyacd|upyq|upcurl|port|reload|all}
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