-- Run in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/qjaavrisvfiqhqklfebn/sql/new
--
-- Creates a PUBLIC bucket for digital card photos and logos. Unlike brochure
-- files, these images must stay readable forever from the public /c/{slug} page.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'card-assets',
  'card-assets',
  true,
  5 * 1024 * 1024,
  array['image/png', 'image/jpeg', 'image/webp', 'image/gif']::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Drop older policies so this script is safe to re-run.
drop policy if exists "card-assets public read" on storage.objects;
drop policy if exists "card-assets insert" on storage.objects;
drop policy if exists "card-assets update" on storage.objects;
drop policy if exists "card-assets delete" on storage.objects;

create policy "card-assets public read"
on storage.objects for select
using (bucket_id = 'card-assets');

-- Upload paths are unique and include the signed-in Firebase uid. The app does
-- not call upsert, so an existing object cannot be replaced by another upload.
-- Public UPDATE/DELETE policies are intentionally absent: an anonymous client
-- holding the publishable key must not be able to overwrite or remove images.
create policy "card-assets insert"
on storage.objects for insert to public
with check (
  bucket_id = 'card-assets'
  and lower(storage.extension(name)) in ('png', 'jpg', 'jpeg', 'webp', 'gif')
);

-- Done. The Flutter app uploads to `uid/profile/{timestamp}.{ext}` and
-- `uid/logo/{timestamp}.{ext}` and stores the returned public URLs in Firestore.
