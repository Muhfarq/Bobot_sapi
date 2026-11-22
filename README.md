# Bobot Sapi

Aplikasi Flutter **offline** untuk membantu peternak mencatat pengukuran sapi, memperkirakan bobot dan tanggal panen, serta menghitung kebutuhan pakan harian.

Seluruh data disimpan lokal di perangkat menggunakan SQLite. Tidak ada login, API, cloud, atau koneksi internet yang diperlukan setelah aplikasi terpasang.

---

## Daftar Isi

- [Tentang Aplikasi](#tentang-aplikasi)
- [Fitur Utama](#fitur-utama)
- [Cara Kerja Perhitungan](#cara-kerja-perhitungan)
- [Menjalankan Proyek](#menjalankan-proyek)
- [Panduan Penggunaan](#panduan-penggunaan)
- [Penyimpanan Data](#penyimpanan-data)
- [Struktur Proyek](#struktur-proyek)
- [Pemecahan Masalah](#pemecahan-masalah)

---

## Tentang Aplikasi

`Bobot Sapi` dibuat untuk menyederhanakan dua kebutuhan utama di lapangan:

1. **Mencatat perkembangan sapi** — mulai dari pengukuran lingkar dada, panjang badan, tinggi gumba, dan kondisi poel, lalu melihat estimasi bobot serta target panen.
2. **Merencanakan pakan** — menghitung kebutuhan bahan kering (BK) per hari berdasarkan bobot terbaru sapi, lalu membandingkannya dengan jumlah hijauan dan konsentrat yang tersedia.

Aplikasi dapat dipakai tanpa sapi tertentu (kalkulator bebas), atau dengan memilih sapi agar bobot diisi otomatis dari pengukuran terakhir yang tersimpan di History.

---

## Fitur Utama

Navigasi bawah aplikasi terdiri dari **4 tab**:

| Tab | Fitur |
| --- | --- |
| **Input** | Input data sapi baru: nama, tanggal masuk, lingkar dada, panjang badan, tinggi gumba, dan poel (`Poel 0`–`Poel 4`). Isi goal panen dalam hari, tekan **Hitung** untuk melihat estimasi, lalu **Simpan Data**. Kartu hasil menampilkan **Bobot Awal** besar, estimasi panen, dan tanggal panen, dilengkapi grafik proyeksi bobot. |
| **Hitung** | Kalkulator rekomendasi pakan: pilih sapi (opsional), bobot terakhir (bisa diedit manual), jenis rumput dari daftar ±29 jenis, berat rumput segar, dan berat konsentrat. Menampilkan estimasi BK/hari, status **Mantap!** atau **Perlu Diperhatikan Lagi**, serta rincian konversi BK hijauan dan konsentrat. Hasil kalkulasi **tidak disimpan** ke database. |
| **Update** | Cari sapi yang sudah ada, lalu buka form pembaruan untuk menambah pengukuran terbaru. Data terbaru otomatis dipakai sebagai "bobot terakhir" di tab Hitung Pakan. |
| **History** | Lihat daftar sapi dan riwayat pengukurannya per tanggal, lihat detail + grafik perkembangan, ubah/hapus pengukuran, hapus sapi beserta riwayatnya, dan ekspor/cetak laporan ke PDF. |

Fitur pendukung lain:

- Validasi input dengan notifikasi (snack bar) yang konsisten.
- Pencarian sapi di tab Update, History, dan di picker tab Hitung Pakan.
- Pilih sapi di tab Hitung Pakan: bobot otomatis terisi dari pengukuran terakhir (`tanggal DESC, id DESC`), dengan keterangan **Diukur dd/MM/yyyy** atau **Diubah manual**.
- Picker sapi boleh dikosongkan lewat tombol **X**; bobot yang sudah diisi tidak ikut terhapus.
- Daftar sapi selalu dimuat ulang saat bottom sheet picker dibuka, sehingga data baru langsung terbaca.
- Tampilan responsif untuk penggunaan di lapangan, dengan warna hijau sebagai identitas aplikasi.

---

## Cara Kerja Perhitungan

Perhitungan menggunakan asumsi yang disederhanakan dan dapat disesuaikan di `lib/utils/calculator.dart`.

### Estimasi bobot dan panen

- **Rumus Schoorl** dari lingkar dada (cm):

  ```text
  bobot (kg) = (lingkar dada + 22)² / 100
  ```

- **Estimasi pakan** = `3% × bobot` (dalam kg bahan kering per hari).
- **Target panen** dihitung dari goal hari:

  ```text
  bobot panen = bobot awal + (1 kg/hari × jumlah hari)
  tanggal panen = tanggal pengukuran + jumlah hari
  ```

- Asumsi **ADG (pertambahan bobot harian) = 1 kg/hari**.

### Kalkulator pakan

- Kebutuhan BK harian diambil dari estimasi `3% × bobot terakhir`.
- **BK hijauan** = `berat rumput segar × kadar BK rumput / 100` (kadar BK bersumber dari data tiap jenis rumput).
- **BK konsentrat** = `berat konsentrat × 0,88` (asumsi kadar BK konsentrat).
- **Total BK** = BK hijauan + BK konsentrat.
  - Jika `total BK ≥ kebutuhan BK` → status **Mantap!**
  - Jika `total BK < kebutuhan BK` → status **Perlu Diperhatikan Lagi** dan ditampilkan selisih kekurangannya.

> Catatan: tinggi gumba dan poel bersifat informasi pendukung. Keduanya **tidak** masuk ke rumus bobot maupun pakan.

---

## Menjalankan Proyek

### Prasyarat

- Flutter SDK dengan Dart SDK `^3.11.5` (cek dengan `flutter --version`).
- Android Studio / Xcode untuk emulator, **atau** perangkat fisik dengan USB debugging.
- Untuk build Windows: Visual Studio dengan workload *Desktop development with C++*.

### Instalasi dan menjalankan

```bash
# 1. Masuk ke folder proyek
cd Bobot_sapi

# 2. Unduh dependency
flutter pub get

# 3. Jalankan aplikasi (pilih perangkat yang tersedia)
flutter run
```

Cek perangkat yang tersedia dengan:

```bash
flutter devices
```

### Build aplikasi

```bash
# Android (APK debug)
flutter build apk --debug

# Android (APK release)
flutter build apk --release

# Windows (debug)
flutter build windows --debug
```

Hasil build Android ada di `build/app/outputs/flutter-apk/`, sedangkan Windows ada di `build/windows/x64/runner/Debug/`.

---

## Panduan Penggunaan

### 1. Tab **Input** — mencatat sapi baru

1. Isi **Nama Sapi** dan **Tanggal Masuk** (ketuk tanggal untuk memilih via kalender).
2. Isi pengukuran:
   - **Lingkar Dada (cm)** — wajib, dipakai rumus Schoorl.
   - **Panjang Badan (cm)** dan **Tinggi Gumba (cm)** — opsional, sebagai catatan.
   - **Poel** — opsional, pilih `Poel 0` sampai `Poel 4`.
3. Isi **Goal Panen (hari)**, misalnya `90`.
4. Tekan tombol **Hitung**. Kartu hasil akan menampilkan:
   - **Bobot Awal** estimasi dalam kg (angka besar),
   - **Estimasi Panen** dan **Tanggal Panen**,
   - grafik proyeksi bobot beberapa bulan ke depan.
5. Tekan **Simpan Data** untuk menyimpan sapi beserta pengukurannya ke database. Form akan dikosongkan otomatis setelah berhasil.

> Data belum tersimpan sampai tombol **Simpan Data** ditekan. Tombol **Hitung** hanya menampilkan estimasi.

### 2. Tab **Hitung** — menghitung kebutuhan pakan

1. **(Opsional)** Ketuk field **Pilih Sapi**, lalu cari dan pilih sapi dari daftar.
   - Jika sapi memiliki pengukuran, kolom **Bobot Terakhir** terisi otomatis dan muncul keterangan `Diukur dd/MM/yyyy`.
   - Jika belum ada pengukuran, muncul snack bar dan bobot yang sudah ada dibiarkan.
   - Tombol **X** pada field mengosongkan pilihan sapi tanpa menghapus bobot.
2. Kolom **Bobot Terakhir** tetap bisa diedit manual. Jika sapi sedang dipilih lalu bobot diubah, keterangannya berubah menjadi `Diubah manual`.
3. Di bagian **Pakan Hijau (Hijauan)**:
   - Pilih **Jenis Rumput** (misalnya rumput field, odot, rnai, dll.).
   - Isi **Berat Rumput Yang Digunakan (Kg)** dalam berat segar.
4. Di bagian **Pakan Konsentrat**, isi **Berat Konsentrat Yang Digunakan (Kg)**.
5. Tekan tombol **Hitung**.
6. Kartu hasil menampilkan:
   - `Untuk: <nama sapi>` bila sapi dipilih,
   - banner **Mantap!** atau **Perlu Diperhatikan Lagi**,
   - **Total Pakan** (kg BK),
   - rincian hijauan segar → BK dan konsentrat → BK.

Hasil di tab ini bersifat sementara dan **tidak disimpan** ke database.

### 3. Tab **Update** — menambah pengukuran terbaru

1. Ketuk kolom **Cari Sapi** untuk memfilter daftar sapi.
2. Ketuk kartu sapi yang ingin diperbarui.
3. Isi form pengukuran terbaru (tanggal, lingkar dada, bobot, target, dan sebagainya), lalu simpan.
4. Kembali ke tab **Hitung** — data terbaru kini dipakai sebagai bobot terakhir saat sapi tersebut dipilih.

### 4. Tab **History** — riwayat dan laporan

1. Cari sapi pada kolom pencarian.
2. Ketuk kartu sapi untuk melihat riwayat pengukuran per tanggal, lengkap dengan grafik perkembangan.
3. Ketuk salah satu riwayat untuk melihat detail pengukuran; dari sini riwayat juga bisa dihapus.
4. Untuk ekspor PDF:
   1. Aktifkan mode pilih dengan mengetuk tombol **Pilih** di header, atau dengan menahan kartu sapi.
   2. Centang satu atau beberapa sapi.
   3. Ketuk tombol ekspor, lalu pilih **Simpan sebagai PDF** atau **Print** dari dialog sistem.
5. Untuk menghapus sapi beserta seluruh riwayatnya, pilih sapi lalu gunakan tombol **Hapus** dan konfirmasi.

> Menghapus sapi akan menghapus semua pengukurannya. Tindakan ini tidak dapat dibatalkan.

---

## Penyimpanan Data

- Database lokal: `bobot_sapi.db` (SQLite), versi skema **4**.
- Tabel:
  - `sapi`: `id`, `nama_sapi`, `tanggal_masuk`.
  - `pengukuran`: hasil ukur dan estimasi, termasuk `tinggi_gumba`, `poel`, dan `estimasi_pakan`.
- Migrasi dari versi lama berjalan otomatis saat aplikasi dibuka (v2 → `goal_hari`, v3 → `panjang_badan`, v4 → `tinggi_gumba` dan `poel`) tanpa menghapus data yang sudah ada.
- Android/iOS memakai factory `sqflite` bawaan. Windows/Linux/macOS memakai `sqflite_common_ffi` yang diinisialisasi di `main()` sebelum aplikasi dijalankan.
- Tidak ada sinkronisasi antarperangkat. Data mengikuti perangkat tempat aplikasi dipakai.

---

## Struktur Proyek

```text
lib/
├── main.dart                      # Entry point + inisialisasi database
├── database/
│   ├── db_helper.dart             # Skema, migrasi, dan query database
│   ├── database_factory.dart      # Pilih implementasi database per platform
│   ├── database_factory_desktop.dart
│   └── database_factory_stub.dart
├── models/
│   ├── sapi_model.dart
│   └── pengukuran_model.dart
├── screens/
│   ├── main_screen.dart           # Navigasi 4 tab
│   ├── input_sapi_screen.dart
│   ├── hitung_pakan_screen.dart
│   ├── update_sapi_screen.dart
│   ├── form_update_sapi_screen.dart
│   ├── history_screen.dart
│   ├── history_tanggal_screen.dart
│   └── history_detail_sheet.dart
├── utils/
│   ├── app_theme.dart             # Warna, tema, dan snack bar
│   ├── calculator.dart            # Semua rumus dan asumsi
│   ├── data_rumput.dart           # Daftar jenis rumput + kadar BK
│   └── daftar_poel.dart
└── widgets/
    ├── app_text_field.dart
    ├── app_dropdown.dart
    ├── sapi_picker_field.dart     # Picker sapi + bottom sheet pencarian
    └── status_banner.dart
```

Dependency utama: `flutter`, `sqflite`, `sqflite_common_ffi`, `path`, `intl`, `fl_chart`, `pdf`, dan `printing`.

---

## Pemecahan Masalah

**"databaseFactory not initialized" saat dijalankan di desktop**
Pastikan menjalankan versi kode terbaru. `main()` sudah memanggil `WidgetsFlutterBinding.ensureInitialized()` dan `await initDatabaseFactory()` sebelum `runApp()`.

**Picker sapi kosong / tidak ada sapi**
Isi data terlebih dahulu lewat tab **Input**. Daftar picker dimuat ulang setiap bottom sheet dibuka.

**Sapi dipilih tetapi bobot tidak berubah**
Sapi tersebut belum memiliki pengukuran. Tambahkan pengukuran lewat tab **Update**, lalu pilih ulang sapi di tab **Hitung**.

**Snack bar "Sapi ini belum punya data pengukuran" muncul**
Itu informasi, bukan error. Bobot lama tetap dipakai dan bisa diedit manual.

**Pencarian tidak menemukan sapi**
Pencarian memakai nama sapi (case-insensitive). Coba kata kunci yang lebih pendek.

---

Dibuat dengan Flutter. Semua perhitungan bersifat estimasi dan bukan pengganti pemeriksaan lapangan atau saran nutrisi profesional.
