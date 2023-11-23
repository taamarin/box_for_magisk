#### Changelog v1.4.2
+ box script fixes and improvements.
+ requires `install busybox-ndk v1.36.1+` to fix :
   + wget: TLS error from peer (alert code 80): 80
   + wget: error getting response: Connection reset by peer
   + setuidgid permission denied on some devices
   > ignore it if you don't experience it
   
#### Changelog v1.4.1
+ Fix restore configuration and kernel, at the start of flash when select `VOL DOWN (-)`

#### Changelog v1.4.0
+ feat: backup and restore
+ remove: sing-box subscription support (if you want to use ProxyProvider, use sing-box kernel([yaotthaha](https://github.com/yaotthaha/sing-box-pub), [PuerNya](https://github.com/PuerNya/sing-box/tree/building), [qjebbs](https://github.com/qjebbs/sing-box)). [example](https://gist.github.com/CHIZI-0618/fc3495cd15b3ab3d53c77872ebece8ae)
+ add: stable Clash.Meta kernel downloads
+ add: cgroup blkio(background),cpuset(top-app), default false
+ add: taskset, default ff
+ ap_list: add swlan+
+ fixes and improvements
#### Changelog v1.3.0
+ fix update_kernel sing-box function
+ add GID black/white lists
#### Changelog v1.2.1
+ code Optimize 
#### Changelog v1.2.0
+ add: options for clash_ premium/meta ([see](https://github.com/taamarin/box_for_magisk/blob/24cee5837965e73eee0b945292d9557180c627d3/box/settings.ini#L24-L26))
#### Changelog v1.1
+ fix an issue where the log file output kept continuously growing larger. ([see](https://github.com/taamarin/box_for_magisk/blob/0a3e9bb6b4260ce065bd3aaaded835cb3f7c0dc7/box/settings.ini#L61-L63))
+ fix `kernel/core` permissions in `/system/bin` directory.
+ chore: sing-box `inbound` configuration
+ customize box.iptables scripts.
#### Changelog v1.0
+ bug fixes and stability improvements.
