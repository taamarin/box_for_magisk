# 📦 Box for Magisk / KernelSU

## ⚠️ Peringatan

Proyek ini tidak bertanggung jawab atas kerusakan perangkat, kartu SD, maupun SoC.

**Pastikan file konfigurasi tidak menyebabkan loop lalu lintas, karena hal ini dapat membuat ponsel terus-menerus melakukan restart.**

Jika Anda benar-benar tidak tahu cara mengonfigurasi modul ini, Anda mungkin memerlukan aplikasi seperti **ClashForAndroid, ClashMetaForAndroid, v2rayNG, Surfboard, SagerNet, AnXray, NekoBox, SFA**, dll.

## 📦 Instalasi
• Unduh paket ZIP modul dari [Releases](https://github.com/taamarin/box_for_magisk/releases), lalu instal melalui `Magisk/APatch/KernelSU`. Saat instalasi, Anda akan ditanya apakah ingin mengunduh paket lengkap. Anda dapat mengunduh semuanya sekaligus atau mengunduh file secara terpisah nanti. Setelah instalasi, mulai ulang perangkat.  
• Modul ini mendukung pembaruan langsung melalui `Magisk/APatch/KernelSU Manager`, dan pembaruan akan berlaku tanpa perlu memulai ulang perangkat.  

### Pembaruan Kernel
Modul ini mencakup kernel berikut:  
• [clash](https://github.com/Dreamacro/clash) (repositori telah dihapus)   
• [clash.meta](https://github.com/MetaCubeX/mihomo)   
• [sing-box](https://github.com/SagerNet/sing-box)  
• [v2ray-core](https://github.com/v2fly/v2ray-core)  
• [Xray-core](https://github.com/XTLS/Xray-core)  
• [hysteria](https://v2.hysteria.network/)  

Nama core yang digunakan ditentukan oleh `${bin_name}`, yang dapat diatur ke `clash`, `xray`, `v2ray`, `sing-box`, atau `hysteria`.  
Setiap core dijalankan dari direktori `/data/adb/box/bin/${bin_name}`. Nama core ditentukan oleh nilai `bin_name` dalam file `/data/adb/box/settings.ini`.  

Pastikan Anda terhubung ke internet dan jalankan perintah berikut untuk memperbarui file kernel:  
```shell
# perbarui kernel yang dipilih, sesuai dengan `bin_name`
su -c /data/adb/box/scripts/box.tool upkernel
```

Jika Anda memilih `clash` atau `sing-box`, Anda mungkin juga perlu menjalankan perintah berikut untuk memasang panel kontrol (dashboard):  
```shell
# Perbarui panel admin clash/sing-box
su -c /data/adb/box/scripts/box.tool upxui
```

Sebagai alternatif, Anda dapat memperbarui semuanya sekaligus, meskipun cara ini mungkin menggunakan ruang penyimpanan lebih banyak dari yang diperlukan:  
```shell
# Perbarui semua file (termasuk berbagai jenis kernel dan GeoX)
su -c /data/adb/box/scripts/box.tool all
```

## ⚙️ Konfigurasi
**Layanan inti modul ini secara kolektif disebut BFR.**  
• Anda dapat memulai atau menghentikan layanan BFR secara langsung dengan mengaktifkan atau menonaktifkan modul melalui aplikasi Magisk/KernelSU Manager, tanpa perlu memulai ulang perangkat. Layanan mungkin memerlukan beberapa detik untuk dimulai, sedangkan penghentian berlaku seketika.

### Konfigurasi core
• Untuk informasi tentang pemilihan core melalui `bin_name`, lihat bagian **Pembaruan Kernel**.   
• Sesuaikan setiap file konfigurasi core sesuai kebutuhan. Skrip akan memeriksa validitas konfigurasi, dan hasilnya disimpan di `/data/adb/box/run/runs.log`.   
• **Tips:** `clash` dan `sing-box` menyertakan skrip untuk proxy transparan. Untuk konfigurasi lebih lanjut, lihat dokumentasi resmi: [Clash](https://github.com/Dreamacro/clash/wiki/configuration) (branch master telah dihapus) dan [sing-box](https://sing-box.sagernet.org/configuration/outbound/).  

### Memfilter aplikasi (daftar blokir/daftar izin)
• Secara default, BFR mem-proxy lalu lintas dari semua aplikasi milik semua pengguna Android.   
• Pengaturan filter aplikasi terdapat di `/data/adb/box/package.list.cfg`. Gunakan `mode:blacklist` (default) untuk mem-proxy semua aplikasi kecuali yang tercantum, atau `mode:whitelist` untuk hanya mem-proxy aplikasi yang tercantum. Tambahkan satu nama paket Android per baris; ID pengguna dapat ditambahkan sebagai awalan, misalnya `0:com.example.app`.   
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**  
• Jika hanya ingin **mem-proxy aplikasi tertentu**, gunakan `mode:whitelist`, lalu tambahkan aplikasi yang ingin di-proxy, misalnya:   
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**    
> ⚠️ Jika menggunakan Clash, daftar blokir dan daftar izin tidak berlaku dalam mode fake-IP.

### Proxy Transparan untuk Proses Tertentu
• Secara default, BFR mem-proxy lalu lintas dari semua proses secara transparan.   
• Filter proses menggunakan GID numerik di `/data/adb/box/gid.list.cfg`. Nilai `mode` di `package.list.cfg` juga menentukan apakah GID yang tercantum dikecualikan atau disertakan. Iptables Android tidak mencocokkan proses berdasarkan PID.

### Mengubah mode jaringan
• Secara default, BFR menggunakan TPROXY untuk mem-proxy lalu lintas TCP dan UDP secara transparan. Jika perangkat tidak mendukung TPROXY, buka `/data/adb/box/settings.ini` dan ubah `network_mode` menjadi `redirect`, yang hanya mem-proxy TCP.   
• `redirect`: TCP menggunakan redirect; UDP tersambung langsung.  
• `tproxy`: TCP dan UDP menggunakan TPROXY.  
• `mixed`: TCP menggunakan redirect dan UDP melalui TUN.  
• `enhance`: TCP menggunakan redirect dan UDP menggunakan TPROXY.    
• `tun`: TCP dan UDP melalui antarmuka TUN dengan rute otomatis.  
• Dukungan mode bergantung pada core: `xray` dan `v2fly` hanya menggunakan `tproxy`; `hysteria` mendukung `redirect`, `tproxy`, dan `enhance`. `clash` dan `sing-box` mendukung mode sesuai konfigurasi masing-masing.   

### Melewati proxy transparan saat menggunakan Wi-Fi atau hotspot
• Filter antarmuka jaringan terdapat di `/data/adb/box/ap.list.cfg`. Format `allow <prefix>` menyertakan antarmuka, sedangkan `ignore <prefix>` mengecualikannya. Awalnya, daftar `allow` mencakup `ap+`, `wlan+`, `rndis+`, `swlan+`, `ncm+`, dan `eth+`.  
• Untuk melewati proxy pada Wi-Fi, tambahkan `ignore wlan+` ke file tersebut. Agar lalu lintas hotspot tetap di-proxy, pastikan awalan antarmuka hotspot tercantum pada `allow`. Pada perangkat **MediaTek**, nama antarmukanya mungkin **ap+** atau **wlan+**.  
• Jalankan perintah `ifconfig` di terminal untuk mengetahui nama antarmuka AP.   

### Menjadwalkan pembaruan Geo dan langganan
• Buka `/data/adb/box/settings.ini` dan ubah `run_crontab="true"`. Aktifkan pembaruan yang diperlukan melalui `update_geo="true"` dan/atau `update_subscription="true"`. Pembaruan langganan mendukung `clash` dan `sing-box`.   
• Atur `interva_update` menggunakan sintaks cron. Nilai default-nya adalah `0 0,6,12,18 * * *` (empat kali sehari), bukan `@daily`.  
• Anda dapat menambahkan tugas terjadwal lainnya di `/data/adb/box/crontab.cfg`.  
```shell
  # start
  su -c /data/adb/box/scripts/box.service cron
  # stop
  su -c /data/adb/box/scripts/box.service kcron
```

## ▶️ Memulai & Menghentikan
### Masuk ke mode manual
• Untuk mengelola BFR secara manual melalui perintah, buat file `/data/adb/box/manual`. Dalam mode ini, layanan BFR **tidak akan dimulai otomatis saat perangkat dinyalakan**, dan Anda tidak dapat memulai atau menghentikan layanan melalui aplikasi Magisk/KernelSU Manager.   

### Memulai dan menghentikan layanan manajemen
• Skrip layanan BFR berada di `/data/adb/box/scripts/box.service`.    
• Skrip iptables BFR berada di `/data/adb/box/scripts/box.iptables`.    

```shell
# Mulai BFR
  su -c /data/adb/box/scripts/box.service start &&  su -c /data/adb/box/scripts/box.iptables enable

# Hentikan BFR
  su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```
• Perintah tersebut akan menampilkan log di terminal sekaligus menyimpannya ke file log.   

## Langganan dan pembaruan basis data Geo
Untuk memperbarui langganan dan basis data Geo secara bersamaan, jalankan:
```shell
  su -c /data/adb/box/scripts/box.tool geosub
```

Anda juga dapat memperbaruinya secara terpisah.
### Perbarui langganan
• Fitur ini hanya mendukung Clash.   
```shell
  su -c /data/adb/box/scripts/box.tool subs
```

### Perbarui basis data Geo
```shell
  su -c /data/adb/box/scripts/box.tool geox
```

## 📘 Petunjuk tambahan
• Tugas cron tambahan dapat ditambahkan ke `/data/adb/box/crontab.cfg`.  
• Dukungan IPv6 (`ipv6`) dan kontrol layanan berdasarkan status jaringan dinonaktifkan secara default. Pembatasan memori, CPU, dan I/O melalui cgroup juga dinonaktifkan secara default.    
• Saat mengubah file konfigurasi core, pastikan pengaturan terkait TPROXY sesuai dengan definisi dalam `/data/adb/box/settings.ini`.    
• Jika perangkat memiliki alamat IP publik, Anda dapat menambahkan IP tersebut ke jaringan internal dalam `/data/adb/box/scripts/box.iptables` untuk mencegah loop lalu lintas.   
• Log layanan BFR tersimpan di direktori **/data/adb/box/run**.   

Jalankan perintah berikut untuk melihat petunjuk penggunaan lainnya:

```shell
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|memcg|cpuset|blkio|bond0|bond1|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|webroot|all}
  su -c /data/adb/box/scripts/box.service
  # usage: $0 {start|stop|restart|status|cron|kcron}
  su -c /data/adb/box/scripts/box.iptables
  # usage: $0 {enable|disable|renew}
```

## 🗑️ Menghapus instalasi
• Menghapus modul ini melalui Magisk/KernelSU Manager juga akan menghapus file `/data/adb/service.d/box_service.sh` dan direktori data BFR di `/data/adb/box`.    
• Untuk menghapus data BFR secara manual, jalankan perintah berikut:    

```shell
  su -c rm -rf /data/adb/box
  su -c rm -rf /data/adb/service.d/box_service.sh
  su -c rm -rf /data/adb/modules/box_for_root
```