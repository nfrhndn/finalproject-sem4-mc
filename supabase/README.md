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

Open Supabase SQL Editor and run every file in `supabase/migrations` in
timestamp order, then run the seed file:

1. `supabase/migrations/202606260001_initial_core_booking.sql`
2. `supabase/migrations/202607030001_core_booking_status_and_tax_fixups.sql`
3. `supabase/migrations/202607060001_community_open_match_split_bill.sql`
4. `supabase/seed.sql`

The migrations create core booking tables, RLS policies, profile triggers,
storage buckets, booking RPCs, expired booking cleanup, tax calculation,
community open matches, and manual split bill RPCs.

If the app shows `PGRST202` or says a Community RPC cannot be found, the latest
migration has not been applied to the Supabase project yet, or the API schema
cache has not refreshed. Wait briefly, then restart the app.

## 3. Configure Auth

Enable Email/Password in Supabase Auth. In Auth URL Configuration, add this
mobile redirect URL for email confirmation callbacks:

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
