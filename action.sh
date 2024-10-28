#!/system/bin/sh
MODDIR=${0%/*}

if [ ! -e /$MODDIR/started ]; then
    su -c /data/adb/box/scripts/box.service start && su -c /data/adb/box/scripts/box.iptables enable
    touch /$MODDIR/started
    exit
fi

if [ -e /$MODDIR/started ]; then
    su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
    rm -f /$MODDIR/started
fi
