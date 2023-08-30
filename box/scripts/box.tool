#!/system/bin/sh

scripts=$(realpath "$0")
scripts_dir=$(dirname "${scripts}")
source /data/adb/box/settings.ini

# user agent
user_agent="box_for_root"
# whether use ghproxy to accelerate github download
use_ghproxy=false

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

# Updating files from URLs
update_file() {
  file="$1"
  update_url="$2"
  file_bak="${file}.bak"
  if [ -f "${file}" ]; then
    mv "${file}" "${file_bak}" || return 1
  fi
  # Use ghproxy
  if [ "${use_ghproxy}" == true ] && [[ "${update_url}" == @(https://github.com/*|https://raw.githubusercontent.com/*|https://gist.github.com/*|https://gist.githubusercontent.com/*) ]]; then
    update_url="https://ghproxy.com/${update_url}"
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

# Get latest yq
update_yq() {
  # su -c /data/adb/box/scripts/box.tool upyq
  case $(uname -m) in
    "aarch64") arch="arm64"; platform="android" ;;
    "armv7l"|"armv8l") arch="arm"; platform="android" ;;
    "i686") arch="386"; platform="android" ;;
    "x86_64") arch="amd64"; platform="android" ;;
    *) log Warning "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  # If you use yq_linux, an error will occur (cmd: mkdir /tmp permission denied) when using a cron job.
  # download_link="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}"
  download_link="https://github.com/taamarin/yq/releases/download/prerelease/yq_${platform}_${arch}"

  log Debug "Download ${download_link}"
  update_file "${box_dir}/bin/yq" "${download_link}"
  chown "${box_user_group}" "${box_dir}/bin/yq"
  chmod 0755 "${box_dir}/bin/yq"
}

# Check and update geoip and geosite
update_geox() {
  # su -c /data/adb/box/scripts/box.tool geox
  geodata_mode=$(busybox awk '!/^ *#/ && /geodata-mode:*./{print $2}' "${clash_config}")
  [ -z "${geodata_mode}" ] && geodata_mode=false
  case "${bin_name}" in
    clash)
      geoip_file="${box_dir}/clash/$(if [[ "${clash_option}" == "premium" || "${geodata_mode}" == "false" ]]; then echo "Country.mmdb"; else echo "GeoIP.dat"; fi)"
      geoip_url="https://github.com/$(if [[ "${clash_option}" == "premium" || "${geodata_mode}" == "false" ]]; then echo "MetaCubeX/meta-rules-dat/raw/release/country-lite.mmdb"; else echo "MetaCubeX/meta-rules-dat/raw/release/geoip-lite.dat"; fi)"
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
  if [ "${update_geo}" = "true" ] && { log Info "daily updates geox" && log Debug "Downloading ${geoip_url}"; } && update_file "${geoip_file}" "${geoip_url}" && { log Debug "Downloading ${geosite_url}" && update_file "${geosite_file}" "${geosite_url}"; }; then

    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.db.bak" -delete
    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.dat.bak" -delete
    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.mmdb.bak" -delete
    log Debug "Update geox $(date +%F %R)"
    return 0
  else
   return 1
  fi
}

