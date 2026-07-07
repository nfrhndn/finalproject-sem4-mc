# Test Case Flow PadalPro

Dokumen ini dipakai untuk uji manual flow utama PadalPro setelah setup lokal dan
Supabase selesai.

## Prasyarat

- App dijalankan memakai Supabase project yang sama.
- Migration Supabase sudah dijalankan berurutan:
  1. `supabase/migrations/202606260001_initial_core_booking.sql`
  2. `supabase/migrations/202607030001_core_booking_status_and_tax_fixups.sql`
  3. `supabase/migrations/202607060001_community_open_match_split_bill.sql`
  4. `supabase/seed.sql`
- Storage bucket `profile-photos` dan `payment-proofs` sudah tersedia.
- Minimal siapkan 4 akun email/password untuk test Community sampai penuh.

Run app:

```powershell
flutter run -d emulator-5554 --dart-define=SUPABASE_URL="https://gktakajgyygjoysemkgi.supabase.co" --dart-define=SUPABASE_ANON_KEY="sb_publishable_rwk7JjMCWTfYEx3c7Vo5pQ_lZiXEMiN"
```

## TC-01 Register User

Steps:
1. Buka app.
2. Masuk ke Sign Up.
3. Isi name, email, password, dan confirm password.
4. Submit.

Expected:
- Jika email confirmation off, user langsung masuk Home.
- Jika email confirmation on, app memberi pesan untuk cek email.
- User muncul di Supabase `Authentication > Users`.
- Row profile user muncul di tabel `profiles`.

## TC-02 Login User

Steps:
1. Buka Sign In.
2. Masukkan email/password akun yang sudah terdaftar.
3. Tap Sign In.

Expected:
- User berhasil masuk Home.
- Jika password salah, app menampilkan pesan error yang jelas.
- User tidak perlu register ulang selama akun masih ada di Supabase project yang sama.

## TC-03 Browse Home

Steps:
1. Login.
2. Buka Home.
3. Lihat Featured Courts, Browse by City, dan Next Booking jika ada.

Expected:
- Data court/city dari Supabase tampil.
- Tidak ada crash/loading stuck.
- Klik court membuka Court Detail.

## TC-04 Normal Court Booking

Steps:
1. Dari Home, buka salah satu Court Detail.
2. Tap Book Now.
3. Pilih date dan time slot available.
4. Continue sampai Payment Page.
5. Upload bukti pembayaran.
6. Submit payment.

Expected:
- Booking dibuat dengan status `pending_payment`.
- Setelah upload bukti, booking berubah menjadi `paid`.
- Booking muncul di My Bookings.
- Slot booking tidak bisa dipakai double-booking pada jam yang sama.

## TC-05 Guest Opens Community

Steps:
1. Logout.
2. Buka menu Community.

Expected:
- Guest bisa melihat list match.
- Jika tap Create Match, user diminta login.
- Jika tap Join Match, user diminta login.

## TC-06 Create Community Open Match

Steps:
1. Login sebagai User A.
2. Buka Community.
3. Tap Create Match.
4. Pilih court, date, start time, end time, skill level, dan notes.
5. Tap Publish Open Match.

Expected:
- Match berhasil dibuat.
- User A otomatis menjadi host/participant pertama.
- Status match `open`.
- Participant count `1/4`.
- Match muncul di Community list.

Supabase checks:
- Row baru di `community_matches`.
- Row host di `match_participants`.
- Belum ada booking di `bookings`.
- Belum ada split bill di `split_bills`.

## TC-07 Join Match Until Full

Steps:
1. Login sebagai User B.
2. Buka Community, pilih match User A.
3. Tap Join Match.
4. Logout, ulangi dengan User C dan User D.

Expected:
- Setelah User B join: count `2/4`.
- Setelah User C join: count `3/4`.
- Setelah User D join: count `4/4`.
- Saat penuh, sistem membuat booking otomatis jika slot masih available.
- Match berubah ke `pending_payment`.
- Split bill muncul untuk 4 participant.

Supabase checks:
- `community_matches.booking_id` terisi.
- Row booking status `pending_payment`.
- 4 row `split_bills` status `pending`.
- Amount split bill dibagi dari `bookings.grand_total`.

## TC-08 Pay Split Bill

Steps:
1. Login sebagai User A/B/C/D.
2. Buka Match Detail.
3. Tap Pay Your Share.
4. Pilih gambar bukti bayar.
5. Submit.
6. Ulangi untuk semua participant.

Expected:
- Setelah satu user bayar, bill user tersebut menjadi `paid`.
- Bill user lain tetap `pending`.
- Setelah semua bill `paid`, match berubah menjadi `paid`.
- Booking terkait berubah menjadi `paid`.

Supabase checks:
- `split_bills.proof_path` terisi.
- Row payment provider `manual_split` dibuat.
- `community_matches.status = paid`.
- `bookings.status = paid`.

## TC-09 Open Scoreboard From Paid Match

Steps:
1. Pastikan match sudah `paid`.
2. Buka Match Detail.
3. Tap Open Scoreboard.

Expected:
- Scoreboard terbuka dari Match Detail.
- Scoreboard tidak muncul sebagai menu utama bottom navigation.

## TC-10 Slot Taken Before Match Full

Steps:
1. User A create open match untuk court/date/time tertentu.
2. Sebelum match penuh, user lain membuat normal booking pada slot yang sama.
3. Lanjutkan join Community match sampai 4 players.

Expected:
- Saat Community match penuh, booking otomatis gagal karena slot sudah dipakai.
- Match berubah ke `needs_reschedule`.
- Split bill tidak dibuat.
- User melihat state reschedule/error yang jelas.

## TC-11 Pending Booking Expired

Steps:
1. Buat Community match sampai penuh.
2. Biarkan booking `pending_payment` melewati waktu expiry.
3. Trigger refresh dengan membuka Community/Booking atau menjalankan RPC expiry.

Expected:
- Booking berubah menjadi `expired`.
- Match berubah menjadi `expired`.
- Split bills pending berubah menjadi `expired`.

## TC-12 Logout/Login Persistence

Steps:
1. Login dengan akun email/password.
2. Tutup app.
3. Buka app lagi.
4. Logout.
5. Login lagi dengan akun yang sama.

Expected:
- Session tetap dikenali saat app dibuka lagi jika belum logout.
- Setelah logout, user bisa login ulang dengan akun yang sama.
- Data profile tetap sama dari Supabase.

## Catatan

- Untuk test Community sampai paid, paling mudah pakai 4 akun email/password berbeda dan logout-login bergantian di emulator yang sama.
- Kalau Community menampilkan RPC not found, migration `202607060001_community_open_match_split_bill.sql` belum dijalankan di Supabase project yang sedang dipakai app.
