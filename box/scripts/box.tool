#!/system/bin/sh

scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
source /data/adb/box/settings.ini

user_agent="box_for_root"
# option to download Clash kernel clash-premium{false} or clash-meta{true}
meta="true"
# for clash-premium
dev=true
# option to download Singbox kernel beta or release
singbox_releases=false

# whether use ghproxy to accelerate github download
use_ghproxy=false

# Check internet connection with mlbox
check_connection_with_mlbox() {
  now=$(date +"%R")
  connect="\033[1;32mconnect\033[0m"
  failed="\033[1;33mfailed\033[0m"

  # Check DNS
  echo -n "\033[1;34m${now} [info]: dns=\033[0m"
  ntpip=$(${data_dir}/bin/mlbox -timeout=5 -dns="-qtype=A -domain=asia.pool.ntp.org" | grep -v 'timeout' | grep -E '[1-9][0-9]{0,2}(\.[0-9]{1,3}){3}' | head -n 1)
  if [ -z "${ntpip}" ]; then
    echo "$failed"
  else
    echo "$connect"

    # Check HTTP
    echo -n "\033[1;34m${now} [info]: http=\033[0m"
    httpIP=$(busybox wget -qO- "http://182.254.116.116/d?dn=reddit.com&clientip=1" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | cut -d "|" -f 2)
    if [ -z "${httpIP}" ]; then
      echo "$failed"
    else
      echo "$connect"

      # Check HTTPS
      echo -n "\033[1;34m${now} [info]: https=\033[0m"
      httpsResp=$(${data_dir}/bin/mlbox -timeout=5 -http="https://api.infoip.io" 2>&1 | grep -Ev 'timeout|httpGetResponse' | grep -E '[1-9][0-9]{0,2}(\.[0-9]{1,3}){3}')
      if [ -z "${httpsResp}" ]; then
        echo "$failed"
      else
        echo "$connect"

        # Check UDP
        echo -n "\033[1;34m${now} [info]: udp=\033[0m"
        currentTime=$(${data_dir}/bin/mlbox -timeout=7 -ntp="${ntpip}" | grep -v 'timeout')
        if echo "${currentTime}" | grep -qi 'LI:'; then
          echo "$connect"
        else
          echo "$failed"
        fi
      fi
    fi
  fi
}

# Check if a binary is running by checking the pid file
probe_bin_alive() {
  if [ ! -f "${pid_file}" ]; then
    return 1 # pid file not found, binary is not alive
  fi
  sleep 0.5
  if ! busybox pidof "${bin_name}" >/dev/null; then
    return 1 # binary is not alive
  fi
  return 0 # binary is alive
}

# Restart the binary, after stopping and running again
restart_box() {
  ${scripts_dir}/box.service restart
  sleep 0.5
  if probe_bin_alive ; then
    # ${scripts_dir}/box.iptables renew
    log debug "$(date) ${bin_name} restarted successfully."
  else
    log error "Failed to restart ${bin_name}."
    ${scripts_dir}/box.iptables disable >/dev/null 2>&1
  fi
}

# Set DNS manually, change net.ipv4.ip_forward and net.ipv6.conf.all.forwarding to 1
keep_dns() {
  local_dns1=$(getprop net.dns1)
  local_dns2=$(getprop net.dns2)
  if [ "${local_dns1}" != "${static_dns1}" ] || [ "${local_dns2}" != "${static_dns2}" ]; then
    setprop net.dns1 "${static_dns1}"
    setprop net.dns2 "${static_dns2}"
  fi
  if [ "$(sysctl net.ipv4.ip_forward)" != "1" ]; then
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
  fi
  if [ "$(sysctl net.ipv6.conf.all.forwarding)" != "1" ]; then
    sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null
  fi
  unset local_dns1
  unset local_dns2
}

