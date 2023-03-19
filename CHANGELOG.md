#### ⟳ Changelog v0.5
+ fix log
+ improve cgroup 
    + cgroups are automatically disabled if the phone's kernel doesn't support it
+ added arm8l arch support for kernel updates
+ improve bfm scripts
    + will take the value of the `clash tun_device: utun`, `sing-box tun_device: tun0`, `clash_fake_ip_range: 198.18.0.1/16`, `clash_enhanced_mode: fake-ip`, `clash_dns_port: 1053`, `external-ui: ./dashboard/dist`, `tproxy-port: $tproxy_port` and `redir-port: $redir_port` variable, as default if not confirmed in the YAML / JSON config

[README](https://github.com/taamarin/box_for_magisk/blob/master/README.md)