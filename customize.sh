#!/system/bin/sh

# Script configuration variables
SKIPUNZIP=1
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true

# Check installation conditions
if [ "$BOOTMODE" != true ]; then
  abort "-----------------------------------------------------------"
  ui_print "! Please install in Magisk/KernelSU/APatch Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ]; then
  abort "-----------------------------------------------------------"
  ui_print "! Please update your KernelSU and KernelSU Manager"
  abort "-----------------------------------------------------------"
fi

service_dir="/data/adb/service.d"
if [ "$KSU" = "true" ]; then
  ui_print "— KernelSU version: $KSU_VER ($KSU_VER_CODE)"
  [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
elif [ "$APATCH" = "true" ]; then
  APATCH_VER=$(cat "/data/adb/ap/version")
  ui_print "— APatch version: $APATCH_VER"
else
  ui_print "— Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

# Set up service directory and clean old installations
mkdir -p "${service_dir}"
if [ -d "/data/adb/modules/box_for_magisk" ]; then
  rm -rf "/data/adb/modules/box_for_magisk"
  ui_print "— Old module deleted."
fi

# Extract files and configure directories
ui_print "— Installing Box for Magisk/KernelSU/APatch"
unzip -o "$ZIPFILE" -x 'META-INF/*' -x 'webroot/*' -d "$MODPATH" >&2
if [ -d "/data/adb/box" ]; then
  ui_print "— Backup existing box data"
  temp_bak=$(mktemp -d "/data/adb/box/box.XXXXXXXXXX")
  temp_dir="${temp_bak}"
  mv /data/adb/box/* "${temp_dir}/"
  mv "$MODPATH/box/"* /data/adb/box/
  backup_box="true"
else
  mv "$MODPATH/box" /data/adb/
fi

# Directory creation and file extraction
ui_print "— Create directories..."
mkdir -p /data/adb/box/ /data/adb/box/run/ /data/adb/box/bin/xclash/
mkdir -p $MODPATH/system/bin

ui_print "— Extracting..."
ui_print "     ↳  uninstall.sh → $MODPATH"
ui_print "     ↳  box_service.sh → ${service_dir}"
ui_print "     ↳  sbfr → $MODPATH/system/bin"
unzip -j -o "$ZIPFILE" 'uninstall.sh' -d "$MODPATH" >&2
unzip -j -o "$ZIPFILE" 'box_service.sh' -d "${service_dir}" >&2
unzip -j -o "$ZIPFILE" 'sbfr' -d "$MODPATH/system/bin" >&2

# Set permissions
ui_print "— Setting permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive /data/adb/box/ 0 3005 0755 0644
set_perm_recursive /data/adb/box/scripts/ 0 3005 0755 0700
set_perm ${service_dir}/box_service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
set_perm $MODPATH/system/bin/sbfr 0 0 0755

chmod ugo+x ${service_dir}/box_service.sh $MODPATH/uninstall.sh /data/adb/box/scripts/*

apply_mirror() {
  ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_print "— Do you want to use the 'ghfast.top' ?"
  ui_print "     ↳  mirror to speed up downloads"
  ui_print "— [ Vol UP(+): Yes ]"
  ui_print "— [ Vol DOWN(-): No ]"
  START_TIME=$(date +%s)
  while true ; do
    NOW_TIME=$(date +%s)
    timeout 1 getevent -lc 1 2>&1 | grep KEY_VOLUME > "$TMPDIR/events"
    if [ $(( NOW_TIME - START_TIME )) -gt 9 ]; then
      ui_print "— No input detected after 10 seconds..."
      ui_print "— ghfast acceleration enabled."
      sed -i 's/use_ghproxy=.*/use_ghproxy="true"/' /data/adb/box/scripts/box.tool
      break
    elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP); then
      ui_print "— ghfast acceleration enabled."
      sed -i 's/use_ghproxy=.*/use_ghproxy="true"/' /data/adb/box/scripts/box.tool
      break
    elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN); then
      ui_print "— ghfast acceleration disabled."
      sed -i 's/use_ghproxy=.*/use_ghproxy="false"/' /data/adb/box/scripts/box.tool
      break
    fi
  done
}

apply_mirror
timeout 1 getevent -cl >/dev/null