# Check and update subscription
update_subs() {
  enhanced=false
  update_file_name="$(if [ "${bin_name}" = "clash" ]; then echo "${clash_config}"; else echo "${sing_config}"; fi)"
  if [ "${renew}" != "true" ]; then
    yq_command=$(command -v yq >/dev/null 2>&1; echo $?)
    # If yq native doesn't exist
    if [ "${yq_command}" -eq 1 ]; then
      if [ ! -e "${box_dir}/bin/yq" ]; then
        log Debug "yq file not found, start to download from github"
        update_yq
      fi
      yq_command=$(command -v "${box_dir}/bin/yq" >/dev/null 2>&1; echo $?)
    fi
    if [ "${yq_command}" -eq 0 ]; then
      if [ -f "${box_dir}/bin/yq" ]; then yq_cmd="${box_dir}/bin/yq"; else yq_cmd="yq"; fi
      enhanced=true
      update_file_name="${update_file_name}.subscription"
    else
      log Warning "yq not found, this will update main configuration $(if [ "${bin_name}" = "clash" ]; then echo "${clash_config}"; else echo "${sing_config}"; fi)"
    fi
  fi

  case "${bin_name}" in
    "clash")
      # subscription clash
      if [ -n "${subscription_url_clash}" ]; then
        if [ "${update_subscription}" = "true" ]; then
          log Info "daily updates subs"
          log Debug "Downloading ${update_file_name}"
          if update_file "${update_file_name}" "${subscription_url_clash}"; then
            log Info "${update_file_name} saved"
            # If there is a yq command, extract the proxy information from the yml and output it to the clash_provide_config file
            if [ "${enhanced}" = "true" ]; then
              if ${yq_cmd} '.proxies' "${update_file_name}" >/dev/null 2>&1; then
                "${yq_cmd}" '.proxies' "${update_file_name}" > "${clash_provide_config}"
                "${yq_cmd}" -i '{"proxies": .}' "${clash_provide_config}"

                if [ "${custom_rules_subs}" = "true" ]; then
                  if ${yq_cmd} '.rules' "${update_file_name}" >/dev/null 2>&1; then

                    "${yq_cmd}" '.rules' "${update_file_name}" > "${clash_provide_rules}"
                    "${yq_cmd}" -i '{"rules": .}' "${clash_provide_rules}"
                    "${yq_cmd}" -i 'del(.rules)' "${clash_config}"

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
          return 1
        fi
      else
        log Warning "${bin_name} subscription url is empty..."
        return 1
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

update_kernel() {
  # su -c /data/adb/box/scripts/box.tool upcore
  mkdir -p "${bin_dir}/backup"
  if [ -f "${bin_dir}/${bin_name}" ]; then
    cp "${bin_dir}/${bin_name}" "${bin_dir}/backup/${bin_name}.bak" >/dev/null 2>&1
  fi
  case $(uname -m) in
    "aarch64") arch="arm64"; platform="android" ;;
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
      # set download link and get the latest version
      latest_version=$(busybox wget --no-check-certificate -qO- "${api_url}" | grep "tag_name" | grep -o "v[0-9].*" | head -1 | cut -d'"' -f1)
      download_link="${url_down}/download/${latest_version}/sing-box-${latest_version#v}-${platform}-${arch}.tar.gz"
      log Debug "download ${download_link}"
      update_file "${box_dir}/${file_kernel}.tar.gz" "${download_link}" && extra_kernel
      ;;
    "clash")
      if [ "${clash_option}" = "meta" ]; then
        # set download link and get the latest version
        download_link="https://github.com/MetaCubeX/Clash.Meta/releases"
        if [ "$use_ghproxy" == true ]; then
          download_link="https://ghproxy.com/${download_link}"
        fi
        tag="Prerelease-Alpha"
        latest_version=$(busybox wget --no-check-certificate -qO- "${download_link}/expanded_assets/${tag}" | grep -oE "alpha-[0-9a-z]+" | head -1)
        # set the filename based on platform and architecture
        filename="clash.meta-${platform}-${arch}-${latest_version}"
        # download and update the file
        log Debug "download ${download_link}/download/${tag}/${filename}.gz"
        update_file "${box_dir}/${file_kernel}.gz" "${download_link}/download/${tag}/${filename}.gz" && extra_kernel
      # if meta flag is false, download clash premium/dev
      else
        # if dev flag is false, download latest premium version
        filename=$(busybox wget --no-check-certificate -qO- "https://github.com/Dreamacro/clash/releases/expanded_assets/premium" | grep -oE "clash-linux-${arch}-[0-9]+.[0-9]+.[0-9]+" | head -1)
        log Debug "download https://github.com/Dreamacro/clash/releases/download/premium/${filename}.gz"
        update_file "${box_dir}/${file_kernel}.gz" "https://github.com/Dreamacro/clash/releases/download/premium/${filename}.gz" && extra_kernel
      fi
      ;;
    "xray"|"v2fly")
      [ "${bin_name}" = "xray" ] && bin='Xray' || bin='v2ray'
      api_url="https://api.github.com/repos/$(if [ "${bin_name}" = "xray" ]; then echo "XTLS/Xray-core/releases"; else echo "v2fly/v2ray-core/releases"; fi)"
      # set download link and get the latest version
      latest_version=$(busybox wget --no-check-certificate -qO- ${api_url} | grep "tag_name" | grep -o "v[0-9.]*" | head -1)
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
      update_file "${box_dir}/${file_kernel}.zip" "${download_link}/download/${latest_version}/${download_file}" && extra_kernel
    ;;
    *)
      log Error "<${bin_name}> unknown binary."
      exit 1
      ;;
  esac
}

