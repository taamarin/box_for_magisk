# Box for Magisk
[![id](https://img.shields.io/badge/id-blue.svg?style=for-the-badge)](index_id.md) [![en](https://img.shields.io/badge/en-blue.svg?style=for-the-badge)](index_en.md) [![cn](https://img.shields.io/badge/cn-blue.svg?style=for-the-badge)](index_cn.md)

<h1 align="center">
  <img src="https://github.com/taamarin/box_for_magisk/blob/master/docs/box.png" alt="BOX" width="200">
  <br>BOX<br>
</h1>
<h4 align="center">Transparent Proxy for Android(root)</h4>


<div align="center">

[![android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)]()
[![releases](https://img.shields.io/github/downloads/taamarin/box_for_magisk/total.svg?style=for-the-badge)](https://github.com/taamarin/box_for_magisk/releases)

</div>

This project is a [Magisk](https://github.com/topjohnwu/Magisk) module which includes `clash`, `sing-box`, `v2ray` and `xray` proxies.


## Tun (tcp + udp)

```open and edit /data/adb/box/settings.ini```
```shell
# select the client to use : clash / sing-box / xray / v2fly
bin_name="good day"
# Proxy mode: blacklist / whitelist / tun (only tun auto-route)
proxy_mode="tun" # change to tun
```

**sing-box confih.json**
```json
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "utun",
      "inet4_address": "172.19.0.1/30",
      "inet6_address": "fdfe:dcba:9876::1/126",
      "mtu": 9000,
      "stack": "system", // lwip , gvisor
      "auto_route": true,
      "strict_route": false,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "prefer_ipv4"
    }
  ],
```
```json
  "route": {
    "final": "PROXY",
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
    ],
    "auto_detect_interface": true // set true, 
  }
```

**clash confih.yaml**
```yaml
tun:
  enable: true
  # biarkan default utun
  device: utun
  mtu: 9000
  # gvisor / lwip / system
  stack: system
  dns-hijack:
    - any:53
  auto-route: true
  auto-detect-interface: true
  # end
  inet4-address: 172.19.0.1/30
  inet6-address: [fdfe:dcba:9876::1/126]
```


## Mixed (redirec tcp + tun udp)

```open and edit /data/adb/box/settings.ini```
```shell
# select the client to use : clash / sing-box / xray / v2fly
bin_name="good day"
# set the port numbers for tproxy and redir
redir_port='9797'
# redirect: tcp only, / tproxy: for tcp+udp with tproxy, / mixed: mode with redirect[tcp] and tun[udp]
# Network mode: tproxy for transparent proxying
network_mode="mixed" # change to mixed
# Proxy mode: blacklist / whitelist / tun (only tun auto-route)
proxy_mode="blacklist"
```

**sing-box confih.json**
```json
  "inbounds": [
    {
      "type": "redirect",
      "tag": "redirect-in",
      "listen": "::",
      "listen_port": 9797,
      "sniff": true
    },
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "utun",
      "inet4_address": "43.0.0.1/30",
      "inet6_address": "fdfe:dcba:9876::1/126",
      "mtu": 9000,
      "stack": "system", // lwip , gvisor
      "auto_route": true,
      "strict_route": false,
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "prefer_ipv4"
    }
  ]
```
```json
  "route": {
    "final": "PROXY",
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
    ],
    "auto_detect_interface": true // set true, 
  }
```

**clash confih.yaml**
```yaml
redir-port: 9797

tun:
  enable: true
  # biarkan default utun
  device: utun
  mtu: 9000
  # gvisor / lwip / system
  stack: system
  dns-hijack:
    - any:53
  auto-route: true
  auto-detect-interface: true
  # end
  inet4-address: 172.19.0.1/30
  inet6-address: [fdfe:dcba:9876::1/126]
```


## Tproxy (tcp + tun)
```open and edit /data/adb/box/settings.ini```
```shell
# select the client to use : clash / sing-box / xray / v2fly
bin_name="good day"
# set the port numbers for tproxy and redir
tproxy_port='9898'
# redirect: tcp only, / tproxy: for tcp+udp with tproxy, / mixed: mode with redirect[tcp] and tun[udp]
# Network mode: tproxy for transparent proxying
network_mode="tproxy" # change to tproxy
# Proxy mode: blacklist / whitelist / tun (only tun auto-route)
proxy_mode="blacklist"
```
 
**sing-box confih.json**
```json
  "inbounds": [
    {
      "type": "tproxy",
      "tag": "tproxy-in",
      "listen": "::",
      "listen_port": 9898,
      "sniff": true,
      "sniff_override_destination": true,
      "sniff_timeout": "300ms",
      "domain_strategy": "prefer_ipv4",
      "udp_timeout": 300
    }
  ]
```

**clash confih.yaml**
```yaml
tproxy-port: 9898

# tun:
  # enable: false
  # # biarkan default utun
  # device: utun
  # mtu: 9000
  # # gvisor / lwip / system
  # stack: system
  # dns-hijack:
    # - any:53
  # auto-route: true
  # auto-detect-interface: true
  # # end
  # inet4-address: 172.19.0.1/30
  # inet6-address: [fdfe:dcba:9876::1/126]
```

**xray/v2ray confih.json**
```json
  "inbounds": [
    {
      "tag": "proxy-in",
      "port": 9898,
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "followRedirect": true
      },
      "streamSettings": {
        "sockopt": {
          "tproxy": "tproxy"
        }
      },
      "sniffing": {
        "enabled": true,
        "routeOnly": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ]
```

#### make sure the ports in settings.ini and configuration are in sync.


## Credits
  - [CHIZI-0618/box4magisk](https://github.com/CHIZI-0618/box4magisk)