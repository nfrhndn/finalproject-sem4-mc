# PadalPro Supabase Setup

This folder contains the backend foundation for Supabase Cloud.

## 1. Create Supabase Project

Create a free Supabase Cloud project, then copy:

- Project URL
- Publishable/anon key

Use them from Flutter with dart defines:

```powershell
flutter run -d android `
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" `
  --dart-define=SUPABASE_ANON_KEY="YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
```

## 2. Run Database SQL

Open Supabase SQL Editor and run:

1. `supabase/migrations/202606260001_initial_core_booking.sql`
2. `supabase/seed.sql`

The migration creates core booking tables, RLS policies, profile triggers, storage buckets, and booking RPCs.

## 3. Configure Auth

Enable Email/Password in Supabase Auth.

For Google SSO:

- Enable Google provider in Supabase Auth.
- Add this redirect URL in Supabase Auth URL configuration:

```text
com.padalpro.app://login-callback/
```

Android and iOS are already configured to receive that callback.

## 4. Midtrans Later

Deploy Edge Functions after core booking works:

```powershell
supabase functions deploy create-midtrans-transaction
supabase functions deploy midtrans-webhook
```

Set secrets in Supabase:

```powershell
supabase secrets set MIDTRANS_SERVER_KEY="YOUR_MIDTRANS_SERVER_KEY"
supabase secrets set MIDTRANS_BASE_URL="https://app.sandbox.midtrans.com/snap/v1/transactions"
```

The Midtrans Server Key must never be placed in Flutter.
