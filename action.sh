#!/system/bin/sh

box_dir=/data/adb/box
box_run="${box_dir}/run"
box_pid="${box_run}/box.pid"

if [ -f "${box_pid}" ]; then
    echo "正在关闭服务…"
    echo "Service is shutting down"
    su -c $box_dir/scripts/box.iptables disable && su -c $box_dir/scripts/box.service stop
else
    echo "正在启动服务，请耐心等待…"
    echo "Service is starting,please wait for a moment"
    su -c $box_dir/scripts/box.service start && su -c $box_dir/scripts/box.iptables enable
    exit
fi
