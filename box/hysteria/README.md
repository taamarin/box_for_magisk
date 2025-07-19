---

## 🌐 Hysteria v2 Documentation

🔹 **Hysteria v2 (UDP-based VPN / Proxy Protocol)**  
📚 Full Client Config: [v2.hysteria.network/docs/advanced/Full-Client-Config](https://v2.hysteria.network/docs/advanced/Full-Client-Config/)

---

## ⚙️ Sample Hysteria2 Client Configuration

```yaml
server: your-server.com:443
auth: your-password-or-token
alpn:
  - h3
protocol: udp
obfs:
  type: salamander
  password: obfs-password
tls:
  sni: your-server.com
  insecure: true
bandwidth:
  up: 50 Mbps
  down: 100 Mbps
fastOpen: true
retry: 3