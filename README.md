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
flutter run -d android
```

Run with Supabase Cloud:

```powershell
flutter run -d android `
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
```

The current app foundation is focused on Android and iOS. Supabase core integration is scaffolded; Midtrans, community, and split bill features continue in later phases.

Supabase backend setup lives in `supabase/README.md`.
