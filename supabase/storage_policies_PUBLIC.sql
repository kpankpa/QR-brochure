-- Supabase Storage Policies - Signed URL (private bucket)
-- Firebase Auth handles user tracking in Firestore
-- Run in: Supabase → SQL Editor → New query → Run

-- Ensure bucket exists and is private
insert into storage.buckets (id, name, public)
values ('QR-bucket', 'QR-bucket', false)
on conflict (id) do update set public = excluded.public;

-- Drop all existing policies
drop policy if exists "brochures public read" on storage.objects;
drop policy if exists "brochures insert own folder" on storage.objects;
drop policy if exists "brochures update own folder" on storage.objects;
drop policy if exists "brochures delete own folder" on storage.objects;
drop policy if exists "QR-bucket public read" on storage.objects;
drop policy if exists "QR-bucket insert own folder" on storage.objects;
drop policy if exists "QR-bucket update own folder" on storage.objects;
drop policy if exists "QR-bucket delete own folder" on storage.objects;
drop policy if exists "QR-bucket signed select" on storage.objects;
drop policy if exists "QR-bucket insert all" on storage.objects;
drop policy if exists "QR-bucket update all" on storage.objects;
drop policy if exists "QR-bucket delete all" on storage.objects;

-- Select needed for createSignedUrl API.
create policy "QR-bucket signed select"
on storage.objects for select
using (bucket_id = 'QR-bucket');

create policy "QR-bucket insert all"
on storage.objects for insert
with check (bucket_id = 'QR-bucket');

create policy "QR-bucket update all"
on storage.objects for update
using (bucket_id = 'QR-bucket')
with check (bucket_id = 'QR-bucket');

create policy "QR-bucket delete all"
on storage.objects for delete
using (bucket_id = 'QR-bucket');

-- IMPORTANT: For stricter production controls, add API-layer validation/rate limiting.
