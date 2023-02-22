## WARNING
Proyek ini tidak bertanggung jawab atas: perangkat rusak, SDcard rusak, atau SoC terbakar.

**Pastikan file konfigurasi Anda tidak menyebabkan traffic loopback, jika tidak maka dapat menyebabkan ponsel Anda restart tanpa batas.**

Jika Anda benar-benar tidak tahu cara mengonfigurasi modul ini, Anda mungkin memerlukan aplikasi seperti `ClashForAndroid`, `v2rayNG`, `Surfboard`, `SagerNet`, `AnXray`, dll.

## install
- Download paket zip modul dari [RELEASE](https://github.com/taamarin/Box4Magisk/releases), dan install melalui [MAGISK](https://github.com/topjohnwu/Magisk), reboot
- pastikan terkoneksi internet, untuk download binery etc, executed:
```shell
  su -c /data/adb/box/scripts/box.tool upyacd
```
```shell
  su -c /data/adb/box/scripts/box.tool subgeo
```
```shell
  su -c /data/adb/box/scripts/box.tool upcore
```

- Mendukung pembaruan modul online berikutnya di Magisk Manager (memperbarui modul akan berlaku tanpa memulai ulang

### Notes
modul ini include:
 - [clash](https://github.com/Dreamacro/clash)、
 - [clash.meta](https://github.com/MetaCubeX/Clash.Meta)、[sing-box](https://github.com/SagerNet/sing-box)、
 - [v2ray-core](https://github.com/v2fly/v2ray-core)、
 - [Xray-core](https://github.com/XTLS/Xray-core).
 - [sing-box]().
  
Setelah modul terinstall, unduh file inti dari arsitektur perangkat Anda yang sesuai dan letakkan di direktori `/data/adb/box/bin/`, atau executed

```shell
su -c /data/adb/box/scripts/box.tool upcore
```

## konfigurasi
- bin_name:
  - clash
  - xray
  - v2ray
  - sing-box

- Setiap inti bekerja di direktori `/data/adb/box/bin/${bin_name}`, nama inti ditentukan oleh `bin_name` di file `/data/adb/box/settings.ini`.

- Setiap file konfigurasi inti perlu disesuaikan oleh pengguna, dan scripts akan memeriksa validitas konfigurasi, dan hasil pemeriksaan akan disimpan dalam file `/data/adb/box/run/runs.log`

- Tip: `clash` dan `sing-box` hadir dengan konfigurasi default yang siap bekerja dengan skrip proxy transparan. Untuk konfigurasi lebih lanjut, lihat dokumentasi resmi terkait. Alamat: [dokumen clash](https://github.com/Dreamacro/clash/wiki/configuration), [dokumen sing-box](https://sing-box.sagernet.org/configuration/outbound/)


## Instruksi
### Metode konvensional (metode standar & yang disarankan)
#### Memulai dan menghentikan layanan manajemen

**Layanan inti berikut secara kolektif disebut sebagai `BFM`**
- Layanan `BFM` akan berjalan secara otomatis setelah boot sistem secara default

- Anda dapat mengaktifkan atau menonaktifkan modul melalui aplikasi Magisk Manager **secara real time** memulai atau menghentikan layanan `BFM`, **tidak perlu memulai ulang perangkat**. Memulai layanan mungkin memerlukan waktu beberapa detik, menghentikan layanan dapat langsung berlaku

#### Pilih aplikasi (APP) yang membutuhkan proxy

- `BFM` default untuk memproksi semua aplikasi (APP) untuk semua pengguna Android

- Jika Anda ingin `BFM` mem-proxy semua aplikasi (APP), kecuali beberapa aplikasi tertentu, silakan buka file `/data/adb/box/settings.ini` dan ubah nilai `proxy_mode` menjadi `blacklist` (default), tambahkan package ke `packages_list`, contoh: `packages_list=("com.termux" "org.telegram.messenger")`
- dan gunakan `whitelist` jika ingin beberapa aplikasi (APP) yang akan di proxy

- Ketika nilai `proxy_mode` adalah `core`, proxy transparan tidak akan berfungsi, hanya kernel yang sesuai yang akan dimulai, yang dapat digunakan untuk mendukung TUN, untuk saat ini hanya `clash` dan `sing-box`

### penggunaan tingkat lanjut
#### mengubah mode proxy

- `BFM` menggunakan TPROXY untuk mem-proxy TCP + UDP secara transparan secara (default). Jika mendeteksi bahwa perangkat tidak mendukung TPROXY, buka `/data/adb/box/settings.ini` ubah `network_mode="redirect"` akan menggunakan `redirect` hanya untuk proxy TCP

- Buka file `/data/adb/box/settings.ini`, ubah nilai `network_mode` menjadi `redirect` , tproxy, atau `mixed`,
- `redirect: tcp` / `tproxy: udp + tcp` / `mixed: tcp + tun`

#### Lewati proxy transparan saat menghubungkan ke Wi-Fi atau hotspot
- `BFM` secara transparan memproksi `localhost` dan `hotspot` (termasuk tethering USB) secara default

- Buka file `/data/adb/box/settings.ini`, ubah `ignore_out_list` dan tambahkan `wlan+`, kemudian proxy transparan mem-bypass `wlan`, dan hotspot tidak terhubung dengan proxy

- Buka file `/data/adb/box/settings.ini`, ubah `ap_list` dan tambah `wlan+` `BFM` akan memproxy hotspot (model MediaTek mungkin `ap+` / `wlan+`)

- Gunakan perintah `ifconfig` di terminal , untuk mengetahui nama `AP`

#### masuk ke mode manual

Jika Anda ingin mengontrol `BFM` sepenuhnya dengan menjalankan perintah, buat saja file baru `/data/adb/box/manual`. Dalam hal ini, layanan `BFM` tidak akan **mulai otomatis** saat perangkat Anda dinyalakan, Anda juga tidak dapat mengatur mulai atau berhentinya layanan melalui aplikasi Magisk Manager.

#### Memulai dan menghentikan layanan manajemen

- Skrip layanan `BFM` adalah `/data/adb/box/scripts/box.service`

- Mulai `BFM`:
```shell
  su -c /data/adb/box/scripts/box.service start
```
- Stop `BFM`:
```shell
  su -c /data/adb/box/scripts/box.service stop
```

- Terminal akan mencetak log dan mengeluarkannya ke file log secara bersamaan

#### Kelola apakah proxy transparan diaktifkan

- Skrip proxy transparan adalah `/data/adb/box/scripts/box.tproxy`

- Aktifkan proxy transparan:
```shell
  su -c /data/adb/box/scripts/box.tproxy enable
```

- Nonaktifkan proxy transparan:
```shell
  su -c /data/adb/box/scripts/box.tproxy disable
```

## instruksi lainnya

- Saat memodifikasi setiap file konfigurasi inti, harap pastikan bahwa konfigurasi yang terkait dengan `tprxoy` konsisten dengan definisi di file `/data/adb/box/settings.ini`

- Jika mesin memiliki alamat **IP publik**, tambahkan IP ke `intranet` di file `/data/adb/box/settings.ini` untuk mencegah traffic loop

- Log untuk layanan `BFM` ada di direktori `/data/adb/box/run`


## uninstall

- Menghapus installan modul ini dari aplikasi Magisk Manager akan menghapus `/data/adb/service.d/box_service.sh` dan menyimpan direktori data `BFM` `/data/adb/box`

- Anda dapat menggunakan perintah untuk menghapus data `BFM`: 
```shell
  su -c rm -rf /data/adb/box
```
```shell
  su -c rm -rf /data/adb/service.d/box_service.sh
```

## CHANGELOG
[CHANGELOG](CHANGELOG.md)
