# PadalPro

Flutter mobile app for padel court booking and community play.

## Setup

Install dependencies:

```powershell
flutter pub get
```

Run checks:

```powershell
flutter analyze
flutter test
```

Run on a connected Android emulator/device:

```powershell
flutter devices
flutter run
```

Run with Supabase Cloud:

```powershell
flutter run `
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
```

If no Android emulator is listed, check available emulators and launch one:

```powershell
flutter emulators
flutter emulators --launch YOUR_EMULATOR_ID
flutter devices
```

Do not put Supabase secret/service-role keys in Flutter. The mobile app should
only receive the project URL and publishable/anon key through `--dart-define`.

The current app foundation is focused on Android and iOS. Core booking now uses
Supabase for auth, database, storage, and booking RPCs. Midtrans, community, and
split bill features continue in later phases.

Supabase backend setup lives in `supabase/README.md`.
