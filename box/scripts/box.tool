#!/system/bin/sh

scripts_dir="${0%/*}"
source /data/adb/box/settings.ini

# user agent
user_agent="box_for_root"
# whether use ghproxy to accelerate github download
url_ghproxy="https://mirror.ghproxy.com"
use_ghproxy="true"
# to enable/disable download the stable mihomo kernel
mihomo_stable="enable"

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
  request="busybox wget"
  request+=" --no-check-certificate"
  request+=" --user-agent ${user_agent}"
  request+=" -O ${file}"
  request+=" ${update_url}"
  echo "${yellow}${request}${normal}"
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
  # PIDS=("clash" "xray" "sing-box" "v2fly")
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
  case "${bin_name}" in
    sing-box)
      if ${bin_path} check -D "${box_dir}/${bin_name}" --config-directory "${box_dir}/sing-box" > "${box_run}/${bin_name}_report.log" 2>&1; then
        log Info "${sing_config} passed"
      else
        log Debug "${sing_config}"
        log Error "$(<"${box_run}/${bin_name}_report.log")" >&2
      fi
      ;;
    clash)
      if ${bin_path} -t -d "${box_dir}/clash" -f "${clash_config}" > "${box_run}/${bin_name}_report.log" 2>&1; then
        log Info "${clash_config} passed"
      else
        log Debug "${clash_config}"
        log Error "$(<"${box_run}/${bin_name}_report.log")" >&2
      fi
      ;;
    xray)
      export XRAY_LOCATION_ASSET="${box_dir}/xray"
      if ${bin_path} -test -confdir "${box_dir}/${bin_name}" > "${box_run}/${bin_name}_report.log" 2>&1; then
        log Info "configuration passed"
      else
        echo "$(ls ${box_dir}/${bin_name})"
        log Error "$(<"${box_run}/${bin_name}_report.log")" >&2
      fi
      ;;
    v2fly)
      export V2RAY_LOCATION_ASSET="${box_dir}/v2fly"
      if ${bin_path} test -d "${box_dir}/${bin_name}" > "${box_run}/${bin_name}_report.log" 2>&1; then
        log Info "configuration passed"
      else
        echo "$(ls ${box_dir}/${bin_name})"
        log Error "$(<"${box_run}/${bin_name}_report.log")" >&2
      fi
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
  if ! command -v curl >/dev/null 2>&1; then
    if [ ! -e "${bin_dir}/curl" ]; then
      log Debug "$bin_dir/curl file not found, unable to reload configuration"
      log Debug "start to download from github"
      upcurl || exit 1
    fi
    curl_command="${bin_dir}/curl"
  fi

  check

  case "${bin_name}" in
    "clash")
      if [ "${xclash_option}" = "mihomo" ]; then
        endpoint="http://${ip_port}/configs?force=true"
      else
        endpoint="http://${ip_port}/configs"
      fi

      if ${curl_command} -X PUT -H "Authorization: Bearer ${secret}" "${endpoint}" -d '{"path": "", "payload": ""}' 2>&1; then
        log Info "${bin_name} config reload success"
        return 0
      else
        log Error "${bin_name} config reload failed !"
        return 1
      fi
      ;;
    "sing-box")
      endpoint="http://${ip_port}/configs?force=true"
      if ${curl_command} -X PUT -H "Authorization: Bearer ${secret}" "${endpoint}" -d '{"path": "", "payload": ""}' 2>&1; then
        log Info "${bin_name} config reload success."
        return 0
      else
        log Error "${bin_name} config reload failed !"
        return 1
      fi
      ;;
    "xray"|"v2fly")
      if [ -f "${box_pid}" ]; then
        if kill -0 "$(<"${box_pid}" 2>/dev/null)"; then
          restart_box
        fi
      fi
      ;;
    *)
      log warning "${bin_name} not supported using API to reload config."
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
    "i686") arch="i686" ;;
    "x86_64") arch="amd64" ;;
    *) log Warning "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
  esac

  mkdir -p "${bin_dir}/backup"
  [ -f "${bin_dir}/curl" ] && cp "${bin_dir}/curl" "${bin_dir}/backup/curl.bak" >/dev/null 2>&1

  local latest_version=$(busybox wget --no-check-certificate -qO- "https://api.github.com/repos/stunnel/static-curl/releases" | grep "tag_name" | busybox grep -oE "[0-9.]*" | head -1)

  local download_link="https://github.com/stunnel/static-curl/releases/download/${latest_version}/curl-linux-${arch}-${latest_version}.tar.xz"

  log Debug "Download ${download_link}"
  upfile "${bin_dir}/curl.tar.xz" "${download_link}"

  if ! busybox tar -xJf "${bin_dir}/curl.tar.xz" -C "${bin_dir}" >&2; then
    log Error "Failed to extract ${bin_dir}/curl.tar.xz" >&2
    cp "${bin_dir}/backup/curl.bak" "${bin_dir}/curl" >/dev/null 2>&1 && log Info "Restored curl" || return 1
  fi

  chown "${box_user_group}" "${box_dir}/bin/curl"
  chmod 0700 "${bin_dir}/curl"

  rm -r "${bin_dir}/curl.tar.xz"
}

