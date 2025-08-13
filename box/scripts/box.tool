#!/system/bin/sh

scripts_dir="${0%/*}"
source /data/adb/box/settings.ini

# user agent
user_agent="box_for_root"
# whether use ghproxy to accelerate github download
url_ghproxy="https://mirror.ghproxy.com"
use_ghproxy="false"
# to enable/disable download the stable mihomo kernel
mihomo_stable="enable"
singbox_stable="enable"

rev1="busybox wget --no-check-certificate -qO-"
if which curl >/dev/null; then
  rev1="curl --insecure -sL"
fi

# Updating files from URLs
upfile() {
  file="$1"
  update_url="$2"
  file_bak="${file}.bak"
  if [ -f "${file}" ]; then
    mv "${file}" "${file_bak}" || return 1
  fi
  # Use ghproxy
  if [ "${use_ghproxy}" == true ] && [[ "${update_url}" == @(https://github.com/*|https://raw.githubusercontent.com/*|https://gist.github.com/*|https://gist.githubusercontent.com/*) ]]; then
    update_url="${url_ghproxy}/${update_url}"
  fi
  # request
  if which curl >/dev/null; then
    # curl="$(which curl || echo /data/adb/box/bin/curl)"
    request="curl"
    request+=" -L"
    request+=" --insecure"
    request+=" --user-agent ${user_agent}"
    request+=" -o ${file}"
    request+=" ${update_url}"
    echo "${yellow}${request}${normal}"
  else
    request="busybox wget"
    request+=" --no-check-certificate"
    request+=" --user-agent ${user_agent}"
    request+=" -O ${file}"
    request+=" ${update_url}"
    echo "${yellow}${request}${normal}"
  fi
  ${request} >&2 || {
    if [ -f "${file_bak}" ]; then
      mv "${file_bak}" "${file}" || true
    fi
    log Error "Download ${request} ${orange}failed${normal}"
    return 1
  }
  return 0
}

# Restart the binary, after stopping and running again
restart_box() {
  "${scripts_dir}/box.service" restart
  # PIDS=("clash" "xray" "sing-box" "v2fly" "hysteria")
  PIDS=(${bin_name})
  PID=""
  i=0
  while [ -z "$PID" ] && [ "$i" -lt "${#PIDS[@]}" ]; do
    PID=$(busybox pidof "${PIDS[$i]}")
    i=$((i+1))
  done

  if [ -n "$PID" ]; then
    log Debug "${bin_name} Restart complete [$(date +"%F %R")]"
  else
    log Error "Failed to restart ${bin_name}."
    ${scripts_dir}/box.iptables disable >/dev/null 2>&1
  fi
}

# Check Configuration
check() {
  # su -c /data/adb/box/scripts/box.tool rconf
  log Info "Checking configuration for <${bin_name}>..."

  case "${bin_name}" in
    sing-box)
      if ${bin_path} check -D "${box_dir}/${bin_name}" --config-directory "${box_dir}/sing-box" >/dev/null; then
        log Info "${sing_config} passed"
      else
        log Error "Configuration check failed for sing-box"
        return 1
      fi
      ;;
    clash)
      if ${bin_path} -t -d "${box_dir}/clash" -f "${clash_config}" 2>/dev/null; then
        log Info "${clash_config} passed"
      else
        log Error "Configuration check failed for clash"
        return 1
      fi
      ;;
    xray)
      export XRAY_LOCATION_ASSET="${box_dir}/xray"
      if ${bin_path} -test -confdir "${box_dir}/${bin_name}" 2>/dev/null; then
        log Info "Xray configuration passed"
      else
        log Error "Configuration check failed for xray"
        return 1
      fi
      ;;
    v2fly)
      export V2RAY_LOCATION_ASSET="${box_dir}/v2fly"
      if ${bin_path} test -d "${box_dir}/${bin_name}" >/dev/null; then
        log Info "V2Fly configuration passed"
      else
        log Error "Configuration check failed for v2fly"
        return 1
      fi
      ;;
    hysteria)
      log Info "No configuration check implemented for hysteria, skipping."
      ;;
    *)
      log Error "<${bin_name}> unknown binary."
      exit 1
      ;;
  esac
}

# reload base config
reload() {
  curl_command="curl"

  # Pastikan curl tersedia
  if ! command -v curl >/dev/null; then
    if [ ! -x "${bin_dir}/curl" ]; then
      log Debug "${bin_dir}/curl not found, downloading..."
      upcurl || { log Error "Failed to install curl"; return 1; }
    fi
    curl_command="${bin_dir}/curl"
  fi

  # Cek config sebelum reload
  if ! check; then
    log Error "Configuration check failed, aborting reload."
    return 1
  fi

  case "${bin_name}" in
    clash|sing-box)
      if [ "${bin_name}" = "clash" ] && [ "${xclash_option}" = "mihomo" ]; then
        endpoint="http://${ip_port}/configs?force=true"
      else
        endpoint="http://${ip_port}/configs"
      fi

      if ${curl_command} -sS -X PUT \
        -H "Authorization: Bearer ${secret}" \
        "${endpoint}" \
        -d '{"path": "", "payload": ""}'; then
        log Info "${bin_name} configuration reloaded successfully."
      else
        log Error "${bin_name} configuration reload failed!"
        return 1
      fi
      ;;
    xray|v2fly|hysteria)
      if [ -f "${box_pid}" ]; then
        pid="$(<"${box_pid}")"
        if kill -0 "$pid" 2>/dev/null; then
          log Info "Restarting ${bin_name} (PID: $pid)"
          restart_box
        else
          log Error "${bin_name} process not running!"
          return 1
        fi
      else
        log Error "PID file for ${bin_name} not found!"
        return 1
      fi
      ;;
    *)
      log Warning "${bin_name} does not support API reload."
      return 1
      ;;
  esac
}

