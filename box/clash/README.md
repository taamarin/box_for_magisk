# 📄 Example Configuration & Documentation

A quick reference guide for setting up **Clash Premium** or **Mihomo (Clash Meta)** configurations properly.    

## 📘 Official Documentation  

🔹 **Mihomo (Clash)**  
📚 [wiki.metacubex.one](https://wiki.metacubex.one/)    

## 🧪 Sample Configuration (YAML)

```yaml
mixed-port: 7890
allow-lan: true
mode: rule
log-level: info

proxies:
  - name: "Example Proxy"
    type: vmess
    server: server.example.com
    port: 443
    uuid: abcdefgh-1234-5678-90ab-cdef12345678
    alterId: 0
    cipher: auto
    tls: true

proxy-groups:
  - name: "PROXY"
    type: select
    proxies:
      - "Example Proxy"
      - DIRECT

rules:
  - DOMAIN-SUFFIX,example.com,PROXY
  - MATCH,DIRECT