
SKIPUNZIP=1
ASH_STANDALONE=1

SKIPUNZIP=1
ASH_STANDALONE=1

if [ "$BOOTMODE" ! = true ] ; then
  ui_print "*********************************************************"
  ui_print "! Please install in Magisk Manager or KernelSU Manager"
  ui_print "! Install from recovery is NOT supported"
  ui_print "! Some recovery has broken implementations, install with such recovery will finally cause BFM modules not working"
  abort "*********************************************************"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ] ; then
  abort "Error: Please update your KernelSU and KernelSU Manager or KernelSU Manager"
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
else 
  service_dir="/data/adb/service.d"
fi

if [ ! -d "${service_dir}" ] ; then
    mkdir -p "${service_dir}"
fi

if [ "$KSU" = true ] ; then
  sed -i "s/name=.*/name=Box for KernelSU/g" "${MODPATH}/module.prop"
fi

ui_print "- Installing Box for Magisk/KernelSU"
if [ -d "/data/adb/box" ]; then
    ui_print "- Backup box"
    latest=$(date '+%Y-%m-%d_%H-%M-%S')
    mkdir -p "/data/adb/box/${latest}"
    mv /data/adb/box/* "/data/adb/box/${latest}/"
fi

ui_print "- Set architecture ${ARCH}"
case "${ARCH}" in
  arm)
    architecture="armv7"
    ;;
  arm64)
    architecture="armv8"
    ;;
  x86)
    architecture="386"
    ;;
  x64)
    architecture="amd64"
    ;;
  *)
    abort "Error: Unsupported architecture ${ARCH}"
    ;;
esac

ui_print "- Create directories"
mkdir -p "${MODPATH}/system/bin"
mkdir -p "${MODPATH}/system/etc/security/cacerts"
mkdir -p "/data/adb/box"
mkdir -p "/data/adb/box/bin"
mkdir -p "/data/adb/box/run"
mkdir -p "/data/adb/box/scripts"
mkdir -p "/data/adb/box/xray"
mkdir -p "/data/adb/box/v2fly"
mkdir -p "/data/adb/box/sing-box"
mkdir -p "/data/adb/box/clash"
mkdir -p "/data/adb/box/dashboard"
mkdir -p "/data/adb/box/clash/dashboard"
mkdir -p "/data/adb/box/sing-box/dashboard"

ui_print "- Extract the ZIP file and skip the META-INF folder into the ${MODPATH} folder"
unzip -o "${ZIPFILE}" -x 'META-INF/*' -d "${MODPATH}" >&2

ui_print "- Extract the files uninstall.sh and box_service.sh into the ${MODPATH} folder and ${service_dir}"
unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d "${MODPATH}" >&2
unzip -j -o "${ZIPFILE}" 'box_service.sh' -d "${service_dir}" >&2

ui_print "- Extract the files from the binary archive and copy them to the /system/bin and /data/adb/box/bin"
tar -xjf "${MODPATH}/binary/${ARCH}.tar.bz2" -C "${MODPATH}/system/bin" >&2
tar -xjf "${MODPATH}/binary/${ARCH}.tar.bz2" "mlbox" -C /data/adb/box/bin >&2

ui_print "- Extract the dashboard.zip file to the folder /data/adb/box/clash/dashboard and /data/adb/box/sing-box/dashboard"
unzip -o "${MODPATH}/dashboard.zip" -d /data/adb/box/dashboard/ >&2
unzip -o "${MODPATH}/dashboard.zip" -d /data/adb/box/clash/dashboard/ >&2
unzip -o "${MODPATH}/dashboard.zip" -d /data/adb/box/sing-box/dashboard/ >&2

ui_print "- Move BFM files"
mv "$MODPATH/scripts/cacert.pem" "$MODPATH/system/etc/security/cacerts"
mv "$MODPATH/scripts/src/"* "/data/adb/box/scripts/"
mv "$MODPATH/scripts/clash/"* "/data/adb/box/clash/"
mv "$MODPATH/scripts/settings.ini" "/data/adb/box/"
mv "$MODPATH/scripts/xray" "/data/adb/box/"
mv "$MODPATH/scripts/v2fly" "/data/adb/box/"
mv "$MODPATH/scripts/sing-box" "/data/adb/box/"

ui_print "- Delete leftover files"
rm -rf "${MODPATH}/scripts"
rm -rf "${MODPATH}/binary"
rm -f "${MODPATH}/box_service.sh"
rm -f "${MODPATH}/dashboard.zip"
sleep 1

ui_print "- Setting permissions"
set_perm_recursive "${MODPATH}" 0 0 0755 0644
set_perm_recursive "/data/adb/box/" 0 3005 0755 0644
set_perm_recursive "/data/adb/box/scripts/" 0 3005 0755 0700
set_perm "${service_dir}/box_service.sh"  0  0  0755
set_perm "${MODPATH}/service.sh"  0  0  0755
set_perm "${MODPATH}/uninstall.sh"  0  0  0755
set_perm "${MODPATH}/system/etc/security/cacerts/cacert.pem" 0 0 0644
set_perm "${MODPATH}/system/bin/curl"  0  0  0755
# fix "set_perm_recursive /data/adb/box/scripts" not working on some phones.
chmod ugo+x /data/adb/box/scripts/*
set_perm /data/adb/box/scripts/box.inotify  0  0  0755
set_perm /data/adb/box/scripts/box.service  0  0  0755
set_perm /data/adb/box/scripts/box.iptables  0  0  0755
set_perm /data/adb/box/scripts/box.tool  0  0  0755
set_perm /data/adb/box/scripts/start.sh  0  0  0755
set_perm /data/adb/box/bin/mlbox  0  0  0755

sleep 1

ui_print ""
ui_print "********************************************************"
ui_print "- do you want to download KERNEL and GEOX?"
ui_print "- Make sure you have a good internet connection."
ui_print "- Vol Up: to download GEOX and KERNEL."
ui_print "- Vol Down: to ignore downloading GEOX and KERNEL."
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

ui_print "- Installation is complete, reboot your device"
ui_print ""
ui_print "- Notes: "
ui_print "- report issues to @taamarin on Telegram"
ui_print "- Join @taamarin on telegram to get more updates"