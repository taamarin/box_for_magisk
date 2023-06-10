#!/sbin/sh

SKIPUNZIP=1
ASH_STANDALONE=1

if [ "$BOOTMODE" ! = true ] ; then
  ui_print "-----------------------------------------------------------"
  ui_print "! Please install in Magisk Manager or KernelSU Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ] ; then
  abort "ERROR: Please update your KernelSU and KernelSU Manager or KernelSU Manager"
fi

# check Magisk
if [ "$KSU" ! = true ] ; then
    ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

# check android
if [ "$API" -lt 28 ]; then
  ui_print "! Unsupported sdk: $API"
  abort "! Minimal supported sdk is 28 (Android 9)"
else
  ui_print "- Device sdk: $API"
fi

if [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10683 ] ; then
  service_dir="/data/adb/ksu/service.d"
  busybox="/data/adb/ksu/bin/busybox"
else 
  service_dir="/data/adb/service.d"
  busybox="/data/adb/magisk/busybox"
fi

if [ ! -d "${service_dir}" ] ; then
    mkdir -p "${service_dir}"
fi

if [ -d "/data/adb/modules/box_for_magisk" ]; then
  rm -rf "/data/adb/modules/box_for_magisk"
  ui_print "- Old module deleted."
fi

ui_print "- Installing Box for Magisk/KernelSU"
ui_print "- Extract the ZIP file and skip the META-INF folder into the $MODPATH folder"
unzip -o "${ZIPFILE}" -x 'META-INF/*' -d "${MODPATH}" >&2

if [ -d "/data/adb/box" ]; then
  ui_print "- Backup box"
  latest=$(date '+%Y-%m-%d_%H-%M')
  mkdir -p "/data/adb/box/${latest}"
  mv /data/adb/box/* "/data/adb/box/${latest}/"
  mv $MODPATH/box/* /data/adb/box/
else
  mv $MODPATH/box /data/adb/
fi

ui_print "- Create directories"
mkdir -p $MODPATH/system/bin/
mkdir -p /data/adb/box/run/

ui_print "- Extract the files uninstall.sh and box_service.sh into the $MODPATH folder and ${service_dir}"
unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d "${MODPATH}" >&2
unzip -j -o "${ZIPFILE}" 'box_service.sh' -d "${service_dir}" >&2

ui_print "- Delete leftover files"
rm -rf $MODPATH/box
rm -f $MODPATH/box_service.sh

ui_print "- Setting permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive /data/adb/box/ 0 3005 0755 0644
set_perm_recursive /data/adb/box/scripts/  0 3005 0755 0700
set_perm ${service_dir}/box_service.sh  0  0  0755
set_perm $MODPATH/service.sh  0  0  0755
set_perm $MODPATH/uninstall.sh  0  0  0755
set_perm /data/adb/box/scripts/box.inotify  0  0  0755
set_perm /data/adb/box/scripts/box.service  0  0  0755
set_perm /data/adb/box/scripts/box.iptables  0  0  0755
set_perm /data/adb/box/scripts/box.tool  0  0  0755
set_perm /data/adb/box/scripts/start.sh  0  0  0755

# fix "set_perm_recursive /data/adb/box/scripts" not working on some phones.
chmod ugo+x /data/adb/box/scripts/*

ui_print ""
ui_print "-----------------------------------------------------------"
ui_print "- do you want to download KERNEL and GEOX?"
ui_print "- Make sure you have a good internet connection."
ui_print "- [ Vol UP: Yes ]"
ui_print "- [ Vol DOWN: No ]"
while true ; do
  getevent -lc 1 2>&1 | grep KEY_VOLUME > $TMPDIR/events
  sleep 1
  if $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP) ; then
    ui_print "- it will take a while...."
    /data/adb/box/scripts/box.tool all && echo "- downloads are complete."
    break
  elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN) ; then
     ui_print "- ignore download GEOX and KERNEL"
    break
  fi
done

for pid in $(${busybox} pidof inotifyd) ; do
  if grep -q box.inotify /proc/${pid}/cmdline ; then
    kill ${pid}
  fi
done

inotifyd "/data/adb/box/scripts/box.inotify" "/data/adb/modules/box_for_root" > /dev/null 2>&1 &

if [ "$KSU" = true ]; then
  sed -i "s/name=.*/name=Box for KernelSU/g" "${MODPATH}/module.prop"
else
  sed -i "s/name=.*/name=Box for Magisk/g" "${MODPATH}/module.prop"
fi

ui_print "- Installation is complete, reboot your device"
ui_print "- report issues to @taamarin on Telegram"