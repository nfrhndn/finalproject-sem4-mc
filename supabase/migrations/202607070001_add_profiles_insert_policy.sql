-- Migration: Add profiles insert policy
-- Description: Allows authenticated users to insert/upsert their own profile row.
-- This fixes the registration error where upsert fails due to missing INSERT policy.

create policy "Users can insert own profile" on public.profiles
for insert with check (auth.uid() = id);
