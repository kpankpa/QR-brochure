-- Supabase Storage Policies - Public Upload (No Supabase Auth Required)
-- Firebase Auth handles user authentication
-- Run in: Supabase → SQL Editor → New query → Run

-- Ensure bucket exists and is public
insert into storage.buckets (id, name, public)
values ('QR-bucket', 'QR-bucket', true)
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

-- PUBLIC READ: Anyone can read/download files (needed for QR codes)
create policy "QR-bucket public read"
on storage.objects for select
using (bucket_id = 'QR-bucket');

-- PUBLIC UPLOAD: Allow uploads without authentication
-- Note: This is simplified for demo. For production, use row-level security
-- or switch to Firebase Storage.
create policy "QR-bucket public insert"
on storage.objects for insert
with check (bucket_id = 'QR-bucket');

create policy "QR-bucket public update"
on storage.objects for update
using (bucket_id = 'QR-bucket')
with check (bucket_id = 'QR-bucket');

create policy "QR-bucket public delete"
on storage.objects for delete
using (bucket_id = 'QR-bucket');

-- IMPORTANT: For production, restrict uploads by implementing:
-- 1. Server-side validation with Firebase Cloud Functions
-- 2. Or switch to Firebase Storage with proper security rules
-- 3. Or use API keys + rate limiting in Supabase
