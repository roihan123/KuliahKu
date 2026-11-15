# KuliahKu

**KuliahKu** adalah aplikasi mobile berbasis **Flutter** yang dirancang untuk membantu mahasiswa mengelola aktivitas akademik sehari-hari secara terintegrasi, mulai dari jadwal kuliah, tugas & tenggat waktu, catatan perkuliahan, kalender akademik, hingga pengingat otomatis.

---

## Unduh Aplikasi (Android APK)

Untuk menginstal langsung di HP Android tanpa perlu melakukan *build* dari kode sumber:

1. Unduh file [**`app-release.apk`**](https://github.com/roihan123/KuliahKu/raw/main/app-release.apk) dari repositori ini (atau melalui menu **Releases** di GitHub).
2. Buka file `.apk` yang sudah diunduh di HP Android Anda (izinkan instalasi dari sumber tidak dikenal jika diminta).
3. Masuk menggunakan akun baru (menu **Daftar**) atau gunakan akun demo bawaan:
   - **Email:** `test@test.com`
   - **Password:** `password`

---

## Fitur Utama

* **Autentikasi & Keamanan Akun (`AuthPage` & `AuthService`)**
  * Sistem **Masuk (Login)** dan **Daftar (Register)** dengan validasi email, NIM, program studi, dan semester.
  * Password disimpan secara aman menggunakan *hashing* **SHA-256 berlapis dengan *random salt*** (`crypto`).
  * Penyimpanan sesi otomatis (`session.json`) dan migrasi otomatis dari format data versi lama.

* **Beranda / Dashboard (`BerandaPage`)**
  * Menampilkan sapaan personal, nama mahasiswa, program studi, dan semester aktif.
  * Ringkasan statistik akademik (jumlah kelas hari ini, tugas mendesak, dan total catatan).
  * Daftar **Jadwal Hari Ini** beserta indikator kelas yang sedang berlangsung (*live badge*).
  * Daftar **Tugas Mendesak** (tenggat $\le 3$ hari atau terlambat) yang dapat langsung ditandai selesai.
  * Pratinjau **Catatan Terbaru** dan akses cepat ke halaman **Notifikasi** & **Profil**.

* **Jadwal Kuliah (`JadwalPage`)**
  * Tambah, ubah, dan hapus jadwal kuliah per hari (**Senin – Minggu**) dengan dukungan **Undo** saat menghapus.
  * **Deteksi jadwal bentrok otomatis** (*conflict warning*) jika ada kelas lain di hari dan jam yang bertabrakan.
  * Saran nama mata kuliah otomatis (*autocomplete*) berdasarkan data mata kuliah yang sudah pernah dimasukkan.

* **Tugas Kuliah (`TugasPage`)**
  * Kelola tugas akademik lengkap dengan judul, mata kuliah, deskripsi, dan tanggal tenggat (*due date*).
  * Filter tugas berdasarkan kategori: **Semua**, **Mendesak**, **Minggu Ini**, dan **Selesai**, dilengkapi fitur pencarian.
  * Lencana (*badge*) status tenggat otomatis: *Terlambat*, *Hari Ini*, *Besok*, atau *N hari lagi*.
  * Tandai tugas selesai/belum selesai secara instan dan fitur **Undo** saat menghapus tugas.

* **Catatan Perkuliahan (`CatatanPage`)**
  * Buat, baca, sunting, dan hapus catatan kuliah dalam tampilan *staggered grid* (`flutter_staggered_grid_view`).
  * Kelompokkan dan filter catatan berdasarkan kategori mata kuliah.
  * Pencarian cepat berdasarkan judul, isi catatan, maupun nama mata kuliah.

* **Kalender Akademik (`KalenderPage`)**
  * Kalender bulanan interaktif yang menggabungkan jadwal kuliah rutin mingguan dan tenggat tugas pada setiap tanggal.
  * Indikator titik warna pada tanggal yang memiliki kelas atau tenggat tugas.
  * Navigasi antarbulan serta tombol kembali cepat ke **Hari Ini**.

* **Notifikasi In-App (`NotifikasiPage`)**
  * Pengingat otomatis untuk tugas yang terlambat, jatuh tempo hari ini, jatuh tempo dalam $\le 3$ hari, serta daftar kelas hari ini.
  * Status baca (*read/unread*) yang tersimpan secara persisten dengan opsi **Tandai semua dibaca**.

* **Profil & Pengaturan (`ProfilePage` & `SettingsService`)**
  * Lihat dan perbarui informasi akademik (Nama Lengkap, NIM, Program Studi, Semester).
  * **Manajemen Semester Aktif** (pilih Semester 1–14 secara cepat).
  * Pengaturan **Mode Gelap (*Dark Mode*)** dan *toggle* **Notifikasi Pengingat** yang tersimpan otomatis.

* **Penyimpanan Lokal Atomik (`JsonStorage`)**
  * Seluruh data disimpan secara lokal di perangkat dalam format JSON (`users.json`, `session.json`, `jadwal.json`, `tasks.json`, `notes.json`, `notifications_state.json`, `settings.json`).
  * Menggunakan mekanisme *atomic write* (`.tmp` lalu *rename*) dan antrian penulisan (*write queue*) untuk mencegah korupsi file.
  * Unfortunately penyimpanan FULLY local jadi tidak bisa digunakan di device berbeda dan hanya untuk mobile device.. belum integrasi dengan desktop.

---

## Struktur Repositori & Proyek

Repositori ini memiliki struktur direktori sebagai berikut:

```text
KuliahKu/                           # Root repository Git
├── README.md                       # Dokumentasi utama repositori GitHub
├── app-release.apk                 # File APK rilis siap unduh & instal di Android
└── KuliahKu/                       # Direktori proyek Flutter utama
    ├── android/                    # Konfigurasi platform Android
    ├── ios/                        # Konfigurasi platform iOS
    ├── windows/                    # Konfigurasi platform Windows Desktop
    ├── linux/                      # Konfigurasi platform Linux
    ├── macos/                      # Konfigurasi platform macOS
    ├── assets/images/              # Aset gambar & logo aplikasi (KKlogo, KuliahkuBanner)
    ├── pubspec.yaml                # Konfigurasi paket & dependensi Flutter
    └── lib/                        # Kode sumber utama Dart/Flutter
        ├── main.dart               # Entry point aplikasi & inisialisasi service
        ├── core/
        │   ├── app_scope.dart      # InheritedWidget penyedia state & service terpusat
        │   ├── app_theme.dart      # Konfigurasi tema Material 3 (Light & Dark Mode)
        │   ├── date_utils.dart     # Utilitas pemformatan tanggal Bahasa Indonesia
        │   └── validators.dart     # Validasi input form (email, password, NIM, jam, dll.)
        ├── models/
        │   ├── app_notification.dart
        │   ├── app_user.dart
        │   ├── note.dart
        │   ├── schedule.dart
        │   └── task.dart
        ├── pages/
        │   ├── auth_page.dart      # Halaman Login & Registrasi
        │   ├── main_shell.dart     # Navigasi utama (Bottom Navigation Bar 5 tab)
        │   ├── beranda_page.dart   # Tab 1: Beranda / Dashboard
        │   ├── jadwal_page.dart    # Tab 2: Jadwal Kuliah
        │   ├── tugas_page.dart     # Tab 3: Tugas Kuliah
        │   ├── catatan_page.dart   # Tab 4: Catatan Perkuliahan
        │   ├── kalender_page.dart  # Tab 5: Kalender Akademik
        │   ├── notifikasi_page.dart# Halaman Notifikasi In-App
        │   └── profile_page.dart   # Halaman Profil & Pengaturan
        ├── services/
        │   ├── academic_data_service.dart # State & CRUD terpusat (Jadwal, Tugas, Catatan, Notif)
        │   ├── auth_service.dart          # Autentikasi, sesi, & hashing password
        │   ├── json_storage.dart          # Penyimpanan file JSON lokal atomik
        │   └── settings_service.dart      # Pengaturan tema (Dark/Light) & notifikasi
        └── widgets/
            ├── course_suggestion_field.dart # Input mata kuliah dengan saran otomatis
            ├── delete_confirmation.dart     # Dialog konfirmasi hapus & helper Undo SnackBar
            └── empty_state_card.dart        # Komponen tampilan saat daftar kosong
```

---

## Cara Menjalankan Proyek (Development)

### 1. Prasyarat
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.7.2`)
* Emulator Android / Perangkat Android fisik (dengan *USB Debugging* aktif), atau Windows Desktop.
  > **Catatan:** Aplikasi menggunakan `dart:io` dan `path_provider` untuk penyimpanan file lokal, sehingga harus dijalankan di **Android**, **iOS**, atau **Desktop (Windows/Linux/macOS)** — bukan di Web Browser.

### 2. Clone & Masuk ke Direktori Proyek Flutter
Karena proyek Flutter berada di dalam subfolder `KuliahKu/`, pastikan Anda masuk ke folder tersebut sebelum menjalankan perintah `flutter`:

```bash
git clone https://github.com/roihan123/KuliahKu.git
cd KuliahKu/KuliahKu
```

### 3. Instal Dependensi & Jalankan
```bash
flutter pub get
flutter run
```

### 4. Cara Build File APK (Untuk Diinstal di HP Android)
Dari dalam folder `KuliahKu/KuliahKu`, jalankan:

```bash
flutter build apk --release
```
File APK hasil *build* akan tersedia di:
```text
KuliahKu/build/app/outputs/flutter-apk/app-release.apk
```

---

## Dependensi Utama

* `flutter_localizations` & `intl` (`^0.19.0`) — Lokalisasi dan format tanggal Bahasa Indonesia (`id_ID`).
* `path_provider` (`^2.1.2`) — Akses direktori dokumen lokal perangkat untuk penyimpanan JSON.
* `flutter_staggered_grid_view` (`^0.7.0`) — Tata letak *masonry grid* pada halaman Catatan.
* `crypto` (`^3.0.8`) — *Hashing* SHA-256 berlapis untuk keamanan password pengguna.
* `flutter_launcher_icons` (`^0.13.1`) — Konfigurasi ikon aplikasi Android & iOS.
