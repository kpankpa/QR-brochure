-- Supabase Storage policies for bucket "QR-bucket" (matches your dashboard).
-- Run in: Supabase → SQL Editor → New query → Run
--
-- Prereqs:
-- 1) Bucket "QR-bucket" already exists (Storage UI).
-- 2) Authentication → Providers → Anonymous → ON.

insert into storage.buckets (id, name, public)
values ('QR-bucket', 'QR-bucket', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "brochures public read" on storage.objects;
drop policy if exists "brochures insert own folder" on storage.objects;
drop policy if exists "brochures update own folder" on storage.objects;
drop policy if exists "brochures delete own folder" on storage.objects;
drop policy if exists "QR-bucket public read" on storage.objects;
drop policy if exists "QR-bucket insert own folder" on storage.objects;
drop policy if exists "QR-bucket update own folder" on storage.objects;
drop policy if exists "QR-bucket delete own folder" on storage.objects;

create policy "QR-bucket public read"
on storage.objects for select
using (bucket_id = 'QR-bucket');

create policy "QR-bucket insert own folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'QR-bucket'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "QR-bucket update own folder"
on storage.objects for update to authenticated
using (
  bucket_id = 'QR-bucket'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'QR-bucket'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "QR-bucket delete own folder"
on storage.objects for delete to authenticated
using (
  bucket_id = 'QR-bucket'
  and (storage.foldername(name))[1] = auth.uid()::text
);
