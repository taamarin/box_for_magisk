#!/system/bin/sh

moddir="/data/adb/modules/box_for_root"
if [ -n "$(magisk -v | grep lite)" ]; then
  moddir="/data/adb/lite_modules/box_for_root"
fi

scripts_dir="/data/adb/box/scripts"

refresh_box() {
  if [ -f "/data/adb/box/run/box.pid" ]; then
    "${scripts_dir}/box.service" stop >> "/dev/null" 2>&1
    "${scripts_dir}/box.iptables" disable >> "/dev/null" 2>&1
  fi
}

start_service() {
  if [ ! -f "/data/adb/box/manual" ]; then
    [ ! -f "${moddir}/disable" ] && "${scripts_dir}/box.service" start >> "/dev/null" 2>&1
    [ -f "/data/adb/box/run/box.pid" ] && "${scripts_dir}/box.iptables" enable >> "/dev/null" 2>&1

    for pid in $(pidof inotifyd) ; do
      if grep -q box.inotify /proc/${pid}/cmdline ; then
        kill ${pid}
      fi
    done
    inotifyd "${scripts_dir}/box.inotify" "${moddir}" >> "/dev/null" 2>&1 &
  fi
}

refresh_box
start_service