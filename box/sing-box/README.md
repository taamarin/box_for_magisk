## 🧱 Sing-box Documentation

🔹 **Sing-box (Universal Proxy Core by SagerNet)**  
📚 Official Docs: [sing-box.sagernet.org/configuration](http://sing-box.sagernet.org/configuration)   

## ⚙️ Sample Sing-box Configuration (VMess over WS + TLS)

```json
{
  "log": {
    "level": "info"
  },
  "inbounds": [
    {
      "type": "mixed",
      "listen": "::",
      "listen_port": 7890
    }
  ],
  "outbounds": [
    {
      "type": "vmess",
      "tag": "vmess-ws",
      "server": "example.com",
      "server_port": 443,
      "uuid": "abcdefgh-1234-5678-90ab-cdef12345678",
      "security": "auto",
      "transport": {
        "type": "ws",
        "path": "/websocket",
        "headers": {
          "Host": "example.com"
        }
      },
      "tls": {
        "enabled": true,
        "server_name": "example.com",
        "insecure": true
      }
    }
  ]
}