# Get latest curl
upcurl() {
  local arch
  case $(uname -m) in
    "aarch64") arch="aarch64" ;;
    "armv7l"|"armv8l") arch="armv7" ;;
    "i686")    arch="i686" ;;
    "x86_64")  arch="amd64" ;;
    *)
      log Warning "Unsupported architecture: $(uname -m)"
      return 1
      ;;
  esac
  log Info "Detected architecture: $(uname -m) -> ${arch}"

  # Backup existing curl if present
  log Info "Ensuring backup directory: ${bin_dir}/backup"
  mkdir -p "${bin_dir}/backup"
  if [ -f "${bin_dir}/curl" ]; then
    log Info "Backing up existing curl to ${bin_dir}/backup/curl.bak"
    cp "${bin_dir}/curl" "${bin_dir}/backup/curl.bak" >/dev/null 2>&1
  else
    log Debug "No existing curl binary found, skipping backup."
  fi

  # Fetch latest version from GitHub
  log Info "Fetching latest static-curl version..."
  local latest_version=$($rev1 "https://api.github.com/repos/stunnel/static-curl/releases" \
    | grep "tag_name" | busybox grep -oE "[0-9.]*" | head -1)

  if [ -z "$latest_version" ]; then
    log Error "Failed to retrieve latest static-curl version."
    return 1
  fi
  log Info "Latest curl version: ${latest_version}"

  # Download
  local download_link="https://github.com/stunnel/static-curl/releases/download/${latest_version}/curl-linux-${arch}-glibc-${latest_version}.tar.xz"
  log Info "Downloading from: ${download_link}"
  if ! upfile "${bin_dir}/curl.tar.xz" "${download_link}"; then
    log Error "Failed to download curl binary."
    return 1
  fi

  # Extract
  log Info "Extracting ${bin_dir}/curl.tar.xz..."
  if busybox tar -xJf "${bin_dir}/curl.tar.xz" -C "${bin_dir}" >&2; then
    log Info "Extraction successful."
  else
    log Error "Failed to extract ${bin_dir}/curl.tar.xz"
    if cp "${bin_dir}/backup/curl.bak" "${bin_dir}/curl" >/dev/null 2>&1; then
      log Info "Restored curl from backup."
    else
      log Error "Failed to restore curl from backup."
      return 1
    fi
  fi

  # Permissions
  log Info "Setting ownership and permissions..."
  chown "${box_user_group}" "${bin_dir}/curl"
  chmod 0700 "${bin_dir}/curl"

  # Cleanup
  log Info "Removing archive: ${bin_dir}/curl.tar.xz"
  rm -f "${bin_dir}/curl.tar.xz"

  log Info "Curl update process completed."
}

# Get latest yq
upyq() {
  local arch platform
  case $(uname -m) in
    "aarch64")  arch="arm64"; platform="android" ;;
    "armv7l"|"armv8l") arch="arm";   platform="android" ;;
    "i686")     arch="386";   platform="android" ;;
    "x86_64")   arch="amd64"; platform="android" ;;
    *)
      log Warning "Unsupported architecture: $(uname -m)"
      return 1
      ;;
  esac
  log Info "Detected architecture: $(uname -m) -> platform=${platform}, arch=${arch}"

  # Backup existing yq if exists
  log Info "Ensuring backup directory: ${bin_dir}/backup"
  mkdir -p "${bin_dir}/backup"
  if [ -f "${box_dir}/bin/yq" ]; then
    log Info "Backing up existing yq to ${bin_dir}/backup/yq.bak"
    cp "${box_dir}/bin/yq" "${bin_dir}/backup/yq.bak" >/dev/null 2>&1
  else
    log Debug "No existing yq binary found, skipping backup."
  fi

  # Download link
  local download_link="https://github.com/taamarin/yq/releases/download/prerelease/yq_${platform}_${arch}"
  log Info "Downloading yq from: ${download_link}"
  if ! upfile "${box_dir}/bin/yq" "${download_link}"; then
    log Error "Failed to download yq binary."
    if cp "${bin_dir}/backup/yq.bak" "${box_dir}/bin/yq" >/dev/null 2>&1; then
      log Info "Restored yq from backup."
    else
      log Error "Failed to restore yq from backup."
    fi
    return 1
  fi

  # Permissions
  log Info "Setting ownership and permissions for yq"
  chown "${box_user_group}" "${box_dir}/bin/yq"
  chmod 0700 "${box_dir}/bin/yq"

  log Info "yq update process completed."
}

