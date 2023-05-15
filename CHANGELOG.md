#### ⟳ Changelog v0.8.2
+ add intranet6 ip range: fc00::/7
+ Enable IP forwarding ( sysctl -w net.ipv4.ip_forward=1 sysctl -w net.ipv6.conf.all.forwarding=1)
+ change dashboard url using [yacd-meta](https://github.com/MetaCubeX/Yacd-meta)
+ fix update dashboard/yacd( su -c /data/adb/box/scripts/box.tool upyacd )
+ fix check kernel in directory /data/adb/box/bin/$bin_name
+ fix: path `tar`, `unzip`, and `gunzip`

[README](https://github.com/taamarin/box_for_magisk/blob/master/README.md)