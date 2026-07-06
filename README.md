# PadalPro

Aplikasi mobile Flutter untuk booking lapangan padel, Community open match,
dan tracking split bill manual.

## Setup Lokal

Install dependency:

```powershell
flutter pub get
```

Jalankan pengecekan:

```powershell
flutter analyze
flutter test
```

Jalankan app di emulator/device Android:

```powershell
flutter devices
flutter run -d emulator-5554 `
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
```

Jika emulator belum terdeteksi:

```powershell
flutter emulators
flutter emulators --launch YOUR_EMULATOR_ID
flutter devices
```

Untuk testing kelompok, gunakan Supabase project yang sama agar data akun,
booking, Community match, dan split bill terkumpul di satu backend. Teman tim
cukup memakai Project URL dan publishable/anon key dari pemilik project.

Jangan memasukkan Supabase secret key atau service-role key ke Flutter. Aplikasi
mobile hanya boleh menerima Project URL dan publishable/anon key melalui
`--dart-define`.

## Testing Tim

Urutan testing yang disarankan:

- Register/login memakai email dan password.
- Browse court dan buat booking normal.
- Buka Community dan buat open match.
- Gunakan 4 akun test untuk join ke match yang sama sampai penuh.
- Upload bukti bayar split bill untuk setiap participant.
- Buka Scoreboard dari Community match yang sudah paid.

Test case manual tersedia di `TEST_CASE_FLOW_PADALPRO.md`.

## Backend

Supabase digunakan untuk auth, database, storage, booking RPC, Community open
match, dan manual split bill tracking. Panduan setup backend tersedia di
`supabase/README.md`.