# Check and update geoip and geosite
upgeox() {
  # su -c /data/adb/box/scripts/box.tool geox
  geodata_mode=$(busybox awk '!/^ *#/ && /geodata-mode:*./{print $2}' "${clash_config}")
  [ -z "${geodata_mode}" ] && geodata_mode=false
  log Info "Geodata mode: ${geodata_mode}"

  case "${bin_name}" in
    clash)
      if [[ "${xclash_option}" == "premium" || "${geodata_mode}" == "false" ]]; then
        geoip_file="${box_dir}/clash/Country.mmdb"
        geoip_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/country-lite.mmdb"
      else
        geoip_file="${box_dir}/clash/GeoIP.dat"
        geoip_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip-lite.dat"
      fi
      geosite_file="${box_dir}/clash/GeoSite.dat"
      geosite_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.dat"
      ;;
    sing-box)
      geoip_file="${box_dir}/sing-box/geoip.db"
      geoip_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip-lite.db"
      geosite_file="${box_dir}/sing-box/geosite.db"
      geosite_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.db"
      ;;
    *)
      geoip_file="${box_dir}/${bin_name}/geoip.dat"
      geoip_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip-lite.dat"
      geosite_file="${box_dir}/${bin_name}/geosite.dat"
      geosite_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.dat"
      ;;
  esac

  if [ "${update_geo}" = "true" ]; then
    log Info "Starting daily geox update..."

    log Info "Downloading GeoIP file from: ${geoip_url}"
    if upfile "${geoip_file}" "${geoip_url}"; then
      log Info "GeoIP file updated: ${geoip_file}"
    else
      log Error "Failed to download GeoIP file."
      return 1
    fi

    log Info "Downloading GeoSite file from: ${geosite_url}"
    if upfile "${geosite_file}" "${geosite_url}"; then
      log Info "GeoSite file updated: ${geosite_file}"
    else
      log Error "Failed to download GeoSite file."
      return 1
    fi

    log Info "Cleaning old backup files..."
    find "${box_dir}/${bin_name}" -maxdepth 1 -type f \( -name "*.db.bak" -o -name "*.dat.bak" -o -name "*.mmdb.bak" \) -delete

    log Info "Geo data updated successfully at $(date '+%F %R')"
    return 0
  else
    log Info "Geo update disabled, skipping."
    return 1
  fi
}

# Check and update subscription
upsubs() {
  enhanced=false
  update_file_name="${clash_config}"
  if [ "${renew}" != "true" ]; then
    yq="yq"
    if ! command -v yq &>/dev/null; then
      if [ ! -e "${box_dir}/bin/yq" ]; then
        log Debug "yq file not found, start to download from github"
        ${scripts_dir}/box.tool upyq
      fi
      yq="${box_dir}/bin/yq"
    fi
    enhanced=true
    update_file_name="${update_file_name}.subscription"
  fi

  case "${bin_name}" in
    "clash")
      # subscription clash
      if [ -n "${subscription_url_clash}" ]; then
        if [ "${update_subscription}" = "true" ]; then
          log Info "daily updates subs"
          log Debug "Downloading ${update_file_name}"
          if upfile "${update_file_name}" "${subscription_url_clash}"; then
            log Info "${update_file_name} saved"
            # Make sure the folder exists
            mkdir -p "$(dirname "$clash_provide_config")"
            touch "$clash_provide_config"
            # If there is a yq command, extract the proxy information from the yml and output it to the clash_provide_config file
            if [ "${enhanced}" = "true" ]; then
              if ${yq} 'has("proxies")' "${update_file_name}" | grep -q "true"; then
                ${yq} '.proxies' "${update_file_name}" >/dev/null 2>&1
                ${yq} '.proxies' "${update_file_name}" > "${clash_provide_config}"
                ${yq} -i '{"proxies": .}' "${clash_provide_config}"

                if [ "${custom_rules_subs}" = "true" ]; then
                  if ${yq} '.rules' "${update_file_name}" >/dev/null; then

                    ${yq} '.rules' "${update_file_name}" > "${clash_provide_rules}"
                    ${yq} -i '{"rules": .}' "${clash_provide_rules}"
                    ${yq} -i 'del(.rules)' "${clash_config}"

                    cat "${clash_provide_rules}" >> "${clash_config}"
                  fi
                fi
                log Info "subscription success"
                log Info "Update subscription $(date +"%F %R")"
                if [ -f "${update_file_name}.bak" ]; then
                  rm "${update_file_name}.bak"
                fi
              elif ${yq} '.. | select(tag == "!!str")' "${update_file_name}" | grep -qE "vless://|vmess://|ss://|hysteria://|trojan://"; then
                mv "${update_file_name}" "${clash_provide_config}"
              else
                log Error "${update_file_name} update subscription failed"
                return 1
              fi
            else
              if [ -f "${box_pid}" ]; then
                kill -0 "$(<"${box_pid}" 2>/dev/null)" && \
                $scripts_dir/box.service restart 2>/dev/null
                exit 1
              fi
              return 1
            fi
            return 0
          else
            log Error "update subscription failed"
            return 1
          fi
        else
          log Warning "update subscription: $update_subscription"
          return 1
        fi
      else
        log Warning "${bin_name} subscription url is empty..."
        return 0
      fi
      ;;
    "xray"|"v2fly"|"sing-box"|"hysteria")
      log Warning "${bin_name} does not support subscriptions.."
      return 1
      ;;
    *)
      log Error "<${bin_name}> unknown binary."
      return 1
      ;;
  esac
}