# Updating files from URLs
update_file() {
  file="$1"
  update_url="$2"
  file_bak="${file}.bak"
  if [ -f "${file}" ]; then
    mv "${file}" "${file_bak}" || return 1
  fi
  # Enable ghproxy to accelerate download
  if [[ "$use_ghproxy" == false ]] && ([[ "$update_url" == "https://github.com/"* ]] || [[ "$update_url" == "https://raw.githubusercontent.com/"* ]] || [[ "$update_url" == "https://gist.github.com/"* ]] || [[ "$update_url" == "https://gist.githubusercontent.com/"* ]]); then
    echo "- It seems that you are downloading from GitHub."
    echo "- Do you want to use the GitHub proxy service to download?"
    echo "- [ Vol UP: Yes ]"
    echo "- [ Vol DOWN: No ]"
    while true; do
      getevent -lc 1 2>&1 | grep -q KEY_VOLUMEUP && {
        use_ghproxy=true
        break
      }
      getevent -lc 1 2>&1 | grep -q KEY_VOLUMEDOWN && break
    done
  fi
  if [[ "$use_ghproxy" == true ]]; then
    update_url="https://ghproxy.com/${update_url}"
  fi
  request="busybox wget"
  request+=" --no-check-certificate"
  request+=" --user-agent ${user_agent}"
  request+=" -O ${file}"
  request+=" ${update_url}"
  echo ${request}
  ${request} >&2 || {
    if [ -f "${file_bak}" ]; then
      mv "${file_bak}" "${file}" || true
    fi
    return 1
  }
  return 0
}

# Check and update geoip and geosite
update_subgeo() {
  log info "daily updates"
  geodata_mode=$(awk '/geodata-mode:*./{print $2}' "${clash_config}")
  case "${bin_name}" in
    clash)
      geoip_file="${data_dir}/clash/$(if [ "${geodata_mode}" = "false" ]; then echo "Country.mmdb"; else echo "GeoIP.dat"; fi)"
      geoip_url="https://github.com/$(if [ "${geodata_mode}" = "false" ]; then echo "MetaCubeX/meta-rules-dat/raw/release/country.mmdb"; else echo "MetaCubeX/meta-rules-dat/raw/release/geoip.dat"; fi)"
      geosite_file="${data_dir}/clash/GeoSite.dat"
      geosite_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.dat"
      ;;
    sing-box)
      geoip_file="${data_dir}/sing-box/geoip.db"
      geoip_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip.db"
      geosite_file="${data_dir}/sing-box/geosite.db"
      geosite_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.db"
      ;;
    *)
      geoip_file="${data_dir}/${bin_name}/geoip.dat"
      geoip_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip.dat"
      geosite_file="${data_dir}/${bin_name}/geosite.dat"
      geosite_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.dat"
      ;;
  esac
  if [ "${auto_update_geox}" = "true" ] && log debug "Downloading ${geoip_url}" && update_file "${geoip_file}" "${geoip_url}" && log debug "Downloading ${geosite_url}" && update_file "${geosite_file}" "${geosite_url}"; then
    log debug "Update geo $(date +"%F %R")"
    flag=false
  fi
  enhanced=false
  update_file_name="${clash_config}"
  yq_command="$(command -v yq >/dev/null 2>&1 ; echo $?)"
  wc_command="$(command -v wc >/dev/null 2>&1 ; echo $?)"
  if [ $yq_command -eq 0 ] && [ $wc_command -eq 0 ]; then
    enhanced=true
    update_file_name="${update_file_name}.subscription"
  fi
  if [ "${bin_name}" = "clash" ] && [ "${auto_update_subscription}" = "true" ] && update_file "${update_file_name}" "${subscription_url}"; then
    log debug "Downloading ${clash_config}"
    # If there is a yq command, extract the proxies information from yml and output it to the clash_domestic_config file
    if [ "${enhanced}" = "true" ]; then
      if [ $(cat ${update_file_name} | yq '.proxies' | wc -l) -gt 1 ];then
        yq '.proxies' ${update_file_name} > ${clash_domestic_config}
        yq -i '{"proxies": .}' ${clash_domestic_config}
        log info "subscription success"
        if [ -f "${update_file_name}.bak" ]; then
          rm ${update_file_name}.bak
        fi
        flag=true
      else
        log error "subscription failed"
      fi
    else
      flag=true
    fi
  fi
  if [ -f "${pid_file}" ] && [ "${flag}" = "true" ]; then
    restart_box
  fi
}

