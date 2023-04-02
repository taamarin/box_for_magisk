## WARNING
This project is not responsible for: damaged devices, damaged SD cards, or burnt SoCs.

**Make sure your configuration file does not cause traffic loopback, otherwise it may cause your phone to restart endlessly.**

If you really don't know how to configure this module, you may need an application like **ClashForAndroid, ClashMetaForAndroid, v2rayNG, Surfboard, SagerNet, AnXray, NekoBox** etc.

## Installation
- Download the module zip package from RELEASE and install it via MAGISK. Then reboot.
- Make sure you are connected to the internet, and execute the following command to download binaries etc:
```shell
  su -c /data/adb/box/scripts/box.tool upyacd
  su -c /data/adb/box/scripts/box.tool subgeo
  su -c /data/adb/box/scripts/box.tool upcore
```

- Support for the next online module update in Magisk Manager (updating the module will take effect without rebooting).

### Notes
This module includes:
 - [clash](https://github.com/Dreamacro/clash)、
 - [clash.meta](https://github.com/MetaCubeX/Clash.Meta)、[sing-box](https://github.com/SagerNet/sing-box)、
 - [v2ray-core](https://github.com/v2fly/v2ray-core)、
 - [Xray-core](https://github.com/XTLS/Xray-core).
 - [sing-box]().

After installing the module, download the appropriate core file for your device's architecture and place it in the /data/adb/box/bin/ directory, or execute:

```shell
su -c /data/adb/box/scripts/box.tool upcore
```

## konfigurasi
```yaml
# list of available kernel binaries
bin_list=("clash" "sing-box" "xray" "v2fly")
# select the client to use : clash / sing-box / xray / v2fly
bin_name="good day"
```

- Each core works in the directory `/data/adb/box/bin/${bin_name}`, and the core name is determined by `bin_name` in the file `BFM`.
- Each core configuration file needs to be customized by the user, and the scripts will check the validity of the configuration, and the check result will be saved in the file `/data/adb/box/run/runs.log.`
- Tip: `clash` and `sing-box` come with ready-to-work default configurations with the transparent proxy script. For further configuration, see the official documentation. Address:  [dokumen clash](https://github.com/Dreamacro/clash/wiki/configuration), [dokumen sing-box](https://sing-box.sagernet.org/configuration/outbound/)


## Instructions
### Conventional method (standard & recommended method)

#### Start and stop management services
**Layanan inti berikut secara kolektif disebut sebagai `BFM`**
- The following core services are collectively referred to as `BFM`
- You can enable or disable the module through the Magisk Manager application **in real time** to start or stop the `BFM` service, **without restarting the device**. Starting the service may take a few seconds, and stopping the service can take effect immediately.

#### Select applications (APPs) that require proxy
- `BFM` defaults to proxying all applications (APPs) for all Android users.
- If you want `BFM` to proxy all applications (APP), except for certain ones, please open the file `/data/adb/box/settings.ini` and change the value of `proxy_mode` to `blacklist` (default), add packages to `packages_list`, for example: `packages_list=("com.termux" "org.telegram.messenger")`
- Use `whitelist` if you only want to proxy certain applications (APP).
- **blacklist** / **whitelist** does not work on `Clash fake-ip`
- When the value of `proxy_mode` is `tun`, transparent proxy will not work, only the corresponding kernel will start, which can be used to support TUN(`auto-route`), currently only `clash` and `sing-box` are available.

### Advanced usage

#### Changing proxy mode
- `BFM` uses `TPROXY` to transparently proxy TCP + UDP (default). If it detects that the device does not support TPROXY, open `/data/adb/box/settings.ini` and change `network_mode="redirect"` to use `redirect` for TCP proxy only.
- Open the file `/data/adb/box/settings.ini`, change the value of `network_mode` to `redirect`, `tproxy`, or `mixed`.
- redirect: `redirec TCP only.`
- tproxy: `tproxy TCP + UDP.`
- mixed: `redirec TCP + tun UDP.`

#### Bypass transparent proxy when connecting to Wi-Fi or hotspot
- `BFM` transparently proxies localhost and hotspot (including USB tethering) by default.
- Open the file `/data/adb/box/settings.ini`, modify `ignore_out_list` and add `wlan+`, then transparent proxy will bypass wlan, and hotspot won't connect to the proxy.
- Open the file `/data/adb/box/settings.ini`, modify `ap_list` and add `wlan+`. `BFM` will proxy the hotspot (for MediaTek devices, it may be ap+ / wlan+).
- Use the `ifconfig/ipconfig` command in the terminal to find out the name of the AP.
```bash
~ 06.12 PM ➤ #ifconfig
wlan1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.x.x.x  netmask 255.255.255.0  broadcast 192.168.43.255
        unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 3000  (UNSPEC)   
```

#### Geo dan Subscription
```yaml
# Set update interval using cron, for more information: https://crontab.guru/
crontab_sec='false'
update_interval="0 12 */3 * *" # updates will run at 12 noon every three days. 
# Update sub&geo
# execute manual, Type "su -c /data/adb/box/scripts/box.tool subgeo" to update
auto_update_geox="false"
# Only update clash subscription URL
auto_update_subscription="false"
subscription_url=""
```

- Located at `/data/adb/box/settings.ini`, the configuration facilitates an automatic update of the geo sab subscription every 3 days upon activation. Customization of the `subscription_url` and `update_interval` variables is possible, and executing the process manually can be achieved using the following command: `su -c /data/adb/box/scripts/box.tool subgeo`.

#### Enter manual mode
- If you want to fully control `BFM` by running commands, just create a new file `/data/adb/box/manual`. In this case, the `BFM` service will not start automatically when your device is turned on, and you also cannot set the start or stop of the service through the Magisk Manager app.

#### Starting and stopping the BFM service
The `BFM` service script is /data/adb/box/scripts/box.service
- Start `BFM`:
```shell
  su -c /data/adb/box/scripts/box.service start
```
- Stop `BFM`:
```shell
  su -c /data/adb/box/scripts/box.service stop
```

- The terminal will print logs and output them to a log file simultaneously.

#### Manage whether transparent proxy is enabled
- The transparent proxy script is `/data/adb/box/scripts/box.iptables`
- Enable transparent proxy:
```shell
  su -c /data/adb/box/scripts/box.iptables enable
```

- Disable transparent proxy:
```shell
  su -c /data/adb/box/scripts/box.iptables disable
```

## Other instructions
- When modifying any of the core configuration files, please ensure that the tproxy related configurations are consistent with the definitions in the `/data/adb/box/settings.ini` file.
- If the machine has a **public IP address**, add the IP to the intranet in the `/data/adb/box/settings.ini` file to prevent traffic loops.
- Logs for the `BFM` service can be found in the `/data/adb/box/run` directory.

## Uninstall
- Removing the installation of this module from Magisk Manager will remove `/data/adb/service.d/box_service.sh` and keep the `BFM` data directory at /data/adb/box.
- You can use the following commands to remove the `BFM` data:

```shell
  su -c rm -rf /data/adb/box
  su -c rm -rf /data/adb/service.d/box_service.sh
```

## CHANGELOG
[CHANGELOG](CHANGELOG.md)
