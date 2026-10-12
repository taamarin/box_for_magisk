# 📦 Magisk / KernelSU 的 Box 模块

## ⚠️ 警告

对于设备、SD 卡或 SoC 的损坏，本项目概不负责。

**请确保配置文件不会造成流量循环，否则手机可能会不断重启。**

如果您不清楚如何配置此模块，建议使用以下应用程序：**ClashForAndroid、ClashMetaForAndroid、v2rayNG、Surfboard、SagerNet、AnXray、NekoBox、SFA** 等。

## 📦 安装
• 从 [Releases](https://github.com/taamarin/box_for_magisk/releases) 下载模块 ZIP，并通过 `Magisk/APatch/KernelSU` 安装。安装时会询问是否下载完整包；您可以一次性下载全部文件，也可以稍后分别下载。安装完成后，请重启设备。  
• 此模块支持通过 `Magisk/APatch/KernelSU 管理器`直接更新，更新后无需重启设备即可生效。

### 内核更新
此模块包含以下内核：  
• [clash](https://github.com/Dreamacro/clash)(仓库已删除)  
• [clash.meta](https://github.com/MetaCubeX/mihomo)  
• [sing-box](https://github.com/SagerNet/sing-box)  
• [v2ray-core](https://github.com/v2fly/v2ray-core)  
• [Xray-core](https://github.com/XTLS/Xray-core)  
• [hysteria]()

使用的内核由 `${bin_name}` 指定，可设置为 `clash`、`xray`、`v2ray`、`sing-box` 或 `hysteria`。  
每个内核运行于 `/data/adb/box/bin/${bin_name}` 目录，具体名称由 `/data/adb/box/settings.ini` 中的 `bin_name` 决定。

请确保连接互联网后执行以下命令以更新内核文件：
```shell
su -c /data/adb/box/scripts/box.tool upkernel
```

如果您选择了 `clash` 或 `sing-box`，并且需要使用控制面板（dashboard），还需执行以下命令：
```shell
su -c /data/adb/box/scripts/box.tool upxui
```

也可以执行以下命令一次性更新所有文件（这可能会占用更多存储空间）：
```shell
su -c /data/adb/box/scripts/box.tool all
```

## ⚙️ 配置
**本模块提供的核心服务统称为 BFR。**  
您可以通过 Magisk/KernelSU 管理器启用或停用模块，从而实时启动或停止 BFR 服务，无需重启设备。服务启动可能需要几秒钟，停止则会立即生效。

### 核心配置
• 有关通过 `bin_name` 选择内核的信息，请参见“内核更新”部分。  
• 请根据需要自定义各内核的配置文件。脚本会检查配置是否有效，并将检查结果保存在 `/data/adb/box/run/runs.log`。  
• **提示：**`clash` 和 `sing-box` 均提供透明代理脚本。更多配置说明请参阅官方文档：[Clash](https://github.com/Dreamacro/clash/wiki/configuration)（master 分支已删除）和 [sing-box](https://sing-box.sagernet.org/configuration/outbound/)。

### 应用过滤（黑名单/白名单）
• 默认情况下，BFR 会代理所有 Android 用户的所有应用流量。  
• 若要让 BFR **代理除指定应用以外的所有应用**，请打开 `/data/adb/box/package.list.cfg`，将 `mode` 设为 `blacklist`（默认值），并添加要排除的应用，例如：  
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**  
• 若只想 **代理指定应用**，请使用 `mode:whitelist`，并添加要代理的应用：  
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**  
> ⚠️ 使用 Clash 时，黑白名单在 fake-IP 模式下无效。

### 为特定进程启用透明代理
• 默认情况下，BFR 会对所有进程进行透明代理。  
• 若要排除某些进程，请在 `/data/adb/box/package.list.cfg` 中将 `mode` 设为 `blacklist`（默认值），并添加相应的 GID（每行一个）。  
• 若只想代理某些进程，则将 `mode` 设为 `whitelist`，并添加相应的 GID。  
> ⚠️ Android 的 iptables 不支持按 PID 匹配，因此 Box 通过 GID 间接匹配进程。在 Android 上，可使用 BusyBox 的 `setuidgid` 命令，以指定 UID 和任意 GID 启动进程。

### 更改代理模式
• 默认使用 TPROXY 模式透明代理 TCP 和 UDP。若设备不支持 TPROXY，请在 `/data/adb/box/settings.ini` 中将 `network_mode` 设为 `redirect`，此模式仅代理 TCP。  
• `redirect`：使用 redirect 代理 TCP，UDP 直连。  
• `tproxy`：使用 TPROXY 代理 TCP 和 UDP。  
• `mixed`：使用 redirect 代理 TCP，通过 TUN 代理 UDP。  
• `enhance`：使用 redirect 代理 TCP，使用 TPROXY 代理 UDP。  
• `tun`：通过自动路由的 TUN 接口代理 TCP 和 UDP。

### 连接 Wi-Fi/热点时绕过透明代理
• 默认情况下，BFR 会透明代理 `localhost` 和热点流量（包括 USB 网络共享）。  
• 若要在连接 Wi-Fi 时绕过代理，请在 `/data/adb/box/ap.list.cfg` 中添加 **ignore wlan+**。  
• 若要代理热点流量，请添加 **allow wlan+**（此设置与 **ignore wlan+** 冲突）。MediaTek 设备的接口名称可能是 **ap+** 或 **wlan+**。  
• 可使用 `ifconfig` 命令查看 AP 接口名称。

### 启用计划任务自动更新 Geo 和订阅
• 编辑 `/data/adb/box/settings.ini`，将 `run_crontab=true`、`update_geo="true"` 和 `update_subscription="true"`，并设置 `interva_update="@daily"`（默认值）或指定其他计划。  
• Geo 数据和订阅将按计划自动更新。  
• 可在 `/data/adb/box/crontab.cfg` 中添加其他计划任务：
```shell
su -c /data/adb/box/scripts/box.service cron
su -c /data/adb/box/scripts/box.service kcron
```

## ▶️ 启动与停止
### 手动模式
• 若要通过命令完全手动管理 BFR，请创建 `/data/adb/box/manual` 文件。在此模式下，BFR 不会自动启动，也无法通过 Magisk/KernelSU 管理器控制。

### 启动与停止服务脚本
• BFR 服务脚本：`/data/adb/box/scripts/box.service`  
• BFR iptables 脚本：`/data/adb/box/scripts/box.iptables`  
```shell
# 启动 BFR
su -c /data/adb/box/scripts/box.service start && su -c /data/adb/box/scripts/box.iptables enable

# 停止 BFR
su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

## Geo 数据与订阅更新
使用以下命令同时更新订阅和 Geo 数据库：
```shell
su -c /data/adb/box/scripts/box.tool geosub
```

也可以分别更新：  
### 更新订阅（仅支持 Clash）
```shell
su -c /data/adb/box/scripts/box.tool subs
```

### 更新 Geo 数据库
```shell
su -c /data/adb/box/scripts/box.tool geox
```

## 📘 补充说明
• 修改内核配置文件时，请确保其中与 TPROXY 相关的设置和 `/data/adb/box/settings.ini` 中的定义一致。  
• 若设备拥有公网 IP，可将其加入 `/data/adb/box/scripts/box.iptables` 中的内部网络，以避免流量循环。  
• BFR 日志保存在 **/data/adb/box/run** 目录中。

运行以下命令可查看其他使用说明：
```shell
su -c /data/adb/box/scripts/box.tool
# usage: {check|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|all}
su -c /data/adb/box/scripts/box.service
# usage: $0 {start|stop|restart|status|cron|kcron}
su -c /data/adb/box/scripts/box.iptables
# usage: $0 {enable|disable|renew}
```

## 🗑️ 卸载
• 通过 Magisk/KernelSU 管理器卸载模块时，也会删除 `/data/adb/service.d/box_service.sh` 和 `/data/adb/box` 目录。  
• 若要手动删除 BFR 数据，请运行以下命令：
```shell
su -c rm -rf /data/adb/box
su -c rm -rf /data/adb/service.d/box_service.sh
su -c rm -rf /data/adb/modules/box_for_root
```