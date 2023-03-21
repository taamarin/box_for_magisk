## WARNING
该项目不负责：损坏设备、损坏SD卡或烧毁SoCs。

**请确保您的配置文件不会引起流量回环，否则可能会导致您的手机无限重启。**

如果你真的不知道如何配置这个模块，你可能需要一个像 ClashForAndroid、ClashMetaForAndroid、v2rayNG、Surfboard、SagerNet、AnXray、NekoBox 等应用程序。

## 安装
- 从RELEASE下载模块zip包，并通过MAGISK安装它。然后重新启动设备。
- 确保您已连接到互联网，并执行以下命令以下载二进制文件等：
```shell
  su -c /data/adb/box/scripts/box.tool upyacd
```
```shell
  su -c /data/adb/box/scripts/box.tool subgeo
```
```shell
  su -c /data/adb/box/scripts/box.tool upcore
```

- 支持在 Magisk Manager 中进行下一个在线模块更新（更新模块将在不重新启动设备的情况下生效）。

### Notes
此模块包括：
 - [clash](https://github.com/Dreamacro/clash)、
 - [clash.meta](https://github.com/MetaCubeX/Clash.Meta)、[sing-box](https://github.com/SagerNet/sing-box)、
 - [v2ray-core](https://github.com/v2fly/v2ray-core)、
 - [Xray-core](https://github.com/XTLS/Xray-core).
 - [sing-box]().
  
安装完模块后，下载适合您设备架构的核心文件，并将其放置在/data/adb/box/bin/目录中，或执行以下命令：

```shell
su -c /data/adb/box/scripts/box.tool upcore
```

or,

```shell
su -c /data/adb/box/scripts/box.tool all
```

## 配置
- ${bin_name}:
  - clash
  - xray
  - v2ray
  - sing-box

- 每个核心都在/data/adb/box/bin/${bin_name}目录中工作，核心名称由BFM文件中的bin_name确定。
- 每个核心配置文件需要由用户进行自定义，并且脚本将检查配置的有效性，检查结果将保存在文件/data/adb/box/run/runs.log中。
- 提示：clash和sing-box都带有透明代理脚本的预配置。有关更多配置，请参阅官方文档。地址：[dokumen clash](https://github.com/Dreamacro/clash/wiki/configuration), [dokumen sing-box](https://sing-box.sagernet.org/configuration/outbound/)

## 说明
### 常规方法（标准和推荐方法）
#### 启动和停止管理服务
**以下核心服务被称为BFM**
- 以下核心服务集体称为BFM
- 您可以通过 Magisk Manager 应用程序实时启用或禁用模块以启动或停止BFM服务，无需重新启动设备。启动服务可能需要几秒钟的时间，停止服务可以立即生效。

#### 选择需要代理的应用程序（APP）
- BFM默认为所有Android用户的所有应用程序（APP）提供代理。
- 如果您想让BFM代理所有应用程序（APP），除了某些应用程序，请打开文件/data/adb/box/settings.ini，将proxy_mode的值更改为blacklist（默认），将要排除的应用程序添加到packages_list，例如：packages_list=("com.termux" "org.telegram.messenger")
- 如果您只想代理某些应用程序（APP），请使用whitelist。
- 当proxy_mode的值为core/tun时，透明代理将不起作用，仅启动相应的内核，用于支持TUN，目前仅有clash和sing-box可用。
- 如果使用 Clash，在 fake-ip 模式下，黑名单和白名单将无法生效。

### 高级用法
#### 更改代理模式
- BFM使用TPROXY来透明代理TCP + UDP（默认）。如果检测到设备不支持TPROXY，请打开/data/adb/box/settings.ini并将network_mode="redirect"更改为仅使用TCP代理的redirect。
- 打开文件/data/adb/box/settings.ini，将network_mode的值更改为redirect、tproxy或mixed。
- redirect：仅重定向TCP。
- tproxy：重定向TCP + UDP。
- mixed：重定向TCP和tun UDP。

#### 在连接到 Wi-Fi 或热点时绕过透明代理
- BFM 默认透明代理本地主机和热点（包括 USB 共享网络）。
- 打开文件 /data/adb/box/settings.ini，修改 ignore_out_list 并添加 wlan+，这样透明代理将绕过 wlan，并且热点不会连接到代理。
- 打开文件 /data/adb/box/settings.ini，修改 ap_list 并添加 wlan+。BFM 将代理热点（对于联发科设备，可能是 ap+ / wlan+）。
- 使用终端中的 ifconfig 命令找出 AP 的名称。

#### 进入手动模式
- 如果您想通过运行命令来完全控制 BFM，只需创建一个名为 /data/adb/box/manual 的新文件。在这种情况下，当您的设备开机时，BFM 服务将不会自动启动，您也无法通过 Magisk Manager 应用程序设置服务的启动或停止。
#### 启动和停止管理服务
- BFM 服务脚本为 /data/adb/box/scripts/box.service

- 启动 BFM：
```shell
  su -c /data/adb/box/scripts/box.service start
```
- 停止 BFM：
```shell
  su -c /data/adb/box/scripts/box.service stop
```

- 终端会同时打印日志并将其输出到日志文件中。

#### 管理透明代理是否启用
- 透明代理脚本是 /data/adb/box/scripts/box.tproxy。

- 启用透明代理：
```shell
  su -c /data/adb/box/scripts/box.tproxy enable
```

- 禁用透明代理：
```shell
  su -c /data/adb/box/scripts/box.tproxy disable
```

## 其他指令
- 在修改任何核心配置文件时，请确保tproxy相关的配置与/data/adb/box/settings.ini文件中的定义一致。
- 如果设备有公共IP地址，请在/data/adb/box/scripts/box.iptables文件中将该IP添加到内网中，以防止流量循环。
- 可以在/data/adb/box/run目录中找到BFM服务的日志。

## 卸载
- 从Magisk Manager中删除此模块的安装将删除/data/adb/service.d/box_service.sh，并保留BFM数据目录位于/data/adb/box。
- 您可以使用以下命令删除BFM数据：

```shell
  su -c rm -rf /data/adb/box
```
```shell
  su -c rm -rf /data/adb/service.d/box_service.sh
```

## CHANGELOG
[CHANGELOG](CHANGELOG.md)
