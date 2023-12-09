#!/system/bin/sh

SKIPUNZIP=1
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true

if [ "$BOOTMODE" != true ]; then
  ui_print "! Please install in Magisk Manager or KernelSU Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ]; then
  abort "error: Please update your KernelSU and KernelSU Manager"
fi

if [ "$API" -lt 28 ]; then
  ui_print "! Unsupported sdk: $API"
  abort "! Minimal supported sdk is 28 (Android 9)"
else
  ui_print "- Device sdk: $API"
fi

service_dir="/data/adb/service.d"
if [ "$KSU" = true ]; then
  ui_print "- kernelSU version: $KSU_VER ($KSU_VER_CODE)"
  [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
else
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

mkdir -p "${service_dir}"

if [ -d "/data/adb/modules/box_for_magisk" ]; then
  rm -rf "/data/adb/modules/box_for_magisk"
  ui_print "- Old module deleted."
fi

ui_print "- Installing Box for Magisk/KernelSU"
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

if [ -d "/data/adb/box" ]; then
  ui_print "- Backup box"
  temp_bak=$(mktemp -d "/data/adb/box/box.XXXXXXXXXX")
  temp_dir="${temp_bak}"
  mv /data/adb/box/* "${temp_dir}/"
  mv "$MODPATH/box/"* /data/adb/box/
  backup_box="true"
else
  mv "$MODPATH/box" /data/adb/
fi

ui_print "- Create directories"
mkdir -p $MODPATH/system/bin/
mkdir -p /data/adb/box/
mkdir -p /data/adb/box/run/
mkdir -p /data/adb/box/bin/xclash/

ui_print "- Extract the files uninstall.sh and box_service.sh into the $MODPATH folder and ${service_dir}"
unzip -j -o "$ZIPFILE" 'uninstall.sh' -d "$MODPATH" >&2
unzip -j -o "$ZIPFILE" 'box_service.sh' -d "${service_dir}" >&2

ui_print "- Setting permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive /data/adb/box/ 0 3005 0755 0644
set_perm_recursive /data/adb/box/scripts/  0 3005 0755 0700
set_perm ${service_dir}/box_service.sh  0  0  0755
set_perm $MODPATH/service.sh  0  0  0755
set_perm $MODPATH/uninstall.sh  0  0  0755
set_perm /data/adb/box/scripts/  0  0  0755

# fix "set_perm_recursive /data/adb/box/scripts" not working on some phones.
chmod ugo+x /data/adb/box/scripts/*

ui_print "-----------------------------------------------------------"
ui_print "- Do you want to download Kernel(xray clash v2fly sing-box) and GeoX(geosite geoip mmdb)? size: ±100MB."
ui_print "- Make sure you have a good internet connection."
ui_print "- [ Vol UP(+): Yes ]"
ui_print "- [ Vol DOWN(-): No ]"

while true ; do
  getevent -lc 1 2>&1 | grep KEY_VOLUME > $TMPDIR/events
  if $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP) ; then
    ui_print "- It will take a while...."
    /data/adb/box/scripts/box.tool all
    break
  elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN) ; then
    ui_print "- Skip download Kernel and Geox"
    break
  fi
done

if [ "${backup_box}" = "true" ]; then
  ui_print "- Restore configuration xray, clash, sing-box, and v2fly"
  restore_config() {
    config_dir="$1"
    if [ -d "${temp_dir}/${config_dir}" ]; then
      cp -rf "${temp_dir}/${config_dir}/"* "/data/adb/box/${config_dir}/"
    fi
  }

  restore_config "clash"
  restore_config "xray"
  restore_config "v2fly"
  restore_config "sing-box"

  restore_kernel() {
    kernel_name="$1"
    if [ ! -f "/data/adb/box/bin/$kernel_name" ] && [ -f "${temp_dir}/bin/${kernel_name}" ]; then
      ui_print "- Restore ${kernel_name} kernel"
      cp -rf "${temp_dir}/bin/${kernel_name}" "/data/adb/box/bin/${kernel_name}"
    fi
  }

  restore_kernel "curl"
  restore_kernel "yq"
  restore_kernel "xray"
  restore_kernel "sing-box"
  restore_kernel "v2fly"
  restore_kernel "xclash/mihomo"
  restore_kernel "xclash/premium"

  ui_print "- Restore logs, pid and uid.list"
  cp "${temp_dir}/run/"* "/data/adb/box/run/"
fi

if [ -z "$(find /data/adb/box/bin -type f)" ]; then
  sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 😱 Module installed but you need to download Kernel(xray clash v2fly sing-box) and GeoX(geosite geoip mmdb) manually ] /g' $MODPATH/module.prop
fi

[ "$KSU" = "true" ] && sed -i "s/name=.*/name=Box for KernelSU/g" $MODPATH/module.prop || sed -i "s/name=.*/name=Box for Magisk/g" $MODPATH/module.prop

ui_print "- Delete leftover files"
rm -rf /data/adb/box/bin/.bin
rm -rf $MODPATH/box
rm -f $MODPATH/box_service.sh

ui_print "- Installation is complete, reboot your device"
ui_print "- Report issues to t.me.taamarin"
