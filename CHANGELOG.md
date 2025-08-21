#### Changelog v1.10.0 - 21-08-25
### ✨ Features
- **Network Control**
  - Introduced **network-based service control** with Wi-Fi/SSID options.
- **Clash**
  - Added support for **multiple subscription URLs and configs**.
- **Subscriptions**
  - Added **sing-box subscription support**.
- **Installer & Updater**
  - Improved install & update flow:
    - Added **progress bars** and **ghfast prompt**.
    - Enhanced logging polish.
- **Service**
  - Improved config file handling (**Sync BFR Manager**).
- **Logging & CLI**
  - Added help menus, enhanced update/reload routines.

### 🛠 Fixes
- **Network Switch**
  - Improved Wi-Fi SSID list handling.
- **Subscription**
  - `box.service` now auto-restarts when subscription updates with `renew=true`.
  - Fixed creation of `clash_provide_config` and subscription settings update.
- **Clash / Connectivity**
  - Reverted socket MARK rules in `box.iptables` to restore UDP connectivity ([#195](https://github.com/taamarin/box_for_magisk/issues/195)).
- **Service**
  - Added unified config error handler to update module status correctly.
- **General**
  - Improved logging, startup handling, and binary checks.

### 🔧 Improvements & Refactors
- **Customize**
  - Refactored binary update flow and mirror selection.
- **Service**
  - Refined log cleanup rules.
- **Scripts**
  - Added `settings.ini` validation to all entry scripts.
  - Unified output suppression format to `>/dev/null 2>&1`.

### 🧹 Chore
- Removed legacy `tun_forward_ip_rules` support.