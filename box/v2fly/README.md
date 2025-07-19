## ⚡ V2Ray / v2fly Documentation

🔹 **V2Ray / v2fly**  
📚 Official Docs: [v2fly.org/en_US](https://www.v2fly.org/en_US/)  

## ⚙️ Sample V2Ray Configuration (VMess over WS + TLS)

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "example.com",
            "port": 443,
            "users": [
              {
                "id": "abcdefgh-1234-5678-90ab-cdef12345678",
                "alterId": 0,
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "serverName": "example.com",
          "allowInsecure": true
        },
        "wsSettings": {
          "path": "/websocket",
          "headers": {
            "Host": "example.com"
          }
        }
      }
    }
  ]
}