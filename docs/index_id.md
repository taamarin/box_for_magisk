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
• [hysteria]()  

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
• Jika ingin BFR **mem-proxy semua aplikasi kecuali beberapa aplikasi tertentu**, buka file `/data/adb/box/package.list.cfg`, ubah nilai `mode` menjadi `blacklist` (default), lalu tambahkan aplikasi yang ingin dikecualikan, misalnya:   
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**  
• Jika hanya ingin **mem-proxy aplikasi tertentu**, gunakan `mode:whitelist`, lalu tambahkan aplikasi yang ingin di-proxy, misalnya:   
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**    
> ⚠️ Jika menggunakan Clash, daftar blokir dan daftar izin tidak berlaku dalam mode fake-IP.

### Proxy Transparan untuk Proses Tertentu
• Secara default, BFR mem-proxy lalu lintas dari semua proses secara transparan.   
• Untuk mem-proxy semua proses kecuali beberapa proses tertentu, buka `/data/adb/box/package.list.cfg`, ubah nilai `mode` menjadi `blacklist` (default), lalu tambahkan GID terkait, masing-masing pada baris terpisah. Proses dengan GID tersebut **tidak akan di-proxy**.   
• Untuk mem-proxy hanya proses tertentu, ubah nilai `mode` menjadi `whitelist`, lalu tambahkan GID terkait, masing-masing pada baris terpisah. Hanya proses dengan GID tersebut yang **akan di-proxy**.   
> ⚠️ Iptables Android tidak mendukung pencocokan PID secara langsung, sehingga Box mencocokkan proses secara tidak langsung melalui GID. Di Android, Anda dapat menggunakan perintah `busybox setuidgid` untuk menjalankan proses dengan UID tertentu dan GID apa pun.

### Mengubah mode jaringan
• Secara default, BFR menggunakan TPROXY untuk mem-proxy lalu lintas TCP dan UDP secara transparan. Jika perangkat tidak mendukung TPROXY, buka `/data/adb/box/settings.ini` dan ubah `network_mode` menjadi `redirect`, yang hanya mem-proxy TCP.   
• redirect：redirect(TCP) + Direct(UDP)  
• tproxy：tproxy(TCP + UDP)  
• mixed：redirect(TCP) + tun(UDP).   
• enhance: redirect(TCP) + tproxy(UDP)    
• tun: TCP + UDP (auto-route)   

### Melewati proxy transparan saat menggunakan Wi-Fi atau hotspot
• Secara default, BFR mem-proxy lalu lintas `localhost` dan hotspot, termasuk tethering USB.  
• Untuk melewati proxy saat menggunakan Wi-Fi, buka `/data/adb/box/ap.list.cfg` dan tambahkan **ignore wlan+**. Dengan begitu, lalu lintas melalui `wlan` dan hotspot **tidak akan di-proxy**.  
• Untuk mem-proxy hotspot, tambahkan **allow wlan+** ke file yang sama. Pengaturan ini bertentangan dengan **ignore wlan+**. Pada perangkat **MediaTek**, nama antarmukanya mungkin **ap+** atau **wlan+**.  
• Jalankan perintah `ifconfig` di terminal untuk mengetahui nama antarmuka AP.   

### Menjadwalkan pembaruan Geo dan langganan
• Buka `/data/adb/box/settings.ini`, ubah `run_crontab=true`, `update_geo="true"`, dan `update_subscription="true"`, lalu atur `interva_update="@daily"` (default) atau jadwal yang Anda inginkan.   
• Geo dan langganan akan diperbarui secara otomatis sesuai jadwal `interva_update`.  
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
• Saat mengubah file konfigurasi core, pastikan pengaturan terkait TPROXY sesuai dengan definisi dalam `/data/adb/box/settings.ini`.    
• Jika perangkat memiliki alamat IP publik, Anda dapat menambahkan IP tersebut ke jaringan internal dalam `/data/adb/box/scripts/box.iptables` untuk mencegah loop lalu lintas.   
• Log layanan BFR tersimpan di direktori **/data/adb/box/run**.   

Jalankan perintah berikut untuk melihat petunjuk penggunaan lainnya:

```shell
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|all}
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