upkernel() {
  # su -c /data/adb/box/scripts/box.tool upkernel
  mkdir -p "${bin_dir}/backup"
  if [ -f "${bin_dir}/${bin_name}" ]; then
    cp "${bin_dir}/${bin_name}" "${bin_dir}/backup/${bin_name}.bak" >/dev/null 2>&1
  fi
  case $(uname -m) in
    "aarch64") if [ "${bin_name}" = "clash" ]; then arch="arm64-v8"; else arch="arm64"; fi; platform="android" ;;
    "armv7l"|"armv8l") arch="armv7"; platform="linux" ;;
    "i686") arch="386"; platform="linux" ;;
    "x86_64") arch="amd64"; platform="linux" ;;
    *) log Warning "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  # Do anything else below
  file_kernel="${bin_name}-${arch}"
  case "${bin_name}" in
    "sing-box")
      api_url="https://api.github.com/repos/SagerNet/sing-box/releases"
      url_down="https://github.com/SagerNet/sing-box/releases"
    
      if [ "${singbox_stable}" = "disable" ]; then
        log Info "Fetching ${bin_name} pre-release version info..."
        latest_version=$($rev1 "${api_url}" \
          | grep "tag_name" | busybox grep -oE "v[0-9].*" | head -1 | cut -d'"' -f1)
      else
        log Info "Fetching ${bin_name} latest stable version info..."
        latest_version=$($rev1 "${api_url}/latest" \
          | grep "tag_name" | busybox grep -oE "v[0-9.]*" | head -1)
      fi
    
      if [ -z "$latest_version" ]; then
        log Error "Failed to get latest version of sing-box."
        return 1
      fi
      log Info "Latest ${bin_name} version: ${latest_version}"
    
      download_link="${url_down}/download/${latest_version}/sing-box-${latest_version#v}-${platform}-${arch}.tar.gz"
      log Info "Downloading from: ${download_link}"
    
      if upfile "${box_dir}/${file_kernel}.tar.gz" "${download_link}"; then
        log Info "Download completed: ${box_dir}/${file_kernel}.tar.gz"
        log Info "Installing ${bin_name}..."
        xkernel
      else
        log Error "Failed to download ${bin_name} binary."
        return 1
      fi
      ;;
    "clash")
      # If mihomo flag is active, download mihomo, otherwise give a warning.
      if [ "${xclash_option}" = "mihomo" ]; then
        download_link="https://github.com/MetaCubeX/mihomo/releases"
        log Info "Updating Clash (mihomo) kernel from ${download_link}"

        if [ "${mihomo_stable}" = "enable" ]; then
          log Info "Fetching latest stable version..."
          latest_version=$($rev1 "https://api.github.com/repos/MetaCubeX/mihomo/releases" \
            | grep "tag_name" | busybox grep -oE "v[0-9.]*" | head -1)
          if [ -z "${latest_version}" ]; then
            log Error "Failed to retrieve latest stable version."
            return 1
          fi
          tag="$latest_version"
          log Info "Latest stable version: ${tag}"
        else
          log Info "Fetching latest alpha (Prerelease) version..."
          if [ "$use_ghproxy" == true ]; then
            log Info "Using GHProxy mirror: ${url_ghproxy}"
            download_link="${url_ghproxy}/${download_link}"
          fi
          tag="Prerelease-Alpha"
          latest_version=$($rev1 "${download_link}/expanded_assets/${tag}" \
            | busybox grep -oE "alpha-[0-9a-z]+" | head -1)
          if [ -z "${latest_version}" ]; then
            log Error "Failed to retrieve latest alpha version."
            return 1
          fi
          log Info "Latest alpha version: ${latest_version}"
        fi

        # Set file names according to platform and architecture
        filename="mihomo-${platform}-${arch}-${latest_version}"
        log Info "Preparing to download: ${filename}.gz"

        # Download file
        full_url="${download_link}/download/${tag}/${filename}.gz"
        log Info "Downloading from: ${full_url}"
        if upfile "${box_dir}/${file_kernel}.gz" "${full_url}"; then
          log Info "Download completed successfully: ${box_dir}/${file_kernel}.gz"
          log Info "Installing kernel..."
          xkernel
        else
          log Error "Failed to download mihomo binary."
          return 1
        fi
      else
        log Warning "clash.${xclash_option} repository has been deleted."
      fi
      ;;
    "xray"|"v2fly")
      # Specify the binary name
      if [ "${bin_name}" = "xray" ]; then
        bin='Xray'
        repo_path="XTLS/Xray-core/releases"
      else
        bin='v2ray'
        repo_path="v2fly/v2ray-core/releases"
      fi
      api_url="https://api.github.com/repos/${repo_path}"
    
      log Info "Updating ${bin_name} from ${repo_path}"
      log Info "Fetching latest release info from ${api_url}..."
    
      # Get the latest version
      latest_version=$($rev1 "${api_url}" | grep "tag_name" | busybox grep -oE "v[0-9.]*" | head -1)
      if [ -z "${latest_version}" ]; then
        log Error "Failed to retrieve latest version for ${bin_name}."
        exit 1
      fi
      log Info "Latest ${bin_name} version: ${latest_version}"
    
      # Specify files according to architecture
      case $(uname -m) in
        "i386")    download_file="${bin}-linux-32.zip" ;;
        "x86_64")  download_file="${bin}-linux-64.zip" ;;
        "armv7l"|"armv8l") download_file="${bin}-linux-arm32-v7a.zip" ;;
        "aarch64") download_file="${bin}-android-arm64-v8a.zip" ;;
        *)
          log Error "Unsupported architecture: $(uname -m)"
          exit 1
          ;;
      esac
      log Info "Detected architecture: $(uname -m) -> file: ${download_file}"
    
      # Set link download
      download_link="https://github.com/${repo_path}"
      full_url="${download_link}/download/${latest_version}/${download_file}"
      log Info "Downloading from: ${full_url}"
    
      # Download & execute xkernel
      if upfile "${box_dir}/${file_kernel}.zip" "${full_url}"; then
        log Info "Download completed: ${box_dir}/${file_kernel}.zip"
        log Info "Extracting and installing..."
        xkernel
      else
        log Error "Failed to download ${bin_name} binary."
        exit 1
      fi
      ;;
    "hysteria")
      local arch
      case $(uname -m) in
        "aarch64") arch="arm64" ;;
        "armv7l" | "armv8l") arch="armv7" ;;
        "i686")    arch="386" ;;
        "x86_64")  arch="amd64" ;;
        *)
          log Warning "Unsupported architecture: $(uname -m)"
          return 1
          ;;
      esac
      log Info "Detected architecture: $(uname -m) -> ${arch}"
    
      # Create backup directory if it doesn't exist
      log Info "Ensuring backup directory exists: ${bin_dir}/backup"
      mkdir -p "${bin_dir}/backup"
    
      # Backup existing Hysteria binary if it exists
      if [ -f "${bin_dir}/hysteria" ]; then
        log Info "Backing up existing Hysteria binary to ${bin_dir}/backup/hysteria.bak"
        cp "${bin_dir}/hysteria" "${bin_dir}/backup/hysteria.bak" >/dev/null 2>&1
      else
        log Debug "No existing Hysteria binary found, skipping backup."
      fi
    
      # Fetch the latest version of Hysteria from GitHub releases
      log Info "Fetching latest Hysteria version from GitHub..."
      local latest_version=$($rev1 "https://api.github.com/repos/apernet/hysteria/releases" \
        | grep "tag_name" | grep -oE "[0-9.].*" | head -1 | sed 's/,//g' | cut -d '"' -f 1)
    
      if [ -z "${latest_version}" ]; then
        log Error "Failed to retrieve latest Hysteria version."
        return 1
      fi
      log Info "Latest Hysteria version: v${latest_version}"
    
      local download_link="https://github.com/apernet/hysteria/releases/download/app%2Fv${latest_version}/hysteria-android-${arch}"
      log Info "Downloading Hysteria from: ${download_link}"
    
      if upfile "${bin_dir}/hysteria" "${download_link}"; then
        log Info "Hysteria binary downloaded successfully to ${bin_dir}/hysteria"
        log Info "Reloading kernel..."
        xkernel
      else
        log Error "Failed to download Hysteria binary."
        return 1
      fi
      ;;
    *)
      log Error "<${bin_name}> unknown binary."
      exit 1
      ;;
  esac
}