# Check and update kernel
extra_kernel() {
  case "${bin_name}" in
    "clash")
      gunzip_command="gunzip"
      if ! command -v gunzip >/dev/null 2>&1; then
        gunzip_command="busybox gunzip"
      fi

      mkdir -p "${bin_dir}/xclash"
      if ${gunzip_command} "${box_dir}/${file_kernel}.gz" >&2 && mv "${box_dir}/${file_kernel}" "${bin_dir}/xclash/${bin_name}_${clash_option}"; then
        ln -sf "${bin_dir}/xclash/${bin_name}_${clash_option}" "${bin_dir}/${bin_name}"

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

      if ${tar_command} -xf "${box_dir}/${file_kernel}.tar.gz" -C "${box_dir}/bin" >&2 &&
        mv "${box_dir}/bin/sing-box-${latest_version#v}-${platform}-${arch}/sing-box" "${bin_dir}/${bin_name}" &&
        rm -r "${box_dir}/bin/sing-box-${latest_version#v}-${platform}-${arch}"; then
        if [ -f "${box_pid}" ]; then
          restart_box
        else
          log Debug "${bin_name} does not need to be restarted."
        fi
      else
        log Error "Failed to extract ${box_dir}/${file_kernel}.tar.gz."
      fi
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
update_dashboard() {
  # su -c /data/adb/box/scripts/box.tool upyacd
  if [[ "${bin_name}" == @(clash|sing-box) ]]; then
    file_dashboard="${box_dir}/${bin_name}/dashboard.zip"
    url="https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip"
    if [ "$use_ghproxy" == true ]; then
      url="https://ghproxy.com/${url}"
    fi
    dir_name="Yacd-meta-gh-pages"
    log Debug "Download ${url}"
    if busybox wget --no-check-certificate "${url}" -O "${file_dashboard}" >&2; then
      if [ ! -d "${box_dir}/${bin_name}/dashboard" ]; then
        log Info "dashboard folder not exist, creating it"
        mkdir "${box_dir}/${bin_name}/dashboard"
      else
        rm -rf "${box_dir}/${bin_name}/dashboard/"*
      fi
      if command -v unzip >/dev/null 2>&1; then
        unzip_command="unzip"
      else
        unzip_command="busybox unzip"
      fi
      $unzip_command -o "${file_dashboard}" "${dir_name}/*" -d "${box_dir}/${bin_name}/dashboard" >&2
      mv -f "${box_dir}/${bin_name}/dashboard/$dir_name"/* "${box_dir}/${bin_name}/dashboard/"
      rm -f "${file_dashboard}"
      rm -rf "${box_dir}/${bin_name}/dashboard/${dir_name}"
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

# Function for detecting ports used by a process
port_detection() {
  sleep 1
  # Use 'command' function to check availability of 'ss'
  if command -v ss > /dev/null ; then
    # Use 'awk' with a regular expression to match the process ID
    ports=$(ss -antup | busybox awk -v PID="$(busybox pidof "${bin_name}")" '$7 ~ PID {print $5}' | busybox awk -F ':' '{print $2}' | sort -u) >/dev/null 2>&1
    # Make a note of the detected ports
    if busybox pidof "${bin_name}" >/dev/null 2>&1; then
      if [ -t 1 ]; then
        echo -n "${orange}${current_time} [Debug]: ${bin_name} port detected:${normal}"
      else
        echo -n "${current_time} [Debug]: ${bin_name} port detected:" | tee -a "${box_log}" >> /dev/null 2>&1
      fi
      # write ports
      while read -r port; do
        sleep 0.5
        [ -t 1 ] && (echo -n "${red}${port}|$normal") || (echo -n "${port}|" | tee -a "${box_log}" >> /dev/null 2>&1)
      done <<< "${ports}"
      # Add a newline to the output if running in terminal
      [ -t 1 ] && echo -e "\033[1;31m""\033[0m" || echo "" >> "${box_log}" 2>&1
    else
      return 1
    fi
  else
    log Debug "ss command not found, skipping port detection." >&2
    return 1
  fi
}

# Function to limit cgroup memory
cgroup_limit() {
  # Check if the cgroup memory limit has been set.
  if [ -z "${cgroup_memory_limit}" ]; then
    log Warning "cgroup_memory_limit is not set"
    return 1
  fi

  # Check if the cgroup memory path is set and exists.
  if [ -z "${cgroup_memory_path}" ]; then
    local cgroup_memory_path=$(mount | grep cgroup | busybox awk '/memory/{print $3}' | head -1)
    if [ -z "${cgroup_memory_path}" ]; then
      log Warning "cgroup_memory_path is not set and could not be found"
      return 1
    fi
  else
    log Warning "Leave the 'cgroup_memory_path' field empty to obtain the path."
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
  mkdir -p "${cgroup_memory_path}/${bin_name}"
  local PID=$(<"${box_pid}" 2>/dev/null)

  if [ ! -z "$PID" ]; then
    echo "$PID" > "${cgroup_memory_path}/${bin_name}/cgroup.procs" \
      && log Info "Moved process $PID to ${cgroup_memory_path}/${bin_name}/cgroup.procs"
    # Set memory limit for cgroups.
    echo "${cgroup_memory_limit}" > "${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes" \
      && log Info "Set memory limit to ${cgroup_memory_limit} for ${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes"
  else
    return 1
  fi
  return 0
}

# Check config
reload_config() {
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
    xray|v2fly)
      true
      ;;
    *)
      log Error "<${bin_name}> unknown binary."
      exit 1
      ;;
  esac
}

# reload bin
reload_bin() {
  # su -c /data/adb/box/scripts/box.tool rbin
  case "${bin_name}" in
    sing-box)
      if kill -SIGHUP "$(busybox pidof sing-box)" >/dev/null 2>&1; then
        log Debug "RESTART with -SIGHUP done"
        return 0
      else
        flag=true
        return 1
      fi
      ;;
    clash)
      ip_port=$(busybox awk '/external-controller:/ {print $2}' "${clash_config}") >/dev/null 2>&1
      secret=$(busybox awk '/secret:/ {print $2}' "${clash_config}") >/dev/null 2>&1
      if busybox wget --header="Authorization: Bearer ${secret}" --post-data "" -O /dev/null "http://${ip_port}/restart" >/dev/null 2>&1; then
        log Debug "RESTART with clash-meta API done"
        return 0
      else
        flag=true
        return 1
      fi
      ;;
    *)
      flag=true
      return 1
      ;;
  esac
}

case "$1" in
  upyq)
    update_yq
    ;;
  upyacd)
    if update_dashboard; then
      busybox pidof "${bin_name}" >/dev/null 2>&1 && open_yacd
    fi
    ;;
  upcore)
    update_kernel
    ;;
  cgroup)
    cgroup_limit
    ;;
  port)
    port_detection
    ;;
  rconf)
    reload_config
    ;;
  rbin)
    reload_bin
    ;;
  geox)
    if update_geox && ! reload_bin; then
      if [ -f "${box_pid}" ] && [ "${flag}" = "true" ]; then
        restart_box
      fi
    fi
    busybox pidof "${bin_name}" >/dev/null 2>&1 && open_yacd
    ;;
  subs)
    if update_subs && ! reload_bin; then
      if [ -f "${box_pid}" ] && [ "${flag}" = "true" ]; then
        restart_box 
      fi
    fi
    busybox pidof "${bin_name}" >/dev/null 2>&1 && open_yacd
    ;;
  geosub)
    update_geox
    update_subs
    if ! reload_bin; then
      if [ -f "${box_pid}" ] && [ "${bin_name}" != "clash" ] && [ "${flag}" = "true" ]; then
        restart_box
      fi
    fi
    ;;
  all)
    update_yq
    for bin_name in "${bin_list[@]}"; do
      update_kernel
      update_geox
      update_subs
      update_dashboard
    done
    ;;
  *)
    echo "${red}$0 $1 no found${normal}"
    echo "${yellow}usage${normal}: ${green}$0${normal} {${yellow}rconf|rbin|upyacd|upcore|upyq|cgroup|port|geox|subs|geosub|all${normal}}"
    ;;
esac