# Function for detecting ports used by a process
port_detection() {
  # Use 'command' function to check availability of 'ss'
  if command -v ss > /dev/null ; then
    # Use 'awk' with a regular expression to match the process ID
    ports=$(ss -antup | busybox awk -v pid="$(busybox pidof "${bin_name}")" '$7 ~ pid {print $5}' | busybox awk -F ':' '{print $2}' | sort -u)
  else
    # Note the warning message if 'ss' is not available
    log debug "ss command not found, skipping port detection." >&2
    return
  fi

  # Make a note of the detected ports
  now=$(date +"%R")
  if [ -t 1 ]; then
    echo -n "\033[1;33m${now} [debug]: ${bin_name} port detected: \033[0m"
  else
    echo -n "${now} [debug]: ${bin_name} port detected: " | tee -a "${logs_file}" >> /dev/null 2>&1
  fi

  while read -r port; do
    sleep 0.5
    if [ -t 1 ]; then
      echo -n "\033[1;33m${port} \033[0m"
    else
      echo -n "${port} " | tee -a "${logs_file}" >> /dev/null 2>&1
    fi
  done <<< "${ports}"

  # Add a newline to the output if running in terminal
  if [ -t 1 ]; then
    echo -e "\033[1;31m""\033[0m"
  else
    echo "" >> "${logs_file}" 2>&1
  fi
}

update_kernel() {
  # su -c /data/adb/box/scripts/box.tool upcore
  case $(uname -m) in
    "aarch64") arch="arm64"; platform="android" ;;
    "armv7l"|"armv8l") arch="armv7"; platform="linux" ;;
    "i686") arch="386"; platform="linux" ;;
    "x86_64") arch="amd64"; platform="linux" ;;
    *) log warn "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
