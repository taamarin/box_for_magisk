#### Changelog vv1.9.1 - 02-08-25
- — fix(iptables): switch to --set-xmark and reorder TProxy skip

#### Changelog v1.9.0 - 2025-07-19

### 🚀 Features
- feat: Add `sbfr` shortcut for direct execution [`361e421`]
- feat: Improve download handling with `curl` fallback to `wget` [`7caf827`]
- feat: Enhance TUN device handling [`8b000cd`]
- feat: Extend routing/NAT rules for TUN device [`c80f57a`]
- feat: Add local IP & DNS info in `box.services` status output [`13e773c`]

### 🛠 Fixes
- fix(box): use busybox paste for better compatibility on older Android [`0a59c04`]
- fix: Remove `0:`, `10:`, and `:999` prefixes from package list in Clash(TUN) config [`97e2db3`]
- fix: Sanitize package list before inserting into config [`42b355f`]
- fix: Duplicate DNS address output on some devices [`b4a2c00`]
- fix: Force redir-host mode when fake-ip is used with GID/packages/AP ignore list [`1619f19`]
- fix: Condition for fake-ip range in `box.iptables` with enhanced-mode [`982a1aa`]

### 🧼 Refactors
- refactor: Simplify sing-box (1.12+) config, remove legacy rules and sniff options [`3b6fe42`]
- refactor(cgroup): Update memcg/cpuset/blkio logic and settings [`a8ee249`]
- refactor: Improve readability/structure in `box.iptables` [`1672bb7`]
- refactor: Android version check via major version parsing [`c9c4be5`]
- refactor(cron): Improve `crond` handling and cleanup [`b43b059`]

### ⚙️ Changes
- chore: Updated `find_packages_uid()` to support `user:package` format [`2dcc4ca`]
- chore(hysteria): Validate `network_mode` and update config [`cac3186`]
- chore: Filter out local DNS (IPv4 only) and convert local IP to array [`02f1be3`]

### 🧰 Maintenance
- chore: Update `upload-artifact` GitHub Action from v3 to v4 [`80c5d73`]
- docs: Update README [`16f2455`, `128006d`]

### 🧹 Miscellaneous
- chore: Minor cleanup and misc changes [`9fbaa99`]

<!-- Commit References -->
[`361e421`]: https://github.com/taamarin/box_for_magisk/commit/361e421
[`7caf827`]: https://github.com/taamarin/box_for_magisk/commit/7caf827
[`8b000cd`]: https://github.com/taamarin/box_for_magisk/commit/8b000cd
[`c80f57a`]: https://github.com/taamarin/box_for_magisk/commit/c80f57a
[`13e773c`]: https://github.com/taamarin/box_for_magisk/commit/13e773c
[`0a59c04`]: https://github.com/taamarin/box_for_magisk/commit/0a59c04
[`97e2db3`]: https://github.com/taamarin/box_for_magisk/commit/97e2db3
[`42b355f`]: https://github.com/taamarin/box_for_magisk/commit/42b355f
[`b4a2c00`]: https://github.com/taamarin/box_for_magisk/commit/b4a2c00
[`1619f19`]: https://github.com/taamarin/box_for_magisk/commit/1619f19
[`982a1aa`]: https://github.com/taamarin/box_for_magisk/commit/982a1aa
[`3b6fe42`]: https://github.com/taamarin/box_for_magisk/commit/3b6fe42
[`a8ee249`]: https://github.com/taamarin/box_for_magisk/commit/a8ee249
[`1672bb7`]: https://github.com/taamarin/box_for_magisk/commit/1672bb7
[`c9c4be5`]: https://github.com/taamarin/box_for_magisk/commit/c9c4be5
[`b43b059`]: https://github.com/taamarin/box_for_magisk/commit/b43b059
[`2dcc4ca`]: https://github.com/taamarin/box_for_magisk/commit/2dcc4ca
[`cac3186`]: https://github.com/taamarin/box_for_magisk/commit/cac3186
[`02f1be3`]: https://github.com/taamarin/box_for_magisk/commit/02f1be3
[`80c5d73`]: https://github.com/taamarin/box_for_magisk/commit/80c5d73
[`16f2455`]: https://github.com/taamarin/box_for_magisk/commit/16f2455
[`128006d`]: https://github.com/taamarin/box_for_magisk/commit/128006d
[`9fbaa99`]: https://github.com/taamarin/box_for_magisk/commit/9fbaa99