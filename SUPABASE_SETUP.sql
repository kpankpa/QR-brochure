-- QUICK SETUP: Copy and paste this entire file into Supabase SQL Editor
-- Dashboard: https://supabase.com/dashboard/project/qjaavrisvfiqhqklfebn/sql/new

-- Step 1: Ensure bucket exists and is public
insert into storage.buckets (id, name, public)
values ('QR-bucket', 'QR-bucket', true)
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

-- Step 3: Create new public policies (no Supabase auth required)

-- PUBLIC READ: Anyone can download files (needed for QR codes)
create policy "QR-bucket public read"
on storage.objects for select
using (bucket_id = 'QR-bucket');

-- PUBLIC INSERT: Allow uploads without authentication
create policy "QR-bucket public insert"
on storage.objects for insert
with check (bucket_id = 'QR-bucket');

-- PUBLIC UPDATE: Allow file updates
create policy "QR-bucket public update"
on storage.objects for update
using (bucket_id = 'QR-bucket')
with check (bucket_id = 'QR-bucket');

-- PUBLIC DELETE: Allow file deletion
create policy "QR-bucket public delete"
on storage.objects for delete
using (bucket_id = 'QR-bucket');

-- DONE! Close this tab and test your app.
-- Note: Firebase Auth handles user tracking, Supabase just stores files.