find_bin() {
  bin_dir="$temp_bak"

  check_bin() {
    local name="$1"
    local path="$bin_dir/bin/$name"
    if [ -e "$path" ]; then
        ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ui_print "📦  $name → ⭕ FOUND"
    else
        ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ui_print "📦  $name → ❌ NOT FOUND"
    fi
  }

  handle_download() {
    local bin="$1"
    local action=""
    case "$bin" in
      yq) action="upyq" ;;
      curl) action="upcurl" ;;
      *) action="all $bin" ;;
    esac

  START_TIME=$(date +%s)
  while true; do
    NOW_TIME=$(date +%s)
    timeout 1 getevent -lc 1 2>&1 | grep KEY_VOLUME > "$TMPDIR/events"
    
    if [ $(( NOW_TIME - START_TIME )) -gt 9 ]; then
      ui_print "— No input detected after 10 seconds..."
      if [ "$bin" = "clash" ]; then
        ui_print "— Download enabled for clash."
        /data/adb/box/scripts/box.tool $action
      else
        ui_print "— Download disabled for $bin."
      fi
      break
    elif grep -q KEY_VOLUMEUP "$TMPDIR/events"; then
      ui_print "— Download enabled."
      /data/adb/box/scripts/box.tool $action
      break
    elif grep -q KEY_VOLUMEDOWN "$TMPDIR/events"; then
      ui_print "— Download disabled."
      break
    fi
    done
  }

  # List of binaries to check
  for bin in sing-box v2fly xray curl yq hysteria; do
    timeout 1 getevent -cl >/dev/null

    check_bin "$bin"
    ui_print "— Do you want to download or update it?"
    ui_print "— [ Vol UP(+): Yes ]"
    ui_print "— [ Vol DOWN(-): No ]"
    handle_download "$bin"
  done

  # Special case for clash
  if [ -e "$bin_dir/bin/xclash/mihomo" ]; then
      ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      ui_print "📦  mihomo → ⭕ FOUND"
      ui_print "-- Do you want to download or update clash?"
      ui_print "— [ Vol UP(+): Yes ]"
      ui_print "— [ Vol DOWN(-): No ]"
      handle_download "clash"
  else
      ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      ui_print "📦  mihomo → ❌ NOT FOUND  "
      ui_print "— Do you want to download or update mihomo?"
      ui_print "— [ Vol UP(+): Yes ]"
      ui_print "— [ Vol DOWN(-): No ]"
      handle_download "clash"
  fi
}

find_bin
timeout 1 getevent -cl >/dev/null

# Restore backup configurations if present
if [ "${backup_box}" = "true" ]; then
  ui_print "— Restoring configurations..."
  ui_print "     ↳  xray"
  ui_print "     ↳  hysteria"
  ui_print "     ↳  clash"
  ui_print "     ↳  sing-box"
  ui_print "     ↳  v2fly"
  restore_config() {
    config_dir="$1"
    [ -d "${temp_dir}/${config_dir}" ] && cp -rf "${temp_dir}/${config_dir}/"* "/data/adb/box/${config_dir}/"
  }
  for dir in clash xray v2fly sing-box hysteria; do
    restore_config "$dir"
  done

  restore_kernel() {
    kernel_name="$1"
    if [ ! -f "/data/adb/box/bin/$kernel_name" ] && [ -f "${temp_dir}/bin/${kernel_name}" ]; then
      ui_print "— Restoring kernel ${kernel_name}..."
      cp -rf "${temp_dir}/bin/${kernel_name}" "/data/adb/box/bin/${kernel_name}"
    fi
  }

  for kernel in curl yq xray sing-box v2fly hysteria xclash/mihomo xclash/premium; do
    restore_kernel "$kernel"
  done

  ui_print "— Restoring..."
  ui_print "     ↳  *.logs"
  ui_print "     ↳  box.pid"
  ui_print "     ↳  uid.list"
  cp -rf "${temp_dir}/run/"* "/data/adb/box/run/"

  ui_print "— Restoring..."
  ui_print "     ↳  ap.list.cfg"
  ui_print "     ↳  crontab.cfg"
  ui_print "     ↳  package.list.cfg"
  cp -rf "${temp_dir}/ap.list.cfg" "/data/adb/box/ap.list.cfg"
  cp -rf "${temp_dir}/crontab.cfg" "/data/adb/box/crontab.cfg"
  cp -rf "${temp_dir}/package.list.cfg" "/data/adb/box/package.list.cfg"
fi

# create_resolv() {
  # # Check if the resolv.conf file exists
  # if [ ! -f /system/etc/resolv.conf ]; then
    # # Ensure the target directory exists before writing the file
    # mkdir -p "$MODPATH/system/etc/security/cacerts/"
    # # Create resolv.conf with the specified nameservers
    # cat > "$MODPATH/system/etc/resolv.conf" <<EOF
# # nameserver 8.8.8.8
# # nameserver 1.1.1.1
# # nameserver 114.114.114.114
# EOF
  # fi
  # ui_print "— create $MODPATH/system/etc/resolv.conf"
# }
# create_resolv

# Update module description if no kernel binaries are found
[ -z "$(find /data/adb/box/bin -type f)" ] && sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 😱 Module installed but manual Kernel download required ] /g' $MODPATH/module.prop

# Customize module name based on environment
if [ "$KSU" = "true" ]; then
  sed -i "s/name=.*/name=Box for KernelSU/g" $MODPATH/module.prop
elif [ "$APATCH" = "true" ]; then
  sed -i "s/name=.*/name=Box for APatch/g" $MODPATH/module.prop
else
  sed -i "s/name=.*/name=Box for Magisk/g" $MODPATH/module.prop
fi
unzip -o "$ZIPFILE" 'webroot/*' -d "$MODPATH" >&2

# Clean up temporary files
ui_print "— Cleaning up leftover files"
rm -rf /data/adb/box/bin/.bin $MODPATH/box $MODPATH/sbfr $MODPATH/box_service.sh

ui_print ""
# Create a symbolic link to run /dev/sbfr as a shortcut to sbfr
ln -sf "$MODPATH/system/bin/sbfr" /dev/sbfr
ui_print "— Shortcut '/dev/sbfr' created."
ui_print "     ↳  You can now run: su -c /dev/sbfr"
ui_print ""
# Complete installation
ui_print "— Installation complete. Please reboot your device."
ui_print "— Report issues to t.me.taamarin"
