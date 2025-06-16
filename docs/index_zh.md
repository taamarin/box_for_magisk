# 📦 Magisk / KernelSU 的 Box 模块

## ⚠️ 警告

本项目不对以下情况负责：设备损坏、SD 卡损坏或 SoC 烧毁。

**请确保您的配置文件不会造成流量循环，否则可能导致手机无限重启。**

如果您不清楚如何配置此模块，建议使用以下应用程序：**ClashForAndroid、ClashMetaForAndroid、v2rayNG、Surfboard、SagerNet、AnXray、NekoBox、SFA** 等。

## 📦 安装
• 从 [RELEASE](https://github.com/taamarin/box_for_magisk/releases) 下载 zip 模块包，并通过 `Magisk/APatch/KernelSU` 安装。安装时会询问是否下载完整包，您可以选择**完整下载** 或 **稍后分开下载**，然后重启设备。  
• 此模块支持通过 `Magisk/APatch/KernelSU 管理器` 直接更新模块（更新后无需重启设备即可生效）。

### 内核更新
此模块包含以下内核：  
• [clash](https://github.com/Dreamacro/clash)(仓库已删除)  
• [clash.meta](https://github.com/MetaCubeX/mihomo)  
• [sing-box](https://github.com/SagerNet/sing-box)  
• [v2ray-core](https://github.com/v2fly/v2ray-core)  
• [Xray-core](https://github.com/XTLS/Xray-core)  
• [hysteria]()

适用于每个内核的配置为 `${bin_name}`，可设为（`clash` | `xray` | `v2ray` | `sing-box` | `hysteria`）。  
每个核心位于 `/data/adb/box/bin/${bin_name}` 目录中，核心名称由 `/data/adb/box/settings.ini` 文件中的 `bin_name` 决定。

请确保连接互联网后执行以下命令以更新内核文件：
```shell
su -c /data/adb/box/scripts/box.tool upkernel
```

如果您使用的是 `clash` 或 `sing-box`，并希望使用控制面板(dashboard)，也请执行以下命令：
```shell
su -c /data/adb/box/scripts/box.tool upxui
```

或者执行以下命令以一次性更新所有文件（可能会占用较多存储）：
```shell
su -c /data/adb/box/scripts/box.tool all
```

## ⚙️ 配置
**以下核心服务统称为 BFR**  
您可以通过 Magisk/KernelSU 管理器启用或停用模块，实时启动或停止 BFR 服务，无需重启设备。启动服务可能需要几秒钟，停止服务则立即生效。

### 核心配置
• 有关 `bin_name` 的核心配置，请参见“内核更新”部分。  
• 每个核心配置文件需用户自行定制，脚本将检查配置有效性，检查结果保存在 `/data/adb/box/run/runs.log`。  
• 提示：`clash` 和 `sing-box` 已预设透明代理脚本。更多配置请参考官方文档：[Clash 官方文档](https://github.com/Dreamacro/clash/wiki/configuration)（已删除），[sing-box 官方文档](https://sing-box.sagernet.org/configuration/outbound/)

### 应用过滤（黑名单/白名单）
• 默认情况下，BFR 会代理所有 Android 用户的所有应用。  
• 若想让 BFR **代理所有应用，排除部分应用**，请打开 `/data/adb/box/package.list.cfg` 文件，将 `mode` 设置为 `blacklist`（默认值），并添加要排除的应用，例如：  
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**  
• 若只想 **代理指定应用**，请使用 `mode:whitelist` 并添加要代理的应用：  
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**  
> ⚠️ 若使用 CLASH，黑白名单在 fake-ip 模式下无效

### 为特定进程启用透明代理
• 默认情况下，BFR 透明代理所有进程。  
• 若要排除某些进程，请在 `/data/adb/box/package.list.cfg` 中将 `mode` 设置为 `blacklist`（默认值），并添加 GID（每个 GID 一行）。  
• 若只想代理某些进程，则设置 `mode` 为 `whitelist` 并添加 GID。  
> ⚠️ Android 的 iptables 不支持 PID 匹配，Box 通过 GID 间接匹配进程。可通过 busybox 的 setuidgid 命令以特定 UID 启动进程。

### 更改代理模式
• 默认使用 TPROXY 模式代理 TCP+UDP。若设备不支持 TPROXY，请修改 `/data/adb/box/settings.ini` 中 `network_mode="tproxy"` 为 `redirect`：  
• redirect：redirect(TCP) + Direct(UDP)  
• tproxy：tproxy(TCP + UDP)  
• mixed：redirect(TCP) + tun(UDP)  
• enhance：redirect(TCP) + tproxy(UDP)  
• tun：TCP + UDP（自动路由）

### 连接 Wi-Fi/热点时绕过透明代理
• 默认情况下，BFR 会透明代理 `localhost` 和热点（包括 USB 共享）。  
• 打开 `/data/adb/box/ap.list.cfg` 添加 **ignore wlan+**，则会跳过 wlan 和热点代理。  
• 若添加 **allow wlan+**（与 ignore wlan+ 冲突），则 BFR 会代理热点（Mediatek 设备可能为 ap+ / wlan+）。  
• 使用 `ifconfig` 命令查看 AP 名称。

### 启用计划任务自动更新 Geo 和订阅
• 修改 `/data/adb/box/settings.ini`，将 `run_crontab=true`、`update_geo="true"`、`update_subscription="true"` 并设置 `interva_update="@daily"`（默认值）  
• Geo 和订阅将自动按计划更新。  
• 可在 `/data/adb/box/crontab.cfg` 添加其他计划任务：
```shell
su -c /data/adb/box/scripts/box.service cron
su -c /data/adb/box/scripts/box.service kcron
```

## ▶️ 启动与停止
### 手动模式
• 若您想完全手动控制 BFR，创建 `/data/adb/box/manual` 文件即可。在此模式下，BFR 不会自动启动，也不能通过 Magisk/KernelSU 管理器控制。

### 启动与停止服务脚本
• BFR 服务脚本：/data/adb/box/scripts/box.service  
• BFR iptables 脚本：/data/adb/box/scripts/box.iptables  
```shell
# 启动 BFR
su -c /data/adb/box/scripts/box.service start && su -c /data/adb/box/scripts/box.iptables enable

# 停止 BFR
su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

## Geo 与订阅更新
使用以下命令同时更新订阅与 Geo 数据库：
```shell
su -c /data/adb/box/scripts/box.tool geosub
```

或分别更新：  
### 更新订阅（仅支持 Clash）
```shell
su -c /data/adb/box/scripts/box.tool subs
```

### 更新 Geo 数据库
```shell
su -c /data/adb/box/scripts/box.tool geox
```

## 📘 附加说明
• 修改任何配置文件时，请确保与 `/data/adb/box/settings.ini` 的定义一致。  
• 若设备拥有公网 IP，请将其加入 `/data/adb/box/scripts/box.iptables` 中的内部网络以避免流量回环。  
• BFR 的日志保存在 **/data/adb/box/run** 目录。

查看帮助命令：
```shell
su -c /data/adb/box/scripts/box.tool
# usage: {check|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|all}
su -c /data/adb/box/scripts/box.service
# usage: $0 {start|stop|restart|status|cron|kcron}
su -c /data/adb/box/scripts/box.iptables
# usage: $0 {enable|disable|renew}
```

## 🗑️ 卸载
• 通过 Magisk/KernelSU 管理器卸载模块将删除 `/data/adb/service.d/box_service.sh` 和 `/data/adb/box` 目录。  
• 可使用以下命令手动删除 BFR 数据：
```shell
su -c rm -rf /data/adb/box
su -c rm -rf /data/adb/service.d/box_service.sh
su -c rm -rf /data/adb/modules/box_for_root
```