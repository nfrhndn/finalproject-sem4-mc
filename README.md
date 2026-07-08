# PadalPro

PadalPro adalah aplikasi mobile berbasis Flutter untuk membantu user melakukan
booking lapangan padel, mencari teman bermain melalui Community open match, dan
mencatat pembayaran patungan atau split bill.

Project ini dibuat sebagai final project mata kuliah **Mobile Computing** dengan
fokus menerapkan materi Flutter, navigation, state management, FutureBuilder,
StreamBuilder, BLoC, local storage, dan integrasi backend Supabase.

## Anggota Tim

| Nama | NIM | Program Studi |
| --- | --- | --- |
| Mohammad Zilan Afiat Suryaditama | 24110300036 | Ilmu Komputer |
| Novendy Farhanudin | 24110300068 | Ilmu Komputer |
| Laily Sulusiyah | 24110500020 | Data Science |

## Latar Belakang

Permasalahan yang diangkat adalah proses booking lapangan padel dan mencari
partner bermain yang masih sering dilakukan secara manual.

PadalPro dibuat untuk membantu user:

- Melihat daftar lapangan padel dan detailnya.
- Mengecek slot waktu yang tersedia.
- Melakukan booking lapangan.
- Upload bukti pembayaran.
- Membuat atau join Community open match.
- Membagi pembayaran match melalui split bill.
- Melihat status booking dan pembayaran.

## Fitur Utama

- **Authentication**: register, login, logout, reset password, dan session
  persistence.
- **Browse Court**: melihat city, featured court, dan detail lapangan.
- **Search**: mencari lapangan/lokasi dan menyimpan recent search.
- **Booking**: memilih tanggal, slot waktu, lalu membuat booking.
- **Payment**: upload bukti pembayaran manual.
- **My Bookings**: melihat daftar dan detail booking.
- **Realtime Booking Detail**: status booking dapat berubah realtime dari
  Supabase.
- **Community Open Match**: membuat match terbuka agar user lain bisa join.
- **Split Bill**: membagi total pembayaran ke setiap participant.
- **Scoreboard**: mencatat skor untuk match yang sudah paid.
- **Profile**: edit profile, upload foto, change password, dan logout.

## Halaman dan Flow

Project memiliki **22 halaman/screen** di `lib/presentation/pages`.

| No | Halaman | Fungsi |
| --- | --- | --- |
| 1 | Splash | Cek session login |
| 2 | Onboarding | Pengenalan aplikasi |
| 3 | Get Started | Akses awal ke login/register |
| 4 | Sign In | Login user |
| 5 | Sign Up | Registrasi user |
| 6 | Reset Password | Reset password |
| 7 | Browse/Home | Halaman utama |
| 8 | Search | Pencarian court/lokasi |
| 9 | City Details | Court berdasarkan kota |
| 10 | Court Details | Detail lapangan |
| 11 | Booking | Pilih tanggal dan slot |
| 12 | Payment | Upload bukti bayar |
| 13 | Success Booking | Booking berhasil |
| 14 | My Bookings | Daftar booking user |
| 15 | Booking Details | Detail dan status booking |
| 16 | Community | Daftar open match |
| 17 | Create Match | Membuat open match |
| 18 | Match Details | Participant dan split bill |
| 19 | Scoreboard | Pencatatan skor |
| 20 | Profile | Data user |
| 21 | Edit Profile | Update profile |
| 22 | Change Password | Ubah password |

Flow booking normal:

```text
Login -> Browse/Home -> Court Details -> Booking
-> Payment -> Upload Proof -> Success Booking -> My Bookings
```

Flow Community open match:

```text
Login -> Community -> Create Match -> Participants Join
-> Booking otomatis saat penuh -> Split Bill -> Paid -> Scoreboard
```

## Arsitektur Project

PadalPro menggunakan pendekatan berlapis agar kode lebih rapi dan mudah
dikembangkan.

```text
UI / Page
  -> BLoC
  -> Domain Repository Interface
  -> Data Repository Implementation
  -> Data Source
  -> Supabase / Local Storage
```

Struktur utama:

- `lib/core`: theme, constants, config, helper, error handling, dependency
  injection, dan storage helper.
- `lib/data`: datasource, model, dan repository implementation.
- `lib/domain`: entity, repository interface, dan use case.
- `lib/presentation`: page, widget, dan BLoC.
- `supabase`: migration SQL, seed data, dan Edge Functions.

BLoC yang digunakan:

- `AuthBloc`
- `CityBloc`
- `CourtBloc`
- `BookingBloc`
- `CommunityBloc`

Contoh setup BLoC di `lib/main.dart`:

```dart
return MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
    ),
    BlocProvider(
      create: (_) => sl<CityBloc>()..add(const CitiesFetchRequested()),
    ),
    BlocProvider(
      create: (_) =>
          sl<CourtBloc>()..add(const FeaturedCourtsFetchRequested()),
    ),
    BlocProvider(create: (_) => sl<BookingBloc>()),
    BlocProvider(create: (_) => sl<CommunityBloc>()),
  ],
  child: MaterialApp(
    title: AppConstants.appName,
    theme: AppTheme.lightTheme,
    home: const AuthSessionSync(child: SplashPage()),
  ),
);
```

## Materi Kuliah yang Diterapkan