# Check and update kernel
xkernel() {
  case "${bin_name}" in
    "clash")
      gunzip_command="gunzip"
      if ! command -v gunzip >/dev/null; then
        gunzip_command="busybox gunzip"
        log Info "Using busybox gunzip"
      else
        log Info "Using system gunzip"
      fi

      mkdir -p "${bin_dir}/xclash" && \
      log Info "Creating directory: ${bin_dir}/xclash"

      log Info "Extracting kernel: ${box_dir}/${file_kernel}.gz"
      if ${gunzip_command} "${box_dir}/${file_kernel}.gz" >&2; then
        log Info "Extraction successful: ${box_dir}/${file_kernel}"
      
        log Info "Moving kernel to ${bin_dir}/xclash/${xclash_option}"
        if mv "${box_dir}/${file_kernel}" "${bin_dir}/xclash/${xclash_option}"; then
          log Info "Kernel moved successfully."
      
          log Info "Creating symlink: ${bin_dir}/${bin_name} -> ${bin_dir}/xclash/${xclash_option}"
          ln -sf "${bin_dir}/xclash/${xclash_option}" "${bin_dir}/${bin_name}"
      
          if [ -f "${box_pid}" ]; then
            log Info "Restarting ${bin_name} service..."
            restart_box
          else
            log Debug "${bin_name} does not need to be restarted."
          fi
        else
          log Error "Failed to move the extracted kernel."
        fi
      else
        log Error "Failed to extract kernel: ${box_dir}/${file_kernel}.gz"
      fi
      ;;
    "sing-box")
      tar_command="tar"
      if ! command -v tar >/dev/null; then
        tar_command="busybox tar"
        log Info "Using busybox tar"
      else
        log Info "Using system tar"
      fi
      
      log Info "Extracting kernel archive: ${box_dir}/${file_kernel}.tar.gz"
      if ${tar_command} -xf "${box_dir}/${file_kernel}.tar.gz" -C "${bin_dir}" >&2; then
        log Info "Extraction successful."
      
        src_dir="${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}"
        log Info "Moving binary from ${src_dir}/sing-box to ${bin_dir}/${bin_name}"
        if mv "${src_dir}/sing-box" "${bin_dir}/${bin_name}"; then
          log Info "Kernel binary moved successfully."
      
          if [ -f "${box_pid}" ]; then
            log Info "Removing cache.db for clean restart..."
            rm -rf /data/adb/box/sing-box/cache.db
      
            log Info "Restarting ${bin_name}..."
            restart_box
          else
            log Debug "${bin_name} does not need to be restarted."
          fi
        else
          log Error "Failed to move binary from ${src_dir}."
        fi
      else
        log Error "Failed to extract ${box_dir}/${file_kernel}.tar.gz."
      fi
      
      if [ -d "${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}" ]; then
        log Info "Cleaning up extracted directory: ${src_dir}"
        rm -r "${src_dir}"
      fi
      ;;
    "v2fly"|"xray")
      bin="xray"
      if [ "${bin_name}" != "xray" ]; then
        bin="v2ray"
      fi
      log Info "Selected binary to extract: ${bin}"
      
      unzip_command="unzip"
      if ! command -v unzip >/dev/null; then
        unzip_command="busybox unzip"
        log Info "Using busybox unzip"
      else
        log Info "Using system unzip"
      fi
      
      log Info "Creating temporary update directory: ${bin_dir}/update"
      mkdir -p "${bin_dir}/update"
      
      log Info "Extracting ${bin} from ${box_dir}/${file_kernel}.zip..."
      if ${unzip_command} -o "${box_dir}/${file_kernel}.zip" "${bin}" -d "${bin_dir}/update" >&2; then
        log Info "Extraction successful."
      
        log Info "Moving ${bin} binary to ${bin_dir}/${bin_name}"
        if mv "${bin_dir}/update/${bin}" "${bin_dir}/${bin_name}"; then
          log Info "Kernel binary moved successfully."
      
          if [ -f "${box_pid}" ]; then
            log Info "Restarting ${bin_name}..."
            restart_box
          else
            log Debug "${bin_name} does not need to be restarted."
          fi
        else
          log Error "Failed to move the kernel binary from ${bin_dir}/update/${bin}."
        fi
      else
        log Error "Failed to extract ${box_dir}/${file_kernel}.zip."
      fi
      
      log Info "Cleaning up temporary directory: ${bin_dir}/update"
      rm -rf "${bin_dir}/update"
      ;;
    "hysteria")
      if [ -f "${box_pid}" ]; then
        restart_box
      else
        log Debug "${bin_name} does not need to be restarted."
      fi
      ;;
    *)
      log Error "<${bin_name}> unknown binary."
      exit 1
      ;;
  esac

  find "${box_dir}" -maxdepth 1 -type f -name "${file_kernel}.*" -delete
  chown ${box_user_group} ${bin_path}
  chmod 6755 ${bin_path}
}

