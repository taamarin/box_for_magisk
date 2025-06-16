# 📦 Box for Magisk / KernelSU

## ⚠️ Peringatan

Proyek ini tidak bertanggung jawab atas: perangkat yang rusak, kartu SD yang rusak, atau SoC yang terbakar.

**Harap pastikan file konfigurasi Anda tidak menyebabkan loop lalu lintas, jika tidak maka dapat menyebabkan ponsel Anda restart tanpa batas.**

Jika Anda benar-benar tidak tahu cara mengonfigurasi modul ini, Anda mungkin memerlukan aplikasi seperti **ClashForAndroid, ClashMetaForAndroid, v2rayNG, Surfboard, SagerNet, AnXray, NekoBox, SFA**, dll.

## 📦 Instalasi
• Unduh paket zip modul dari [RELEASE](https://github.com/taamarin/box_for_magisk/releases) dan instal melalui `Magisk/APatch/KernelSU`. Saat menginstal, Anda akan ditanya apakah akan mengunduh paket lengkap, Anda dapat memilih **unduhan lengkap** atau **unduhan terpisah** nanti, lalu mulai ulang perangkat.  
• Module ini mendukung pembaruan Module langsung berikutnya di `Magisk/APatch/KernelSU Manager` (Module yang diperbarui akan berlaku tanpa me-reboot perangkat).  

### Pembaruan Kernel
Modul ini mencakup kernel berikut:  
• [clash](https://github.com/Dreamacro/clash)(repo dihapus)   
• [clash.meta](https://github.com/MetaCubeX/mihomo)   
• [sing-box](https://github.com/SagerNet/sing-box)  
• [v2ray-core](https://github.com/v2fly/v2ray-core)  
• [Xray-core](https://github.com/XTLS/Xray-core)  
• [hysteria]()  

Konfigurasi yang sesuai dengan kernel adalah `${bin_name}`, yang dapat diatur ke ( `clash` | `xray` | `v2ray` | `sing-box` | `hysteria`).  
Setiap core bekerja di direktori `/data/adb/box/bin/${bin_name}`, nama core ditentukan oleh `bin_name` di file `/data/adb/box/settings.ini`.  

Pastikan Anda terhubung ke internet dan jalankan perintah berikut untuk memperbarui file kernel:  
```shell
# perbarui kernel yang dipilih, sesuai dengan `bin_name`
su -c /data/adb/box/scripts/box.tool upkernel
```

Jika Anda menggunakan `clash/sing-box` sebagai kernel yang dipilih, Anda mungkin juga perlu menjalankan perintah berikut untuk dapat menggunakan panel kontro(dashboard):  
```shell
# Perbarui panel admin clash/sing-box
su -c /data/adb/box/scripts/box.tool upxui
```

Alternatifnya, Anda dapat melakukannya sekaligus (yang mungkin menghabiskan ruang penyimpanan secara tidak perlu):  
```shell
# Perbarui semua file (termasuk berbagai jenis kernel dan GeoX)
su -c /data/adb/box/scripts/box.tool all
```

## ⚙️ Konfigurasi
**Layanan inti berikut disebut sebagai BFR**
• Layanan inti berikut secara kolektif disebut sebagai BFR  
• Anda dapat mengaktifkan atau menonaktifkan modul untuk memulai atau menghentikan layanan BFR secara real time melalui aplikasi Magisk/KernelSU Manager tanpa harus me-reboot perangkat. Memulai layanan mungkin memerlukan waktu beberapa detik, penghentian layanan akan segera berlaku. 

### konfigurasi inti
• Untuk konfigurasi inti `bin_name`, silakan lihat bagian **Pembaruan Kernel** untuk konfigurasi.   
• Setiap file konfigurasi inti perlu dikustomisasi oleh pengguna, dan skrip akan memeriksa validitas konfigurasi, dan hasil pemeriksaan akan disimpan di file `/data/adb/box/run/runs.log`.   
• Tip: Baik `clash` dan `sing-box` datang dengan pra-konfigurasi dengan skrip proxy transparan. Untuk konfigurasi lebih lanjut, silakan merujuk ke dokumentasi resmi. Alamat: [dokumen resmi Clash](https://github.com/Dreamacro/clash/wiki/configuration) delete, [dokumen resmi sing-box](https://sing-box.sagernet.org/configuration/outbound/).  

### Menerapkan pemfilteran (blacklist/whitelist)
• BFR menyediakan proxy untuk semua aplikasi (aplikasi) dari semua pengguna Android secara default.   
• Jika Anda ingin BFR **mem-proxy semua aplikasi (aplikasi), kecuali beberapa aplikasi**, silakan buka file `/data/adb/box/package.list.cfg`, ubah nilai `mode` menjadi `blacklist` (default), tambahkan aplikasi yang akan dikecualika , misalnya:   
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**  
• Jika Anda hanya ingin **mem-proxy aplikasi (aplikasi) tertentu**, gunakan `mode:whitelist`, dan tambahkan (aplikasi) yang hanya ingin di proxy, misalnya:   
  ↳ **com.termux**  
  ↳ **org.telegram.messenger**    
> ⚠️ Jika CLASH digunakan, blacklist/whitelist tidak akan berlaku dalam mode fake-ip. 

### Proxy Transparan untuk Proses Tertentu
• BFR secara default melakukan proxy transparan untuk semua proses.   
• Jika Anda ingin BFR melakukan proxy untuk semua proses kecuali beberapa proses tertentu, buka berkas `/data/adb/box/package.list.cfg`, ubah nilai `mode` menjadi `blacklist` (nilai default), lalu tambahkan elemen GID, dengan GID dipisahkan oleh enter(↳). Ini akan mengakibatkan proses dengan GID yang sesuai **tidak diproksikan**.   
• Jika Anda ingin hanya melakukan proxy transparan untuk proses tertentu, buka berkas `/data/adb/box/package.list.cfg`, ubah nilai `mode` menjadi `whitelist`, lalu tambahkan elemen GID, dengan GID dipisahkan oleh enter(↳). Ini akan mengakibatkan proses dengan GID yang sesuai **diproksikan**.   
> ⚠️ Karena iptables Android tidak mendukung pencocokan ekstensi PID, pencocokan proses oleh Box dilakukan melalui pencocokan GID secara tidak langsung. Di Android dapat menggunakan perintah setuidgid busybox untuk memulai proses tertentu dengan UID tertentu, GID apa pun.

### mengubah mode proxy
• BFR menggunakan TPROXY untuk mem-proxy TCP+UDP secara transparan (default). Jika terdeteksi bahwa perangkat tidak mendukung TPROXY, buka `/data/adb/box/settings.ini` dan ubah `network_mode="tproxy"` menjadi `redirect` yang hanya menggunakan proxy TCP.   
• redirect：redirect(TCP) + Direct(UDP)  
• tproxy：tproxy(TCP + UDP)  
• mixed：redirect(TCP) + tun(UDP).   
• enhance: redirect(TCP) + tproxy(UDP)    
• tun: TCP + UDP (auto-route)   

### Lewati proxy transparan saat menghubungkan ke Wi-Fi atau hotspot
• BFR secara transparan memproksi `localhost` dan `hotspot` (termasuk tethering USB) secara default.  
• Buka file `/data/adb/box/ap.list.cfg`, tambahkan **ignore wlan+**, sehingga proxy transparan akan mem-bypass `wlan` dan `hotspot` **tidak akan terhubung ke proxy**.  
• Buka file `/data/adb/box/ap.list.cfg`, tambahkan **allow wlan+**(konflik dengan **ignore wlan+**). BFR akan **mem-proxy hotspot** (mungkin **ap+ / wlan+** untuk perangkat **Mediatek**).  
• Gunakan perintah `ifconfig` di Terminal untuk mengetahui nama AP.   

### Aktifkan Cron Job untuk memperbarui Geo dan Subs sesuai jadwal secara otomatis
• Buka file `/data/adb/box/settings.ini`, ubah nilai `run_crontab=true`, `update_geo="true"`, `update_subscription="true"` dan atur `interva_update="@daily"` (default), sesuaikan dengan yang anda inginkan.   
• Maka secara otomatis Geox dan Subs akan diperbarui sesuai jadwal interva_update.  
• Anda bisa menambahkan **scheduled tasks** lainnya di `/data/adb/box/crontab.cfg`  
```shell
  # start
  su -c /data/adb/box/scripts/box.service cron
  # stop
  su -c /data/adb/box/scripts/box.service kcron
```

## ▶️ Memulai & Menghentikan
### Masuk ke mode manual
• Jika Anda ingin memiliki kontrol penuh atas BFR dengan menjalankan perintah, buat saja file baru bernama `/data/adb/box/manual`. Dalam hal ini, layanan BFR **tidak akan dimulai secara otomatis saat perangkat Anda dihidupkan)**, Anda juga tidak dapat mengatur mulai atau berhentinya layanan melalui aplikasi Magisk/KernelSU Manager.   

### Memulai dan menghentikan layanan manajemen
• Skrip layanan BFR adalah /data/adb/box/scripts/box.service    
• Skrip Iptables BFR adalah /data/adb/box/scripts/box.iptables    

```shell
# Mulai BFR
  su -c /data/adb/box/scripts/box.service start &&  su -c /data/adb/box/scripts/box.iptables enable

# Hentikan BFR
  su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```
• Terminal akan mencetak log pada saat yang sama dan mengeluarkannya ke file log.   

## Langganan dan pembaruan basis data Geo
Anda dapat memperbarui langganan dan basis data Geo secara bersamaan menggunakan perintah berikut:
```shell
  su -c /data/adb/box/scripts/box.tool geosub
```

Atau Anda dapat memperbaruinya satu per satu.
### perbarui langganan
• hanya mendukung untuk Clash   
```shell
  su -c /data/adb/box/scripts/box.tool subs
```

### Perbarui basis data Geo
```shell
  su -c /data/adb/box/scripts/box.tool geox
```

## 📘 Instruksi Tambahan
• Saat memodifikasi salah satu file konfigurasi inti, pastikan konfigurasi terkait cocok dengan definisi di file `/data/adb/box/settings.ini`.    
• Jika perangkat memiliki alamat IP publik, tambahkan IP tersebut ke jaringan internal di file `/data/adb/box/scripts/box.iptables` untuk mencegah pengulangan lalu lintas.   
• Log untuk layanan BFR dapat ditemukan di direktori **/data/adb/box/run**.   

Anda dapat menjalankan perintah berikut untuk mendapatkan instruksi operasi terkait lainnya:

```shell
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|all}
  su -c /data/adb/box/scripts/box.service
  # usage: $0 {start|stop|restart|status|cron|kcron}
  su -c /data/adb/box/scripts/box.iptables
  # usage: $0 {enable|disable|renew}
```

## 🗑️ Uninstall
• Instalasi yang menghapus modul ini dari Magisk/KernelSU Manager, akan menghapus file `/data/adb/service.d/box_service.sh` dan direktori data BFR di `/data/adb/box.`    
• Anda dapat menghapus data BFR dengan perintah berikut:    

```shell
  su -c rm -rf /data/adb/box
  su -c rm -rf /data/adb/service.d/box_service.sh
  su -c rm -rf /data/adb/modules/box_for_root
```