# Do anything else below
  file_kernel="${bin_name}-${arch}"
  case "${bin_name}" in
    sing-box)
      url_down="https://github.com/SagerNet/sing-box/releases"
      if [ "${singbox_releases}" = "false" ]; then
        sing_box_version_temp=$(busybox wget --no-check-certificate -qO- "${url_down}" | grep -oE '/tag/v[0-9]+\.[0-9]+-[a-z0-9]+' | head -1 | busybox awk -F'/' '{print $3}')
      else
        sing_box_version_temp=$(busybox wget --no-check-certificate -qO- "${url_down}" | grep -oE '/tag/v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | busybox awk -F'/' '{print $3}')
      fi
      sing_box_version=${sing_box_version_temp#v}
      download_link="${url_down}/download/${sing_box_version_temp}/sing-box-${sing_box_version}-${platform}-${arch}.tar.gz"
      log debug "download ${download_link}"
      update_file "${data_dir}/${file_kernel}.tar.gz" "${download_link}"
      ;;
    clash)
      if [ "${meta}" = "true" ]; then
        # set download link and get the latest version
        download_link="https://github.com/MetaCubeX/Clash.Meta/releases"
        # tag=$(busybox wget --no-check-certificate -qO- ${download_link} | grep -oE 'tag\/([^"]+)' | cut -d '/' -f 2 | head -1)
        tag="Prerelease-Alpha"
        latest_version=$(busybox wget --no-check-certificate -qO- "${download_link}/expanded_assets/${tag}" | grep -oE "alpha-[0-9a-z]+" | head -1)
        # set the filename based on platform and architecture
        filename="clash.meta-${platform}-${arch}-${latest_version}"
        # download and update the file
        log debug "download ${download_link}/download/${tag}/${filename}.gz"
        update_file "${data_dir}/${file_kernel}.gz" "${download_link}/download/${tag}/${filename}.gz"
      # if meta flag is false, download clash premium/dev
      else
        # if dev flag is true, download latest dev version
        if [ "${dev}" != "false" ]; then
          log debug "download https://release.dreamacro.workers.dev/latest/clash-linux-${arch}-latest.gz"
          update_file "${data_dir}/${file_kernel}.gz" "https://release.dreamacro.workers.dev/latest/clash-linux-${arch}-latest.gz"
        else
        # if dev flag is false, download latest premium version
          filename=$(busybox wget --no-check-certificate -qO- "https://github.com/Dreamacro/clash/releases/expanded_assets/premium" | grep -oE "clash-linux-${arch}-[0-9]+.[0-9]+.[0-9]+" | head -1)
          log debug "download https://github.com/Dreamacro/clash/releases/download/premium/${filename}.gz"
          update_file "${data_dir}/${file_kernel}.gz" "https://github.com/Dreamacro/clash/releases/download/premium/${filename}.gz"
        fi
      fi
      ;;
    xray|v2fly)
      [ "${bin_name}" = "xray" ] && bin='Xray' || bin='v2ray'
      api_url="https://api.github.com/repos/$(if [ "${bin_name}" = "xray" ]; then echo "XTLS/Xray-core/releases"; else echo "v2fly/v2ray-core/releases"; fi)"
      # set download link and get the latest version
      latest_version=$(busybox wget --no-check-certificate -qO- ${api_url} | grep "tag_name" | grep -o "v[0-9.]*" | head -1)
      case $(uname -m) in
        "i386") download_file="$bin-linux-32.zip" ;;
        "x86_64") download_file="$bin-linux-64.zip" ;;
        "armv7l"|"armv8l") download_file="$bin-linux-arm32-v7a.zip" ;;
        "aarch64") download_file="$bin-android-arm64-v8a.zip" ;;
        *) log error "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
      esac
      # Do anything else below
      download_link="https://github.com/$(if [ "${bin_name}" = "xray" ]; then echo "XTLS/Xray-core/releases"; else echo "v2fly/v2ray-core/releases"; fi)"
      log debug "Downloading ${download_link}/download/${latest_version}/${download_file}"
      update_file "${data_dir}/${file_kernel}.zip" "${download_link}/download/${latest_version}/${download_file}"
    ;;
    *)
      log error "kernel error."
      exit 1
      ;;
  esac

  case "${bin_name}" in
    clash)
      gunzip_command="$(command -v gunzip >/dev/null 2>&1 ; echo $?)"
      if [ $gunzip_command -eq 0 ]; then
        gunzip_command="gunzip"
      else
        gunzip_command="busybox gunzip"
      fi
      if ${gunzip_command} "${data_dir}/${file_kernel}.gz" >&2 &&
        mv "${data_dir}/${file_kernel}" "${bin_kernel}/${bin_name}"; then
        if [ -f "${pid_file}" ]; then
          restart_box
        else
          log debug "${bin_name} does not need to be restarted."
        fi
      else
        log error "Failed to extract or move the kernel."
      fi
    ;;
    sing-box)
      tar_command="$(command -v tar >/dev/null 2>&1 ; echo $?)"
      if [ $tar_command -eq 0 ]; then
        tar_command="tar"
      else
        tar_command="busybox tar"
      fi
      if ${tar_command} -xf "${data_dir}/${file_kernel}.tar.gz" -C "${data_dir}/bin" >&2 &&
        mv "${data_dir}/bin/sing-box-${sing_box_version}-${platform}-${arch}/sing-box" "${bin_kernel}/${bin_name}" &&
        rm -r "${data_dir}/bin/sing-box-${sing_box_version}-${platform}-${arch}"; then
        if [ -f "${pid_file}" ]; then
          restart_box
        else
          log debug "${bin_name} does not need to be restarted."
        fi
      else
        log warn "Failed to extract ${data_dir}/${file_kernel}.tar.gz."
        flag="false"
      fi
    ;;
    v2fly|xray)
      [ "${bin_name}" = "xray" ] && bin='xray' || bin='v2ray'
      unzip_command="$(command -v unzip >/dev/null 2>&1 ; echo $?)"
      if [ $unzip_command -eq 0 ]; then
        unzip_command="unzip"
      else
        unzip_command="busybox unzip"
      fi

      if ${unzip_command} -o "${data_dir}/${file_kernel}.zip" "${bin}" -d "${bin_kernel}" >&2; then
        if mv "${bin_kernel}/${bin}" "${bin_kernel}/${bin_name}"; then
          if [ -f "${pid_file}" ]; then
            restart_box
          else
            log debug "${bin_name} does not need to be restarted."
          fi
        else
          log error "Failed to move the kernel."
        fi
      else
        log warn "Failed to extract ${data_dir}/${file_kernel}.zip."
      fi
      ;;
    *)
      log error "kernel error."
      exit 1
    ;;
  esac

  find "${data_dir}" -type f -name "${file_kernel}.*" -delete
  chown ${box_user_group} ${bin_path}
  chmod 6755 ${bin_path}
}

