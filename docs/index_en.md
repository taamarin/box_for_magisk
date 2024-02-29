## WARNING
This project is not responsible for: damaged devices, corrupted SD cards, or burnt SoCs.

**Please ensure that your configuration files do not cause traffic loops, as this can result in your phone continuously restarting.**

If you have no idea how to configure this module, you may need applications such as **ClashForAndroid, ClashMetaForAndroid, v2rayNG, Surfboard, SagerNet, AnXray, NekoBox,** etc.

## Installation
- Download the modules zip package from the [RELEASE](https://github.com/taamarin/box_for_magisk/releases) and install it through `Magisk/KernelSU`. During installation, you will be asked whether to download the complete package. You can choose either **complete download** or **separate download** later, then reboot your device.
- This mod supports direct updates in `Magisk/KernelSU Manager` (updated mods will take effect without rebooting the device).

### Kernel Updates
This module includes the following kernels:
- [clash](https://github.com/Dreamacro/clash)(Delete master branch)
- [clash.meta](https://github.com/MetaCubeX/Clash.Meta)(Archive and change branches, the content is still there)
- [sing-box](https://github.com/SagerNet/sing-box)
- [v2ray-core](https://github.com/v2fly/v2ray-core)
- [Xray-core](https://github.com/XTLS/Xray-core)

The corresponding configuration for the kernel is `${bin_name}`, which can be set to (`clash` | `xray` | `v2ray` | `sing-box`).

Each core operates in the directory `/data/adb/box/bin/${bin_name}`, and the core name is determined by the `bin_name` in the `/data/adb/box/settings.ini` file.

Make sure you are connected to the internet and run the following command to update the kernel file:

```shell
# Update the selected kernel, based on `${bin_name}`.
su -c /data/adb/box/scripts/box.tool upkernel
```

If you are using `clash/sing-box` as the selected kernel, you may also need to run the following command to open the control panel:

```shell
# Update the admin panel for `clash/sing-box`.
su -c /data/adb/box/scripts/box.tool upyacd
```

Alternatively, you can do it all at once (which may consume unnecessary storage space).

```shell
# Update all files, including various kernel types.
su -c /data/adb/box/scripts/box.tool all
```

## Configuration
**The following core services are referred to as BFM:**
- The following core services are collectively referred to as BFM.
- You can enable or disable the module to start or stop the BFM services in real time through the Magisk/KernelSU Manager application without having to reboot the device. Starting the service may take a few seconds, and stopping the service will take effect immediately.

### Core configuration
- For the core configuration of `bin_name`, please refer to the **Kernel Updates** section for the configuration.
- Each core configuration file needs to be customized by the user, and the script will check the validity of the configuration. The results of the check will be stored in the `/data/adb/box/run/runs.log` file.
- Tip: Both `clash` and `sing-box` come with pre-configured scripts for transparent proxy. For further configuration, please refer to the official documentation. Documentation links: [Official Clash Documentation](https://github.com/Dreamacro/clash/wiki/configuration)(Delete master branch), [Official sing-box Documentation](https://sing-box.sagernet.org/configuration/outbound)

### To apply filtering using a blacklist or whitelist, you can follow these general steps:
- By default, BFM provides a proxy for all applications (APP) from all Android users.
- If you want BFM to proxy all applications (APP), except for some specific applications, please open the file `/data/adb/box/settings.ini`, change the value of `proxy_mode` to `blacklist` (default), and add the applications to be excluded to the `packages_list`, for **example: packages_list=("com.termux" "org.telegram.messenger")**.
- If you only want to proxy specific applications (APP), use the `whitelist` mode.
- When the value of `proxy_mode` is set to `TUN`, transparent proxy will not function, and only the corresponding kernel will start supporting **TUN**. Currently, **only clash and sing-box are available**.
> **Notes: If Clash is used, the blacklist and whitelist will not apply in fake-ip mode**

### Transparent Proxies for Specific Processes
- BFM by default performs a transparent proxy for all processes.
- If you want BFM to proxy for all processes except specific ones, open the file `/data/adb/box/settings.ini`, change the value of `proxy_mode` to `blacklist` (the default value), then add GID elements to the `gid_list` array, with GID separated by spaces. This will result in processes with the corresponding GID **not being proxied**.

- If you wish to perform transparent proxying only for specific processes, open the file `/data/adb/box/settings.ini`, change the value of `proxy_mode` to `whitelist`, then add GID elements to the `gid_list` array, with GID separated by spaces. This will result in only processes with the corresponding GID being **proxied**.

> Tips: Since Android iptables does not support extension PID matching, process matching by Box is done via GID matching indirectly. On Android you can use busybox setuidgid command to start a specific process with a specific UID, any GID.

### Change the proxy mode in BFM, follow these steps:
- BFM utilizes TPROXY to transparently proxy TCP+UDP traffic (default). If it is detected that the device does not support TPROXY, open the file **/data/adb/box/settings.ini** and change `network_mode="redirect"` to `redirect`, which only uses TCP proxying.
- Open the file `/data/adb/box/settings.ini` and change the value of `network_mode` to **redirect, tproxy, or mixed**.
- redirect: Use redirect mode for TCP proxying.
- tproxy: Use tproxy mode for TCP + UDP proxying.
- mixed: Use redirect mode for TCP and tun mode for UDP proxying
- Make sure to save the changes to the configuration file and restart the BFM service or the device for the modifications to take effect.

### bypass transparent proxy when connecting to Wi-Fi or hotspot in BFM
- BFM transparently proxies localhost and hotspot (including USB tethering) by default.
- Open the file **/data/adb/box/settings.ini** using a text editor, Find the `ignore_out_list` parameter in the file, update the value of ignore_out_list by adding `wlan+` to it. This will bypass transparent proxy for Wi-Fi connections.
- If you want to enable proxying for hotspots, follow these additional steps:
  - Find the `ap_list` parameter in the settings.ini file.
  - Update the value of `ap_list` by adding `wlan+`. This will enable proxying for hotspots
- maybe **ap+ / wlan+** for Mediatek devices
- If you are unsure about the name of the access point (AP), you can use the **ifconfig** command in the Terminal to determine the AP name.

### To enable Cron Job for automatic updates of Geo and Subs according to a schedule.
- Open the file **/data/adb/box/settings.ini** using a text editor.
- Locate the parameter `run_crontab` in the file.
- Change the value of `run_crontab` to true.
- Set the `interval_update` parameter according to your desired schedule. The default value is **@daily**, which means the updates will occur once daily. You can customize it to your preferred interval using cron syntax.
- Save the changes to the configuration file.
- To execute the Cron Job and trigger the updates, follow these steps:

```shell
  # run command
  su -c /data/adb/box/scripts/box.service cron
```

- This command will execute the Cron Job and initiate the updates for Geo and Subs based on the configured schedule.
- Ensure that you have the necessary permissions to execute the command. The updates will automatically occur according to the specified schedule once you have enabled the Cron Job and executed the command.

## Start and Stop
### manual mode
- If you want to have full control over BFM by running commands manually, you can create a new file named **/data/adb/box/manual**. In this case, the BFM service will not start automatically when your device is powered on, and you will not be able to control the start or stop of the service through the Magisk/KernelSU Manager application.
- By creating the **/data/adb/box/manual** file, you take manual control over BFM and can execute commands as needed to manage its operations. Please note that modifying system files requires appropriate permissions, and any manual changes should be made with caution.

### Start and stop the management service
- The BFM service script is /data/adb/box/scripts/box.service

```shell
# Start BFM
  su -c /data/adb/box/scripts/box.service start &&  su -c /data/adb/box/scripts/box.iptables enable

# Stop BFM
  su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

- When executing these commands, the Terminal will print logs simultaneously and output them to the log file.

## Geo database subscriptions and updates
To update both the subscription and the Geo database simultaneously, you can use the following command:

```shell
  # This command will update both the subscription and the Geo database at the same time.
  su -c /data/adb/box/scripts/box.tool geosub
```

Alternatively, if you prefer to update them separately, you can use the following commands:

### Update the subscription:

```shell
  # This command will update the subscription data.
  su -c /data/adb/box/scripts/box.tool subs
```

By running these commands, you will be able to update the subscription and the Geo database as needed.

### Update the Geo database:

```shell
  # This command will update the Geo database.
  su -c /data/adb/box/scripts/box.tool geox
```

## Here are some additional instructions:
- When modifying any of the core configuration files, ensure that the tproxy-related configurations match the definitions in the **/data/adb/box/settings.ini** file.
- If your device has a public IP address, you can add that IP address to the internal network in the **/data/adb/box/scripts/box.iptables** file to prevent loopback traffic.
- The logs for the BFM service can be found in the directory **/data/adb/box/run**.
- Please note that modifying these files requires appropriate permissions. Make sure to carefully follow the instructions and validate any changes made to the configuration files.

You can run the following command to get other related operating instructions:

```shell
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|bond0|bond1|memcg|cpuset|blkio|geosub|geox|subs|upkernel|upyacd|upyq|upcurl|port|reload|all}
  su -c /data/adb/box/scripts/box.service
  # usage: $0 {start|stop|restart|status|cron|kcron}
  su -c /data/adb/box/scripts/box.iptables
  # usage: $0 {enable|disable|renew}
```

## uninstall
- An install that removes this module from Magisk/KernelSU Manager, will remove the file **/data/adb/service.d/box_service.sh** and the BFM data directory at **/data/adb/box**.
- Remove the BFM data directory by running the following command:

```shell
  # This command will delete the BFM data directory located at /data/adb/box.
  su -c rm -rf /data/adb/box
  su -c rm -rf /data/adb/service.d/box_service.sh
  su -c rm -rf /data/adb/modules/box_for_root
```