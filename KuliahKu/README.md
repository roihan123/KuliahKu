# KuliahKu (Flutter Project)

Direktori ini berisi kode sumber utama aplikasi **Flutter KuliahKu**.
Dokumentasi lengkap mengenai fitur, arsitektur, dan cara mengunduh APK tersedia pada [README utama repositori](../README.md).

## Menjalankan Aplikasi

Pastikan terminal berada di direktori ini (`KuliahKu/KuliahKu`), lalu jalankan:

```bash
flutter pub get
flutter run
```

> **Catatan:** Jalankan pada target **Android** (Emulator/Perangkat fisik) atau **Desktop (Windows/Linux/macOS)** karena penyimpanan lokal menggunakan `dart:io` dan `path_provider`.

## Membuat Build APK Rilis

```bash
flutter build apk --release
```

Hasil *build* APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.
