#!/system/bin/sh

scripts_dir="${0%/*}"
file_settings="/data/adb/box/settings.ini"

moddir="/data/adb/modules/box_for_root"

if [ -n "$(magisk -v | grep lite &> /dev/null )" ]; then
  moddir="/data/adb/lite_modules/box_for_root"
fi

if [ -f "/data/adb/ksu/bin/busybox" ]; then
  # busybox KSU
  busybox="/data/adb/ksu/bin/busybox"
elif [ -f "/data/adb/ap/bin/busybox" ]; then
  # busybox APatch
  busybox="/data/adb/ap/bin/busybox"
else
  # busybox Magisk
  busybox="/data/adb/magisk/busybox"
fi

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

start_inotifyd() {
  PIDs=($($busybox pidof inotifyd))
  for PID in "${PIDs[@]}"; do
    if grep -q "box.inotify" "/proc/$PID/cmdline"; then
      kill -9 "$PID"
    fi
  done
  inotifyd "${scripts_dir}/box.inotify" "${moddir}" >> "/dev/null" 2>&1 &
}

mkdir -p /data/adb/box/run/
if [ -f "/data/adb/box/manual" ]; then
  exit 1
fi

if [ -f "$file_settings" ] && [ -r "$file_settings" ] && [ -s "$file_settings" ]; then
  refresh_box
  start_service
  enable_iptables
fi

start_inotifyd