# Function to limit cgroup memory
cgroup_limit() {
  # Check if the cgroup memory limit has been set.
  if [ -z "${cgroup_memory_limit}" ]; then
    log warn "cgroup_memory_limit is not set"
    return 1
  fi
  
  # Check if the cgroup memory path is set and exists.
  if [ -z "${cgroup_memory_path}" ]; then
    local cgroup_memory_path=$(mount | grep cgroup | busybox awk '/memory/{print $3}' | head -1)
    
    if [ -z "${cgroup_memory_path}" ]; then
      log warn "cgroup_memory_path is not set and could not be found"
      return 1
    fi
  elif [ ! -d "${cgroup_memory_path}" ]; then
    log warn "${cgroup_memory_path} does not exist"
    return 1
  fi
  
  # Check if pid_file is set and exists.
  if [ -z "${pid_file}" ]; then
    log warn "pid_file is not set"
    return 1
  elif [ ! -f "${pid_file}" ]; then
    log warn "${pid_file} does not exist"
    return 1
  fi
  
  # Create cgroup directory and move process to cgroup.
  local bin_name=${bin_name}
  # local bin_name=$(basename "$0")
  mkdir -p "${cgroup_memory_path}/${bin_name}"
  local pid=$(cat "${pid_file}")
  
  echo "${pid}" > "${cgroup_memory_path}/${bin_name}/cgroup.procs" \
    && log info "Moved process ${pid} to ${cgroup_memory_path}/${bin_name}/cgroup.procs"
  
  # Set memory limit for cgroups.
  echo "${cgroup_memory_limit}" > "${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes" \
    && log info "Set memory limit to ${cgroup_memory_limit} for ${cgroup_memory_path}/${bin_name}/memory.limit_in_bytes"
  
  return 0
}

update_dashboard() {
  if [ "${bin_name}" = "sing-box" ] || [ "${bin_name}" = "clash" ]; then
    file_dashboard="${data_dir}/${bin_name}/dashboard.zip"
    rm -rf "${data_dir}/${bin_name}/dashboard"
    if [ ! -d "${data_dir}/${bin_name}/dashboard" ]; then
      log info "dashboard folder not exist, creating it"
      mkdir "${data_dir}/${bin_name}/dashboard"
    fi
    url="https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip"
    dir_name="Yacd-meta-gh-pages"
    busybox wget --no-check-certificate "${url}" -O "${file_dashboard}" >&2 || { log error "Failed to download $url"; exit 1; }
    unzip_command="$(command -v unzip >/dev/null 2>&1 ; echo $?)"
    if [ $unzip_command -eq 0 ]; then
      unzip_command="unzip"
    else
      unzip_command="busybox unzip"
    fi
    ${unzip_command} -o "${file_dashboard}" "${dir_name}/*" -d "${data_dir}/${bin_name}/dashboard" >&2
    mv -f "${data_dir}/${bin_name}/dashboard/$dir_name"/* "${data_dir}/${bin_name}/dashboard"
    rm -f "${file_dashboard}"
    rm -r "${data_dir}/${bin_name}/dashboard/${dir_name}"
  else
    log debug "${bin_name} does not support dashboards"
  fi
}

reload() {
  case "${bin_name}" in
    sing-box)
      if ${bin_path} check -D "${data_dir}/${bin_name}" --config-directory "${data_dir}/sing-box" > "${run_path}/${bin_name}-report.log" 2>&1; then
        log info "config.json passed"
      else
        log error "config.json check failed"
        cat "${run_path}/${bin_name}-report.log" >&2
        exit 1
      fi
      ;;
    clash)
      if ${bin_path} -t -d "${data_dir}/clash" -f "${clash_config}" > "${run_path}/${bin_name}-report.log" 2>&1; then
        log info "config.yaml passed"
        log info "Open yacd-meta/configs and click 'Reload Configs'"
      else
        log error "config.yaml check failed"
        cat "${run_path}/${bin_name}-report.log" >&2
        exit 1
      fi
      ;;
    *)
      log error "Unknown binary: ${bin_name}"
      exit 1
      ;;
  esac
}

case "$1" in
  testing)
    check_connection_with_mlbox
    ;;
  keepdns)
    keep_dns
    ;;
  upyacd)
    update_dashboard
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
  reload)  
    reload
    ;;
  subgeo)
    update_subgeo
    find "${data_dir}/${bin_name}" -type f -name "*.db.bak" -delete
    find "${data_dir}/${bin_name}" -type f -name "*.dat.bak" -delete
    ;;
  all)  
    for list in "${bin_list[@]}" ; do
      bin_name="${list}"
      update_kernel
      update_subgeo
      update_dashboard
    done
    ;;
  *)
    echo "$0: usage: $0 {reload|testing|keepdns|connect|upyacd|upcore|cgroup|port|subgeo|all}"
    exit 1
    ;;
esac
