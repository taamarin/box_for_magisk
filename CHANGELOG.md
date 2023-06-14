#### Changelog v0.9.1
+ fix Cron Job can't start/update `geosub`, if `use_ghproxy=false`

#### Changelog v0.9.0
+ fix: Cron Job update Geox and Subs [click](https://github.com/taamarin/box_for_magisk/blob/bbeb8018aeadaa9d845f3e3d5d38a0446d694f34/box/settings.ini#L45-L56)
    + for manual
    $ su -c /data/adb/box/scripts/box.tool subs
    $ su -c /data/adb/box/scripts/box.tool geox
+ add: download enable ghproxy, default is 'true' [click](https://github.com/taamarin/box_for_magisk/blob/bbeb8018aeadaa9d845f3e3d5d38a0446d694f34/box/scripts/box.tool#L20)
+ add: yacd autostart settings [click](https://github.com/taamarin/box_for_magisk/blob/bbeb8018aeadaa9d845f3e3d5d38a0446d694f34/box/settings.ini#L103)
+ add: default url Country.mmdb and GeoX by MetaCubeX [click](https://github.com/taamarin/box_for_magisk/blob/bbeb8018aeadaa9d845f3e3d5d38a0446d694f34/box/scripts/box.tool#L100-L116)
+ add: toml support for xray/v2fly
+ add: yq to extract the node information in the subscribed address to domestic.yml [click](https://github.com/taamarin/box_for_magisk/blob/bbeb8018aeadaa9d845f3e3d5d38a0446d694f34/box/settings.ini#L78)