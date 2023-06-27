#!/system/bin/sh

moddir="/data/adb/modules/box_for_root"
if [ -n "$(magisk -v | grep lite)" ]; then
  moddir="/data/adb/lite_modules/box_for_root"
fi

if [ -f "/data/adb/magisk/busybox" ]; then
  busybox="/data/adb/magisk/busybox"
elif [ -f "/data/adb/ksu/bin/busybox" ]; then
  busybox="/data/adb/ksu/bin/busybox"
fi

scripts_dir="/data/adb/box/scripts"

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
      PID=$(${busybox} pidof "${PIDS[$i]}")
      i=$((i+1))
    done

    if [ -n "$PID" ]; then
      "${scripts_dir}/box.iptables" enable >> "/dev/null" 2>&1
    fi
}

start_inotifyd() {
    for PID in $(${busybox} pidof inotifyd); do
      if grep -q box.inotify /proc/$PID/cmdline; then
        kill -15 ${pid}
      fi
    done
    inotifyd "${scripts_dir}/box.inotify" "${moddir}" >> "/dev/null" 2>&1 &
}

refresh_box
if [ ! -f "/data/adb/box/manual" ]; then
    start_service
    enable_iptables
    start_inotifyd
fi