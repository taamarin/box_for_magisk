#!/sbin/sh

SKIPUNZIP=1
ASH_STANDALONE=1

### INSTALLATION ###

if [ "$BOOTMODE" != true ]; then
  ui_print "-----------------------------------------------------------"
  ui_print "! Please install in Magisk Manager or KernelSU Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ]; then
  abort "ERROR: Please update your KernelSU and KernelSU Manager"
fi

# check android
if [ "$API" -lt 28 ]; then
  ui_print "! Unsupported sdk: $API"
  abort "! Minimal supported sdk is 28 (Android 9)"
else
  ui_print "- Device sdk: $API"
fi

# check version
service_dir="/data/adb/service.d"
if [ "$KSU" = true ]; then
  ui_print "- kernelSU version: $KSU_VER ($KSU_VER_CODE)"
  [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
else
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

if [ ! -d "${service_dir}" ]; then
  mkdir -p "${service_dir}"
fi

if [ -d "/data/adb/modules/box_for_magisk" ]; then
  rm -rf "/data/adb/modules/box_for_magisk"
  ui_print "- old module deleted."
fi

ui_print "- Installing Box for Magisk/KernelSU"
ui_print "- Extract the ZIP file and skip the META-INF folder into the $MODPATH folder"
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

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
unzip -j -o "$ZIPFILE" 'uninstall.sh' -d "$MODPATH" >&2
unzip -j -o "$ZIPFILE" 'box_service.sh' -d "${service_dir}" >&2

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

ui_print "-----------------------------------------------------------"
ui_print "- Do you want to download KERNEL(xray clash v2fly sing-box) and GEOX(geosite geoip mmdb)? size: ±100MB."
ui_print "- Make sure you have a good internet connection."
ui_print "- [ Vol UP(+): Yes ] / [ Vol DOWN(-): No ]"

while true ; do
  getevent -lc 1 2>&1 | grep KEY_VOLUME > $TMPDIR/events
  if $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP) ; then
    ui_print "- it will take a while...."
    /data/adb/box/scripts/box.tool all
    break
  elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN) ; then
    sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 🙁 Module installed but you need to download KERNEL(xray clash v2fly sing-box) and GEOX(geosite geoip mmdb) manually ] /g' $MODPATH/module.prop
    ui_print "- skip download KERNEL and GEOX" && break
  fi
done

[ "$KSU" = "true" ] && sed -i "s/name=.*/name=Box for KernelSU/g" $MODPATH/module.prop || sed -i "s/name=.*/name=Box for Magisk/g" $MODPATH/module.prop

ui_print "- Installation is complete, reboot your device"
ui_print "- report issues to @taamarin on Telegram"