# Get latest yq
upyq() {
  local arch platform
  case $(uname -m) in
    "aarch64") arch="arm64"; platform="android" ;;
    "armv7l"|"armv8l") arch="arm"; platform="android" ;;
    "i686") arch="386"; platform="android" ;;
    "x86_64") arch="amd64"; platform="android" ;;
    *) log Warning "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
  esac

  local download_link="https://github.com/taamarin/yq/releases/download/prerelease/yq_${platform}_${arch}"

  log Debug "Download ${download_link}"
  upfile "${box_dir}/bin/yq" "${download_link}"

  chown "${box_user_group}" "${box_dir}/bin/yq"
  chmod 0700 "${box_dir}/bin/yq"
}

# Check and update geoip and geosite
upgeox() {
  # su -c /data/adb/box/scripts/box.tool geox
  geodata_mode=$(busybox awk '!/^ *#/ && /geodata-mode:*./{print $2}' "${clash_config}")
  [ -z "${geodata_mode}" ] && geodata_mode=false
  case "${bin_name}" in
    clash)
      geoip_file="${box_dir}/clash/$(if [[ "${xclash_option}" == "premium" || "${geodata_mode}" == "false" ]]; then echo "Country.mmdb"; else echo "GeoIP.dat"; fi)"
      geoip_url="https://github.com/$(if [[ "${xclash_option}" == "premium" || "${geodata_mode}" == "false" ]]; then echo "MetaCubeX/meta-rules-dat/raw/release/country-lite.mmdb"; else echo "MetaCubeX/meta-rules-dat/raw/release/geoip-lite.dat"; fi)"
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
  if [ "${update_geo}" = "true" ] && { log Info "daily updates geox" && log Debug "Downloading ${geoip_url}"; } && upfile "${geoip_file}" "${geoip_url}" && { log Debug "Downloading ${geosite_url}" && upfile "${geosite_file}" "${geosite_url}"; }; then

    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.db.bak" -delete
    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.dat.bak" -delete
    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.mmdb.bak" -delete

    log Debug "update geox $(date "+%F %R")"
    return 0
  else
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
            # If there is a yq command, extract the proxy information from the yml and output it to the clash_provide_config file
            if [ "${enhanced}" = "true" ]; then
              if ${yq} '.proxies' "${update_file_name}" >/dev/null 2>&1; then
                ${yq} '.proxies' "${update_file_name}" > "${clash_provide_config}"
                ${yq} -i '{"proxies": .}' "${clash_provide_config}"

                if [ "${custom_rules_subs}" = "true" ]; then
                  if ${yq} '.rules' "${update_file_name}" >/dev/null 2>&1; then

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
              else
                log Error "${update_file_name} update subscription failed"
                return 1
              fi
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
    "xray"|"v2fly"|"sing-box")
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

      latest_version=$(busybox wget --no-check-certificate -qO- "${api_url}" | grep "tag_name" | busybox grep -oE "v[0-9].*" | head -1 | cut -d'"' -f1)
      download_link="${url_down}/download/${latest_version}/sing-box-${latest_version#v}-${platform}-${arch}.tar.gz"
      log Debug "download ${download_link}"
      upfile "${box_dir}/${file_kernel}.tar.gz" "${download_link}" && xkernel
      ;;
    "clash")
      # if mihomo flag is false, download clash premium/dev
      if [ "${xclash_option}" = "mihomo" ]; then
        # set download link
        download_link="https://github.com/MetaCubeX/mihomo/releases"

        if [ "${mihomo_stable}" = "enable" ]; then
          latest_version=$(busybox wget --no-check-certificate -qO- "https://api.github.com/repos/MetaCubeX/mihomo/releases" | grep "tag_name" | busybox grep -oE "v[0-9.]*" | head -1)
          tag="$latest_version"
        else
          if [ "$use_ghproxy" == true ]; then
            download_link="${url_ghproxy}/${download_link}"
          fi
          tag="Prerelease-Alpha"
          latest_version=$(busybox wget --no-check-certificate -qO- "${download_link}/expanded_assets/${tag}" | busybox grep -oE "alpha-[0-9a-z]+" | head -1)
        fi
        # set the filename based on platform and architecture
        filename="mihomo-${platform}-${arch}-${latest_version}"
        # download and update the file
        log Debug "download ${download_link}/download/${tag}/${filename}.gz"
        upfile "${box_dir}/${file_kernel}.gz" "${download_link}/download/${tag}/${filename}.gz" && xkernel
      else
        log Warning "clash.${xclash_option} Repository has been deleted"
        # filename=$(busybox wget --no-check-certificate -qO- "https://github.com/Dreamacro/clash/releases/expanded_assets/premium" | busybox grep -oE "clash-linux-${arch}-[0-9]+.[0-9]+.[0-9]+" | head -1)
        # log Debug "download https://github.com/Dreamacro/clash/releases/download/premium/${filename}.gz"
        # upfile "${box_dir}/${file_kernel}.gz" "https://github.com/Dreamacro/clash/releases/download/premium/${filename}.gz" && xkernel
      fi
      ;;
    "xray"|"v2fly")
      [ "${bin_name}" = "xray" ] && bin='Xray' || bin='v2ray'
      api_url="https://api.github.com/repos/$(if [ "${bin_name}" = "xray" ]; then echo "XTLS/Xray-core/releases"; else echo "v2fly/v2ray-core/releases"; fi)"
      # set download link and get the latest version
      latest_version=$(busybox wget --no-check-certificate -qO- ${api_url} | grep "tag_name" | busybox grep -oE "v[0-9.]*" | head -1)

      case $(uname -m) in
        "i386") download_file="$bin-linux-32.zip" ;;
        "x86_64") download_file="$bin-linux-64.zip" ;;
        "armv7l"|"armv8l") download_file="$bin-linux-arm32-v7a.zip" ;;
        "aarch64") download_file="$bin-android-arm64-v8a.zip" ;;
        *) log Error "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
      esac
      # Do anything else below
      download_link="https://github.com/$(if [ "${bin_name}" = "xray" ]; then echo "XTLS/Xray-core/releases"; else echo "v2fly/v2ray-core/releases"; fi)"
      log Debug "Downloading ${download_link}/download/${latest_version}/${download_file}"
      upfile "${box_dir}/${file_kernel}.zip" "${download_link}/download/${latest_version}/${download_file}" && xkernel
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
      if ! command -v gunzip >/dev/null 2>&1; then
        gunzip_command="busybox gunzip"
      fi

      mkdir -p "${bin_dir}/xclash"
      if ${gunzip_command} "${box_dir}/${file_kernel}.gz" >&2 && mv "${box_dir}/${file_kernel}" "${bin_dir}/xclash/${xclash_option}"; then
        ln -sf "${bin_dir}/xclash/${xclash_option}" "${bin_dir}/${bin_name}"

        if [ -f "${box_pid}" ]; then
          restart_box
        else
          log Debug "${bin_name} does not need to be restarted."
        fi
      else
        log Error "Failed to extract or move the kernel."
      fi
      ;;
    "sing-box")
      tar_command="tar"
      if ! command -v tar >/dev/null 2>&1; then
        tar_command="busybox tar"
      fi
      if ${tar_command} -xf "${box_dir}/${file_kernel}.tar.gz" -C "${bin_dir}" >&2; then
        mv "${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}/sing-box" "${bin_dir}/${bin_name}"
        if [ -f "${box_pid}" ]; then
          rm -rf /data/adb/box/sing-box/cache.db
          restart_box
        else
          log Debug "${bin_name} does not need to be restarted."
        fi
      else
        log Error "Failed to extract ${box_dir}/${file_kernel}.tar.gz."
      fi
      [ -d "${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}" ] && \
        rm -r "${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}"
      ;;
    "v2fly"|"xray")
      bin="xray"
      if [ "${bin_name}" != "xray" ]; then
        bin="v2ray"
      fi
      unzip_command="unzip"
      if ! command -v unzip >/dev/null 2>&1; then
        unzip_command="busybox unzip"
      fi

      mkdir -p "${bin_dir}/update"
      if ${unzip_command} -o "${box_dir}/${file_kernel}.zip" "${bin}" -d "${bin_dir}/update" >&2; then
        if mv "${bin_dir}/update/${bin}" "${bin_dir}/${bin_name}"; then
          if [ -f "${box_pid}" ]; then
            restart_box
          else
            log Debug "${bin_name} does not need to be restarted."
          fi
        else
          log Error "Failed to move the kernel."
        fi
      else
        log Error "Failed to extract ${box_dir}/${file_kernel}.zip."
      fi
      rm -rf "${bin_dir}/update"
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
    url="https://github.com/MetaCubeX/metacubexd/archive/gh-pages.zip"
    if [ "$use_ghproxy" == true ]; then
      url="${url_ghproxy}/${url}"
    fi
    dir_name="metacubexd-gh-pages"
    log Debug "Download ${url}"
    if busybox wget --no-check-certificate "${url}" -O "${file_dashboard}" >&2; then
      if [ ! -d "${box_dir}/${xdashboard}" ]; then
        log Info "dashboard folder not exist, creating it"
        mkdir "${box_dir}/${xdashboard}"
      else
        rm -rf "${box_dir}/${xdashboard}/"*
      fi
      if command -v unzip >/dev/null 2>&1; then
        unzip_command="unzip"
      else
        unzip_command="busybox unzip"
      fi
      "${unzip_command}" -o "${file_dashboard}" "${dir_name}/*" -d "${box_dir}/${xdashboard}" >&2
      mv -f "${box_dir}/${xdashboard}/$dir_name"/* "${box_dir}/${xdashboard}/"
      rm -f "${file_dashboard}"
      rm -rf "${box_dir}/${xdashboard}/${dir_name}"
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

# Function to limit cgroup memcg
cgroup_blkio() {
  # Check if the cgroup blkio path is set and exists.
  if [ -z "${blkio_path}" ]; then
    local blkio_path=$(mount | grep cgroup | busybox awk '/blkio/{print $3}' | head -1)
    if [ -z "${blkio_path}" ]; then
      log Warning "blkio_path: is not set and could not be found"
      return 1
    fi
  else
    log Warning "leave the blkio_path: field empty to obtain the path."
    return 1
  fi

  # Check if box_pid is set and exists.
  if [ ! -f "${box_pid}" ]; then
    log Warning "${box_pid} does not exist"
    return 1
  fi

  local PID=$(<"${box_pid}" 2>/dev/null)
  if [ -d "${blkio_path}/background" ]; then
    if [ ! -z "$PID" ]; then
      # log Info "${bin_name} blkio: background"
      echo "$PID" >> "${blkio_path}/background/cgroup.procs" \
        && log Info "add $PID to ${blkio_path}/background/cgroup.procs"
    fi
  else
     return 1
  fi
  return 0
}

cgroup_memcg() {
  # Check if the cgroup memcg limit has been set.
  if [ -z "${memcg_limit}" ]; then
    log Warning "memcg_limit: is not set"
    return 1
  fi

  # Check if the cgroup memcg path is set and exists.
  if [ -z "${memcg_path}" ]; then
    local memcg_path=$(mount | grep cgroup | busybox awk '/memory/{print $3}' | head -1)
    if [ -z "${memcg_path}" ]; then
      log Warning "memcg_path: is not set and could not be found"
      return 1
    fi
  else
    log Warning "leave the memcg_path: field empty to obtain the path."
    return 1
  fi

  # Check if box_pid is set and exists.
  if [ ! -f "${box_pid}" ]; then
    log Warning "${box_pid} does not exist"
    return 1
  fi

  # Create cgroup directory and move process to cgroup.
  bin_name=${bin_name}
  # local bin_name=$(basename "$0")
  mkdir -p "${memcg_path}/${bin_name}"
  local PID=$(<"${box_pid}" 2>/dev/null)

  if [ ! -z "$PID" ]; then
    # Set memcg limit for cgroups.
    echo "${memcg_limit}" > "${memcg_path}/${bin_name}/memory.limit_in_bytes" \
      && log Info "${bin_name} memcg limit: ${memcg_limit}"

    echo "$PID" > "${memcg_path}/${bin_name}/cgroup.procs" \
      && log Info "add $PID to ${memcg_path}/${bin_name}/cgroup.procs"
  else
    return 1
  fi
  return 0
}

cgroup_cpuset() {
  # Check if the cgroup cpuset path is set and exists.
  if [ -z "${cpuset_path}" ]; then
    cpuset_path=$(mount | grep cgroup | busybox awk '/cpuset/{print $3}' | head -1)
    if [ -z "${cpuset_path}" ]; then
      log Warning "cpuset_path: is not set and could not be found"
      return 1
    fi
  else
    log Warning "leave the cpuset_path: field empty to obtain the path."
    return 1
  fi

  # Check if box_pid is set and exists.
  if [ ! -f "${box_pid}" ]; then
    log Warning "${box_pid} does not exist"
    return 1
  fi

  local PID=$(<"${box_pid}" 2>/dev/null)
  if [ -d "${cpuset_path}/top-app" ]; then
    if [ ! -z "$PID" ]; then
      # log Info "${bin_name} cpuset: $(cat ${cpuset_path}/top-app/cpus)"
      echo "$PID" >> "${cpuset_path}/top-app/cgroup.procs" \
        && log Info "add $PID to ${cpuset_path}/top-app/cgroup.procs"
    fi
  else
    return 1
  fi
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

bond1() {
  su -mm -c "cmd wifi force-low-latency-mode enabled"
  su -mm -c "sysctl -w net.ipv4.tcp_low_latency=1"
  su -mm -c "ip link set dev wlan0 txqueuelen 4000"
}

bond0() {
  su -mm -c "cmd wifi force-low-latency-mode disabled"
  su -mm -c "sysctl -w net.ipv4.tcp_low_latency=0"
  su -mm -c "ip link set dev wlan0 txqueuelen 3000"
}

case "$1" in
  check)
    check
    ;;
  memcg|cpuset|blkio)
  # leave it blank by default, it will fill in auto,
    case "$1" in
      memcg)
        memcg_path=""
        cgroup_memcg
        ;;
      cpuset)
        cpuset_path=""
        cgroup_cpuset
        ;;
      blkio)
        blkio_path=""
        cgroup_blkio
        ;;
    esac
    ;;
  bond0|bond1)
    $1
    ;;
  geosub)
    upsubs
    upgeox
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
  *)
    echo "${red}$0 $1 no found${normal}"
    echo "${yellow}usage${normal}: ${green}$0${normal} {${yellow}check|memcg|cpuset|blkio|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|webroot|bond0|bond1|all${normal}}"
    ;;
esac