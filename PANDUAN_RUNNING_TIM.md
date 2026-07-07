# Panduan Running PadalPro untuk Tim

Panduan ini dipakai untuk teman tim yang ingin clone project dari awal lalu
menjalankan aplikasi PadalPro. Ada dua pilihan:

- Android emulator, kalau laptop kuat.
- Browser Chrome, kalau emulator terasa berat.

Jalankan semua command dari folder root project `finalproject-sem4-mc`, bukan
dari folder `mobile/`.

## 1. Install Tools

Pastikan sudah install:

- Git
- Flutter SDK
- Android Studio
- Android Emulator dari Android Studio
- Google Chrome
- VS Code atau Android Studio untuk editor

Cek instalasi Flutter:

```powershell
flutter doctor
```

Kalau ada error di bagian Android toolchain atau emulator, selesaikan dulu dari
instruksi `flutter doctor`.

## 2. Clone Repository

Clone repository project:

```powershell
git clo ne URL_REPOSITORY_PADALPRO
cd finalproject-sem4-mc
```

Ganti `URL_REPOSITORY_PADALPRO` dengan URL repository GitHub/GitLab yang
dibagikan oleh pemilik project.

Contoh:

```powershell
git clone https://github.com/USERNAME/finalproject-sem4-mc.git
cd finalproject-sem4-mc
```

## 3. Install Dependency Flutter

Jalankan:

```powershell
flutter pub get
```

## 4. Pilihan A: Jalankan di Android Emulator

Pakai cara ini kalau laptop kuat menjalankan emulator.

Cek daftar emulator:

```powershell
flutter emulators
```

Nyalakan emulator dari Android Studio atau lewat terminal:

```powershell
flutter emulators --launch NAMA_EMULATOR
```

Setelah emulator menyala, cek device:

```powershell
flutter devices
```

Biasanya emulator Android muncul seperti ini:

```text
emulator-5554
```

Jalankan command ini dari folder project:

```powershell
flutter run -d emulator-5554 --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

Kalau nama device berbeda, ganti `emulator-5554` sesuai hasil dari:

```powershell
flutter devices
```

Contoh kalau device bernama `android`:

```powershell
flutter run -d android --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

## 5. Pilihan B: Jalankan di Browser Chrome

Pakai cara ini kalau emulator terlalu berat. Flutter akan membuka aplikasi di
Chrome lewat alamat `localhost`.

Cek apakah Chrome terdeteksi:

```powershell
flutter devices
```

Pastikan ada device seperti ini:

```text
Chrome (web)
```

Kalau Chrome belum muncul, aktifkan web support:

```powershell
flutter config --enable-web
flutter devices
```

Jalankan aplikasi di Chrome:

```powershell
flutter run -d chrome --web-port 8080 --no-web-resources-cdn --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

Nanti browser akan membuka alamat seperti:

```text
http://localhost:8080
```

Kalau port `8080` sedang dipakai, ganti ke port lain:

```powershell
flutter run -d chrome --web-port 8081 --no-web-resources-cdn --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

Catatan untuk mode browser:

- Tidak perlu Android emulator.
- Tetap memakai Supabase project yang sama.
- Upload foto/bukti bayar bisa memakai file dari komputer.
- Fitur yang sangat spesifik mobile bisa terasa sedikit berbeda di browser.

## 6. Pilih Cara Mana?

Untuk teman yang laptopnya berat, rekomendasinya pakai Chrome:

```powershell
flutter run -d chrome --web-port 8080 --no-web-resources-cdn --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

Untuk teman yang mau testing rasa mobile Android, pakai emulator:

```powershell
flutter run -d emulator-5554 --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

## 7. Akun dan Data Testing

Untuk testing, setiap anggota boleh register akun sendiri lewat aplikasi.
Semua akun, booking, community match, dan split bill akan masuk ke Supabase
project yang sama.

Testing flow yang disarankan:

1. Register akun baru.
2. Login.
3. Browse court.
4. Buat booking.
5. Buka Community.
6. Buat open match.
7. Minta anggota lain join match yang sama.
8. Upload bukti bayar split bill.
9. Cek scoreboard setelah match paid.

Detail test case ada di `TEST_CASE_FLOW_PADALPRO.md`.

## 8. Catatan Penting Supabase

Project ini memakai Supabase milik pemilik project. Teman tim tidak perlu
membuat Supabase sendiri untuk menjalankan aplikasi.

Yang boleh dibagikan untuk menjalankan app:

- Supabase Project URL
- Supabase publishable/anon key

Yang tidak boleh dibagikan atau dimasukkan ke Flutter:

- Supabase service role key
- Database password
- Midtrans server key
- Secret lain dari Supabase

## 9. Troubleshooting

Jika muncul pesan:

```text
Supabase config is missing
```

Artinya command run belum memakai `--dart-define=SUPABASE_URL=...` dan
`--dart-define=SUPABASE_ANON_KEY=...`.

Jika emulator tidak muncul:

```powershell
flutter devices
flutter emulators
```

Lalu nyalakan emulator dari Android Studio.

Jika Chrome tidak muncul:

```powershell
flutter config --enable-web
flutter devices
```

Jika aplikasi web tidak terbuka otomatis, buka manual:

```text
http://localhost:8080
```

Jika halaman Chrome putih kosong:

1. Stop server Flutter di terminal dengan `q`.
2. Tutup tab Chrome localhost.
3. Jalankan:

```powershell
flutter clean
flutter pub get
```

4. Jalankan ulang dengan command Chrome yang memakai `--no-web-resources-cdn`:

```powershell
flutter run -d chrome --web-port 8080 --no-web-resources-cdn --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

5. Kalau masih putih, tekan `Ctrl + Shift + R` di Chrome untuk hard refresh.

Jika dependency error:

```powershell
flutter clean
flutter pub get
```

Lalu jalankan ulang command `flutter run`.