| Materi | Implementasi |
| --- | --- |
| Setup Flutter | Project dapat dijalankan di emulator/Chrome |
| Intro Mobile App | Aplikasi memiliki flow end-to-end |
| Native vs Flutter | Menggunakan Flutter untuk mobile app |
| Everything is a Widget | UI dibangun dari widget Flutter |
| Navigation | Menggunakan `Navigator` dan bottom navigation |
| Stateless & Stateful | Dipakai sesuai kebutuhan state halaman |
| FutureBuilder | Recent search di Search Page |
| StreamBuilder | Realtime status di Booking Details |
| BLoC | Auth, City, Court, Booking, dan Community |

Dengan kondisi saat ini, materi utama yang diajarkan sudah diterapkan di dalam
flow aplikasi.

## FutureBuilder dan StreamBuilder

`FutureBuilder` digunakan untuk recent search karena data diambil sekali dari
local storage.

```dart
return FutureBuilder<List<String>>(
  future: _recentSearchesFuture,
  builder: (context, snapshot) {
    final searches = snapshot.data ?? const <String>[];
    if (snapshot.connectionState == ConnectionState.waiting ||
        searches.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildRecentSearches(searches);
  },
);
```

`StreamBuilder` digunakan di Booking Details karena status booking bisa berubah
dari backend, misalnya dari `pending_payment` menjadi `paid`.

```dart
return StreamBuilder<Booking?>(
  stream: _bookingStream,
  initialData: _initialBooking,
  builder: (context, snapshot) {
    final booking = snapshot.data;
    if (booking == null) return _buildLoadingState();
    return _buildBookingDetails(context, booking);
  },
);
```

## Library

| Library | Fungsi |
| --- | --- |
| `flutter_bloc` | State management BLoC |
| `equatable` | Membandingkan state/entity |
| `supabase_flutter` | Auth, database, storage, RPC, realtime |
| `get_it` | Dependency injection |
| `dartz` | Handling success/failure dengan `Either` |
| `flutter_secure_storage` | Menyimpan session/token |
| `shared_preferences` | Data lokal seperti recent search |
| `image_picker` | Upload foto dan bukti pembayaran |
| `cached_network_image` | Cache gambar dari URL |
| `google_fonts` | Font aplikasi |
| `intl` | Format tanggal dan angka |
| `url_launcher` | Membuka phone/link |

## Backend dan Database

Backend menggunakan Supabase untuk:

- Authentication user.
- Database court, booking, payment, community match, participant, dan split bill.
- Storage untuk foto profile dan bukti pembayaran.
- RPC untuk create booking, cek slot, join match, dan split bill.
- Realtime untuk update status booking.
- RLS policy untuk membatasi akses data sesuai user.

Alasan menggunakan Supabase:

- Sudah menyediakan authentication, database PostgreSQL, storage, dan realtime
  dalam satu platform.
- Cocok untuk aplikasi mobile karena Flutter dapat terhubung langsung melalui
  `supabase_flutter`.
- Mendukung Row Level Security (RLS), sehingga akses data bisa dibatasi sesuai
  user yang sedang login.
- Mempercepat pengembangan final project karena backend utama tidak perlu
  dibuat dari nol.

## Rancangan Database / ERD

Database dibagi menjadi empat bagian utama:

- **User dan profile**: `auth_users`, `profiles`.
- **Master lapangan**: `cities`, `court_categories`, `courts`, dan detail court.
- **Booking dan payment**: `bookings`, `payments`.
- **Community match**: `community_matches`, `match_participants`, `split_bills`.

ERD dibuat menggunakan dbdiagram.io berdasarkan migration Supabase.

![ERD PadalPro](assets/images/erd_padalpro.png)

Relasi utama:

| Jenis Relasi | Relasi | Penjelasan |
| --- | --- | --- |
| One-to-one | `auth_users` -> `profiles` | Satu akun memiliki satu profile |
| One-to-many | `cities` -> `courts` | Satu kota memiliki banyak lapangan |
| One-to-many | `courts` -> `bookings` | Satu lapangan memiliki banyak booking |
| One-to-many | `auth_users` -> `bookings` | Satu user dapat membuat banyak booking |
| One-to-many | `bookings` -> `payments` | Satu booking dapat memiliki catatan pembayaran |
| One-to-many | `community_matches` -> `match_participants` | Satu match memiliki banyak participant |
| One-to-many | `community_matches` -> `split_bills` | Satu match menghasilkan banyak split bill |
| Many-to-many | `auth_users` <-> `community_matches` | Satu user bisa ikut banyak match, dan satu match bisa memiliki banyak user |
| Optional one-to-one | `community_matches` -> `bookings` | Match terhubung ke booking setelah penuh |
| Optional one-to-one | `split_bills` -> `payments` | Split bill terhubung ke payment setelah dibayar |

Relasi many-to-many antara user dan Community Match tidak disimpan langsung di
dua tabel tersebut, tetapi melalui tabel penghubung `match_participants`.
Setelah match penuh, pembayaran tiap participant dicatat di tabel `split_bills`.

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

Jalankan app:

```powershell
flutter run -d emulator-5554 `
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
```

Catatan:

- Flutter app hanya memakai Supabase Project URL dan publishable/anon key.
- Jangan memasukkan Supabase service role key ke aplikasi mobile.

## Status

- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
