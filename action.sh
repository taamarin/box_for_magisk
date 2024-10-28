#!/system/bin/sh
BOXDIR=/data/adb/box

if [ ! -e "/$BOXDIR/started" ]; then
    echo "正在启动服务，请耐心等待…"
    echo "Service is starting,please wait for a moment"
    su -c /$BOXDIR/scripts/box.service start && su -c /$BOXDIR/scripts/box.iptables enable
    touch "/$BOXDIR/started"
    exit
else
    echo "正在关闭服务…"
    echo "Service is shutting down"
    su -c /$BOXDIR/scripts/box.iptables disable && su -c /$BOXDIR/scripts/box.service stop
    rm "/$BOXDIR/started"
fi
