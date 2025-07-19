## ✴️ Xray (XTLS) Documentation

🔹 **Xray Core (XTLS, Reality, and enhancements)**  
📚 Official Docs: [xtls.github.io](https://xtls.github.io/)   

## ⚙️ Sample Xray Configuration (VLESS + XTLS / Reality)

```json
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "your-server.com",
            "port": 443,
            "users": [
              {
                "id": "abcdefgh-1234-5678-90ab-cdef12345678",
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "serverName": "target-sni.com",
          "publicKey": "Base64ServerPubKeyHere",
          "shortId": "0123456789abcdef",
          "fingerprint": "chrome"
        }
      }
    }
  ]
}