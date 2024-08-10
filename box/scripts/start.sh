#!/system/bin/sh

scripts_dir="${0%/*}"
file_settings="/data/adb/box/settings.ini"
moddir="/data/adb/modules/box_for_root"

# busybox Magisk/KSU/Apatch
busybox="/data/adb/magisk/busybox"
[ -f "/data/adb/ksu/bin/busybox" ] && busybox="/data/adb/ksu/bin/busybox"
[ -f "/data/adb/ap/bin/busybox" ] && busybox="/data/adb/ap/bin/busybox"

refresh_box() {
  if [ -f "/data/adb/box/run/box.pid" ]; then
    "${scripts_dir}/box.service" stop >> "/dev/null" 2>&1
    "${scripts_dir}/box.iptables" disable >> "/dev/null" 2>&1
  fi
}

start_service() {
  if [ ! -f "${moddir}/disable" ]; then
    "${scripts_dir}/box.service" start >> "/dev/null" 2>&1
  fi
}

enable_iptables() {
  PIDS=("clash" "xray" "sing-box" "v2fly")
  PID=""
  i=0
  while [ -z "$PID" ] && [ "$i" -lt "${#PIDS[@]}" ]; do
    PID=$($busybox pidof "${PIDS[$i]}")
    i=$((i+1))
  done

  if [ -n "$PID" ]; then
    "${scripts_dir}/box.iptables" enable >> "/dev/null" 2>&1
  fi
}

net_inotifyd() {
  while [ ! -f /data/misc/net/rt_tables ] ; do
    sleep 3
  done

  net_dir="/data/misc/net"
  # Use inotifyd to monitor write events in the /data/misc/net directory for network changes, perhaps we have a better choice of files to monitor (the /proc filesystem is unsupported) and cyclic polling is a bad solution
  inotifyd "${scripts_dir}/net.inotify" "${net_dir}" > "/dev/null" 2>&1 &
}

start_inotifyd() {
  PIDs=($($busybox pidof inotifyd))
  for PID in "${PIDs[@]}"; do
    if grep -q -e "box.inotify" -e "net.inotify" "/proc/$PID/cmdline"; then
      kill -9 "$PID"
    fi
    # if grep -q "box.inotify" "/proc/$PID/cmdline"; then
      # kill -9 "$PID"
    # fi
  done
  inotifyd "${scripts_dir}/box.inotify" "${moddir}" > "/dev/null" 2>&1 &
  net_inotifyd
}

mkdir -p /data/adb/box/run/
if [ -f "/data/adb/box/manual" ]; then
  net_inotifyd
  exit 1
fi

if [ -f "$file_settings" ] && [ -r "$file_settings" ] && [ -s "$file_settings" ]; then
  refresh_box
  start_service
  enable_iptables
fi

start_inotifyd