# Check and update yacd
upxui() {
  # su -c /data/adb/box/scripts/box.tool upxui
  xdashboard="${bin_name}/dashboard"
  if [[ "${bin_name}" == @(clash|sing-box) ]]; then
    file_dashboard="${box_dir}/${xdashboard}.zip"
    url="https://github.com/Zephyruso/zashboard/archive/gh-pages.zip"
    if [ "$use_ghproxy" == true ]; then
      url="${url_ghproxy}/${url}"
    fi
    dir_name="zashboard-gh-pages"
    log Debug "Download ${url}"

    if which curl >/dev/null; then
      rev2="curl -L --insecure ${url} -o"
    else
      rev2="busybox wget --no-check-certificate ${url} -O"
    fi

    if $rev2 "${file_dashboard}" >&2; then
      log Info "Dashboard file downloaded: ${file_dashboard}"
    
      if [ ! -d "${box_dir}/${xdashboard}" ]; then
        log Info "Dashboard folder not exist, creating it"
        mkdir "${box_dir}/${xdashboard}"
      else
        log Info "Dashboard folder exists, cleaning old files"
        rm -rf "${box_dir}/${xdashboard}/"*
      fi
    
      if command -v unzip >/dev/null; then
        unzip_command="unzip"
        log Info "Using system unzip"
      else
        unzip_command="busybox unzip"
        log Info "Using busybox unzip"
      fi
    
      log Info "Extracting dashboard from ${file_dashboard}..."
      "${unzip_command}" -o "${file_dashboard}" "${dir_name}/*" -d "${box_dir}/${xdashboard}" >&2
    
      log Info "Moving extracted files to ${box_dir}/${xdashboard}/"
      mv -f "${box_dir}/${xdashboard}/$dir_name"/* "${box_dir}/${xdashboard}/"
    
      log Info "Cleaning up temporary files"
      rm -f "${file_dashboard}"
      rm -rf "${box_dir}/${xdashboard}/${dir_name}"
    
      log Info "Dashboard update completed successfully"
    else
      log Error "Failed to download dashboard" >&2
      return 1
    fi
    return 0
  else
    log Debug "${bin_name} does not support dashboards"
    return 1
  fi
}

cgroup_blkio() {
  local pid_file="$1"
  local fallback_weight="${2:-900}"  # default weight jika pakai 'box'

  if [ -z "$pid_file" ] || [ ! -f "$pid_file" ]; then
    log Warning "PID file missing or invalid: $pid_file"
    return 1
  fi

  local PID=$(<"$pid_file" 2>/dev/null)
  if [ -z "$PID" ] || ! kill -0 "$PID" >/dev/null; then
    log Warning "Invalid or dead PID: $PID"
    return 1
  fi

  # Temukan blkio path
  if [ -z "$blkio_path" ]; then
    blkio_path=$(mount | busybox awk '/blkio/ {print $3}' | head -1)
    if [ -z "$blkio_path" ] || [ ! -d "$blkio_path" ]; then
      log Warning "blkio path not found"
      return 1
    fi
  fi

  # Pilih target group: foreground jika ada, jika tidak buat box
  local target
  if [ -d "${blkio_path}/foreground" ]; then
    target="${blkio_path}/foreground"
    log Info "Using existing blkio group: foreground"
  else
    target="${blkio_path}/box"
    mkdir -p "$target"
    echo "$fallback_weight" > "${target}/blkio.weight"
    log Info "Created blkio group: box with weight $fallback_weight"
  fi

  echo "$PID" > "${target}/cgroup.procs" \
    && log Info "Assigned PID $PID to $target"

  return 0
}

cgroup_memcg() {
  local pid_file="$1"
  local raw_limit="$2"

  if [ -z "$pid_file" ] || [ ! -f "$pid_file" ]; then
    log Warning "PID file missing or invalid: $pid_file"
    return 1
  fi

  if [ -z "$raw_limit" ]; then
    log Warning "memcg limit not specified"
    return 1
  fi

  local limit
  case "$raw_limit" in
    *[Mm])
      limit=$(( ${raw_limit%[Mm]} * 1024 * 1024 ))
      ;;
    *[Gg])
      limit=$(( ${raw_limit%[Gg]} * 1024 * 1024 * 1024 ))
      ;;
    *[Kk])
      limit=$(( ${raw_limit%[Kk]} * 1024 ))
      ;;
    *[0-9])
      limit=$raw_limit  # assume raw bytes
      ;;
    *)
      log Warning "Invalid memcg limit format: $raw_limit"
      return 1
      ;;
  esac

  local PID
  PID=$(<"$pid_file" 2>/dev/null)
  if [ -z "$PID" ] || ! kill -0 "$PID" >/dev/null; then
    log Warning "Invalid or dead PID: $PID"
    return 1
  fi

  # Deteksi memcg_path jika belum diset
  if [ -z "$memcg_path" ]; then
    memcg_path=$(mount | grep cgroup | busybox awk '/memory/{print $3}' | head -1)
    if [ -z "$memcg_path" ] || [ ! -d "$memcg_path" ]; then
      log Warning "memcg path could not be determined"
      return 1
    fi
  fi

  # Gunakan bin_name jika tersedia, default ke 'app'
  local name="${bin_name:-app}"
  local target="${memcg_path}/${name}"
  mkdir -p "$target"

  echo "$limit" > "${target}/memory.limit_in_bytes" \
    && log Info "Set memory limit for $name: ${limit} bytes"

  echo "$PID" > "${target}/cgroup.procs" \
    && log Info "Assigned PID $PID to ${target}"

  return 0
}

cgroup_cpuset() {
  local pid_file="${1}"
  local cores="${2}"

  if [ -z "${pid_file}" ] || [ ! -f "${pid_file}" ]; then
    log Warning "Missing or invalid PID file: ${pid_file}"
    return 1
  fi

  local PID
  PID=$(<"${pid_file}" 2>/dev/null)
  if [ -z "$PID" ] || ! kill -0 "$PID" >/dev/null; then
    log Warning "PID $PID from ${pid_file} is not valid or not running"
    return 1
  fi

  # Deteksi jumlah core jika cores belum ditentukan
  if [ -z "${cores}" ]; then
    local total_core
    total_core=$(nproc --all 2>/dev/null)
    if [ -z "$total_core" ] || [ "$total_core" -le 0 ]; then
      log Warning "Failed to detect CPU cores"
      return 1
    fi
    cores="0-$((total_core - 1))"
  fi

  # Deteksi cpuset_path
  if [ -z "${cpuset_path}" ]; then
    cpuset_path=$(mount | grep cgroup | busybox awk '/cpuset/{print $3}' | head -1)
    if [ -z "${cpuset_path}" ] || [ ! -d "${cpuset_path}" ]; then
      log Warning "cpuset path not found"
      return 1
    fi
  fi

  local cpuset_target="${cpuset_path}/foreground"
  if [ ! -d "${cpuset_target}" ]; then
    cpuset_target="${cpuset_path}/top-app"
  elif [ ! -d "${cpuset_target}" ]; then
    cpuset_target="${cpuset_path}/apps"
    [ ! -d "${cpuset_target}" ] && log Warning "cpuset target not found" && return 1
  fi

  echo "${cores}" > "${cpuset_target}/cpus"
  echo "0" > "${cpuset_target}/mems"

  echo "${PID}" > "${cpuset_target}/cgroup.procs" \
    && log Info "Assigned PID $PID to ${cpuset_target} with CPU cores [$cores]"

  return 0
}

ip_port=$(if [ "${bin_name}" = "clash" ]; then busybox awk '/external-controller:/ {print $2}' "${clash_config}"; else find /data/adb/box/sing-box/ -type f -name 'config.json' -exec busybox awk -F'[:,]' '/external_controller/ {print $2":"$3}' {} \; | sed 's/^[ \t]*//;s/"//g'; fi;)
secret=""

webroot() {
path_webroot="/data/adb/modules/box_for_root/webroot/index.html"
touch -n > $path_webroot
  if [[ "${bin_name}" = @(clash|sing-box) ]]; then
    echo -e '
  <!DOCTYPE html>
  <script>
      document.location = 'http://127.0.0.1:9090/ui/'
  </script>
  </html>
  ' > $path_webroot
    sed -i "s#document\.location =.*#document.location = 'http://$ip_port/ui/'#" $path_webroot
  else
   echo -e '
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Unsupported Dashboard</title>
      <style>
          body {
              font-family: Arial, sans-serif;
              text-align: center;
              padding: 50px;
          }
          h1 {
              color: red;
          }
      </style>
  </head>
  <body>
      <h1>Unsupported Dashboard</h1>
      <p>Sorry, xray/v2ray does not support the necessary Dashboard features.</p>
  </body>
  </html>' > $path_webroot
  fi
}

bond0() {
  # Menonaktifkan mode low latency untuk TCP
  sysctl -w net.ipv4.tcp_low_latency=0 >/dev/null 2>&1
  log Debug "tcp low latency: 0"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 3000 untuk semua interface wireless (wlan*)
  for dev in /sys/class/net/wlan*; do ip link set dev $(basename $dev) txqueuelen 3000; done
  log Debug "wlan* txqueuelen: 3000"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 1000 untuk semua interface rmnet_data*
  for txqueuelen in /sys/class/net/rmnet_data*; do txqueuelen_name=$(basename $txqueuelen); ip link set dev $txqueuelen_name txqueuelen 1000; done
  log Debug "rmnet_data* txqueuelen: 1000"

  # Mengatur MTU (Maximum Transmission Unit) menjadi 1500 untuk semua interface rmnet_data*
  for mtu in /sys/class/net/rmnet_data*; do mtu_name=$(basename $mtu); ip link set dev $mtu_name mtu 1500; done
  log Debug "rmnet_data* mtu: 1500"
}

bond1() {
  # Mengaktifkan mode low latency untuk TCP
  sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
  log Debug "tcp low latency: 1"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 4000 untuk semua interface wireless (wlan*)
  for dev in /sys/class/net/wlan*; do ip link set dev $(basename $dev) txqueuelen 4000; done
  log Debug "wlan* txqueuelen: 4000"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 2000 untuk semua interface rmnet_data*
  for txqueuelen in /sys/class/net/rmnet_data*; do txqueuelen_name=$(basename $txqueuelen); ip link set dev $txqueuelen_name txqueuelen 2000; done
  log Debug "rmnet_data* txqueuelen: 2000"

  # Mengatur MTU (Maximum Transmission Unit) menjadi 9000 untuk semua interface rmnet_data*
  for mtu in /sys/class/net/rmnet_data*; do mtu_name=$(basename $mtu); ip link set dev $mtu_name mtu 9000; done
  log Debug "rmnet_data* mtu: 9000"
}

case "$1" in
  check)
    check
    ;;
  memcg|cpuset|blkio)
    case "$1" in
      memcg)
        memcg_path=""
        cgroup_memcg "${box_pid}" ${memcg_limit}
        ;;
      cpuset)
        cpuset_path=""
        cgroup_cpuset "${box_pid}" ${allow_cpu}
        ;;
      blkio)
        blkio_path=""
        cgroup_blkio "${box_pid}" "${weight}"
        ;;
    esac
    ;;
  bond0|bond1)
    $1
    ;;
  geosub)
    upgeox
    upsubs
    if [ -f "${box_pid}" ]; then
      kill -0 "$(<"${box_pid}" 2>/dev/null)" && reload
    fi
    ;;
  geox|subs)
    if [ "$1" = "geox" ]; then
      upgeox
    else
      upsubs
      [ "${bin_name}" != "clash" ] && exit 1
    fi
    if [ -f "${box_pid}" ]; then
      kill -0 "$(<"${box_pid}" 2>/dev/null)" && reload
    fi
    ;;
  upkernel)
    upkernel
    ;;
  upxui)
    upxui
    ;;
  upyq|upcurl)
    $1
    ;;
  reload)
    reload
    ;;
  webroot)
    webroot
    ;;
  all)
    upyq
    upcurl
    for bin_name in "${bin_list[@]}"; do
      upkernel
      upgeox
      upsubs
      upxui
    done
    ;;
  help|-h|--help|"")
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  check       - Check Configuration"
    echo "  memcg       - Apply memory cgroup limit to process"
    echo "  cpuset      - Apply CPU core affinity to process"
    echo "  blkio       - Apply I/O weight limit to process"
    echo "  bond0|bond1 - Run bonding configuration functions"
    echo "  geosub      - Update both subscription and GeoX files, then reload if running"
    echo "  geox        - Update GeoX database, then reload if running"
    echo "  subs        - Update subscription (only for clash), then reload if running"
    echo "  upkernel    - Update kernel-related components"
    echo "  upxui       - Update XUI panel"
    echo "  upyq        - Update yq binary"
    echo "  upcurl      - Update curl binary"
    echo "  reload      - Reload running service configuration"
    echo "  webroot     - Update/rebuild webroot files"
    echo "  all         - Run all update commands in sequence"
    echo
    echo "Example:"
    echo "  $0 check"
    ;;
  *)
    echo "${red}$0 $1 not found${normal}"
    echo "Run '$0 help' for usage."
    ;;
esac