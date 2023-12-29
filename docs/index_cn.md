## 注意
该项目不负责：损坏设备、损坏 SD 卡或烧毁 SoCs。

**请确保您的配置文件不会引起流量回环，否则可能会导致您的手机无限重启。**

如果你真的不知道如何配置这个模块，你可能需要一个像 **ClashForAndroid、ClashMetaForAndroid、v2rayNG、Surfboard、SagerNet、AnXray、NekoBox** 等应用程序。

## 安装
- 从 [RELEASE](https://github.com/taamarin/box_for_magisk/releases) 下载模块 zip 包，并通过 `Magisk/KernelSU` 安装它。安装时会询问是否下载全量包，您可以选择**全量下载**或者稍后再**单独下载**，然后重新启动设备。
- 本模块支持在 `Magisk/KernelSU Manager` 中进行下一个在线模块更新（更新模块将在不重新启动设备的情况下生效）。

### 内核更新
此模块包括如下几种内核：
- [clash](https://github.com/Dreamacro/clash)(删除主分支)
- [clash.meta](https://github.com/MetaCubeX/Clash.Meta)(存档换分支，内容还在)
- [sing-box](https://github.com/SagerNet/sing-box)
- [v2ray-core](https://github.com/v2fly/v2ray-core)
- [Xray-core](https://github.com/XTLS/Xray-core)

内核对应的配置为 `${bin_name}`, 可以设置为( `clash` | `xray` | `v2ray` | `sing-box`).

每个核心都在`/data/adb/box/bin/${bin_name}`目录中工作，核心名称由 `/data/adb/box/settings.ini` 文件中的 `bin_name` 确定。

确保您已连接到互联网，并执行以下命令以更新内核文件：

```shell
# 更新选定的内核
su -c /data/adb/box/scripts/box.tool upcore
```

如果您使用 `clash` 作为你的选定内核，您可能还需要执行如下指令开启控制面板:

```shell
# 更新 Clash 管理面板
su -c /data/adb/box/scripts/box.tool upxui
```

或者，您可以将所有操作一次性执行(这可能造成不必要的存储空间浪费):

```shell
# 更新所有文件(包括不同种类的内核)
su -c /data/adb/box/scripts/box.tool all
```

## 配置
**以下核心服务被称为 BFM**
- 以下核心服务集体称为 BFM
- 您可以通过 Magisk/KernelSU Manager 应用程序实时启用或禁用模块以启动或停止 BFM 服务，无需重新启动设备。启动服务可能需要几秒钟的时间，停止服务可以立即生效。

### 核心配置
- 核心 `bin_name` 配置请查询**内核更新**部分进行配置即可
- 每个核心配置文件需要由用户进行自定义，并且脚本将检查配置的有效性，检查结果将保存在文件 `/data/adb/box/run/runs.log` 中。
- 提示：`clash` 和 `sing-box` 都带有透明代理脚本的预配置。有关更多配置，请参阅官方文档。地址：[Clash 官方文档](https://github.com/Dreamacro/clash/wiki/configuration)(删除主分支)、[sing-box 官方文档](https://sing-box.sagernet.org/configuration/outbound/)

### 应用过滤(白/黑名单)
- BFM 默认为所有 Android 用户的所有应用程序（APP）提供代理。
- 如果您想让 BFM 代理所有应用程序（APP），除了某些应用程序，请打开文件`/data/adb/box/settings.ini`，将 `proxy_mode` 的值更改为 **blacklist**（默认），将要排除的应用程序添加到 `packages_list`，例如：packages_list=("com.termux" "org.telegram.messenger")
- 如果您只想代理某些应用程序（APP），请使用 **whitelist**。
- 当 `proxy_mode` 的值为 **tun** 时，透明代理将不起作用，仅启动相应的内核，用于支持 **TUN**，目前仅有 **clash** 和 **sing-box** 可用。
- **如果使用 Clash，在 fake-ip 模式下，黑名单和白名单将无法生效。**

### 特定进程的透明代理
- BFM 默认透明代理所有进程
- 如果您希望 BFM 代理所有进程，除了某些特定的进程，那么请打开 `/data/adb/box/settings.ini` 文件，修改 `proxy_mode` 的值为 `blacklist`（默认值），在 `gid_list` 数组中添加 GID 元素，GID 之间用空格隔开。即可**不代理**相应 GID 的进程
- 如果您希望只对特定的进程进行透明代理，那么请打开 `/data/adb/box/settings.ini` 文件，修改 `proxy_mode` 的值为 **whitelist**，在 `gid_list` 数组中添加 GID 元素，GID 之间用空格隔开。即可**仅代理**相应 GID 进程

> 小贴士：因为安卓 iptables 不支持 PID 扩展匹配，所以 Box 匹配进程是通过匹配 GID 间接达到的。安卓可以使用 busybox setuidgid 命令使用特定 UID 任意 GID 启动特定进程

### 更改代理模式
- BFM 使用 TPROXY 来透明代理 TCP + UDP（默认）。如果检测到设备不支持 TPROXY，请打开**/data/adb/box/settings.ini** 并将 `network_mode="redirect"`更改为仅使用 TCP 代理的 redirect。
- 打开文件**/data/adb/box/settings.ini**，将 network_mode 的值更改为 redirect、tproxy 或 mixed。
- redirect：仅重定向 TCP。
- tproxy：重定向 TCP + UDP。
- mixed：重定向 TCP 和 tun UDP。

### 在连接到 Wi-Fi 或热点时绕过透明代理
- BFM 默认透明代理本地主机和热点（包括 USB 共享网络）。
- 打开文件 **/data/adb/box/settings.ini**，修改 `ignore_out_list` 并添加 wlan+，这样透明代理将绕过 **wlan**，并且热点不会连接到代理。
- 打开文件 **/data/adb/box/settings.ini**，修改 `ap_list` 并添加 wlan+。BFM 将代理热点（对于联发科设备，可能是 ap+ / wlan+）。
- 使用终端中的 `ifconfig` 命令找出 `AP` 的名称。

### 启用 Cron 作业以按计划自动更新 Geo 和 Subs
- 打开文件 /data/adb/box/settings.ini，更改 `run_crontab=true` 的值，并设置 interval_update=“@daily”（默认），调整为你想要的。

```shell
  # 运行命令
  su -c /data/adb/box/scripts/box.service cron
```

- 因此 Geox 和 Subs 将根据 interval_update 时间表自动更新。

## 启动和停止
### 进入手动模式
- 如果您想通过运行命令来完全控制 BFM，只需创建一个名为 /data/adb/box/manual 的新文件。在这种情况下，当您的设备开机时，BFM 服务将不会自动启动，您也无法通过 Magisk/KernelSU Manager 应用程序设置服务的启动或停止。

### 启动和停止管理服务
- BFM 服务脚本为 /data/adb/box/scripts/box.service
- BFM iptables 脚本是 /data/adb/box/scripts/box.iptables

```shell
# 启动 BFM
  su -c /data/adb/box/scripts/box.service start &&  su -c /data/adb/box/scripts/box.iptables enable

# 停止 BFM
  su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

- 终端会同时打印日志并将其输出到日志文件中。

## 订阅及Geo数据库更新
您可以使用如下指令同时更新订阅以及 Geo 数据库:

```shell
  su -c /data/adb/box/scripts/box.tool geosub
```

或者您可以单独更新他们。

### 更新订阅

```shell
  su -c /data/adb/box/scripts/box.tool subs
```

### 更新 Geo 数据库

```shell
  su -c /data/adb/box/scripts/box.tool geox
```

## 其他指令
- 在修改任何核心配置文件时，请确保 tproxy 相关的配置与/data/adb/box/settings.ini 文件中的定义一致。
- 如果设备有公共 IP 地址，请在/data/adb/box/scripts/box.iptables 文件中将该 IP 添加到内网中，以防止流量循环。
- 可以在/data/adb/box/run 目录中找到 BFM 服务的日志。

您可以运行如下指令获取其他更多相关操作指令：

```shell
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|bond0|bond1|memcg|cpuset|blkio|geosub|geox|subs|upkernel|upyacd|upyq|upcurl|port|reload|all}
  su -c /data/adb/box/scripts/box.service
  # usage: $0 {start|stop|restart|status|cron|kcron}
  su -c /data/adb/box/scripts/box.iptables
  # usage: $0 {enable|disable|renew}
```

## 卸载
- 从 Magisk/KernelSU Manager 中删除此模块的安装将删除/data/adb/service.d/box_service.sh，并保留 BFM 数据目录位于/data/adb/box。
- 您可以使用以下命令删除 BFM 数据：

```shell
  su -c rm -rf /data/adb/box
  su -c rm -rf /data/adb/service.d/box_service.sh
  su -c rm -rf /data/adb/modules/box_for_root
```
