-- QUICK SETUP: Copy and paste this entire file into Supabase SQL Editor
-- Dashboard: https://supabase.com/dashboard/project/qjaavrisvfiqhqklfebn/sql/new
-- This config enables expiring signed URLs (private bucket behavior).

-- Step 1: Ensure bucket exists and is private
insert into storage.buckets (id, name, public)
values ('QR-bucket', 'QR-bucket', false)
on conflict (id) do update set public = excluded.public;

-- Step 2: Drop any existing policies to start fresh
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

-- Step 3: Create policies for signed URL workflow

-- SELECT policy is required so the client can create signed URLs.
-- Bucket remains private, so scanners need a signed URL to download.
create policy "QR-bucket signed select"
on storage.objects for select
using (bucket_id = 'QR-bucket');

-- Allow uploads/updates/deletes from client app.
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

-- DONE! Close this tab and test your app.
-- Note: Firebase Auth tracks ownership in Firestore; Supabase serves expiring signed links.
