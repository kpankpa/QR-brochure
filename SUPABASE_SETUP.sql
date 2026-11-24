-- Canonical QR-bucket setup. This file is kept for compatibility; the
-- maintained copy is supabase/storage_setup.sql.
-- The bucket is PRIVATE so expiring signed URLs are the only way to read files.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'QR-bucket',
  'QR-bucket',
  false,
  25 * 1024 * 1024,
  array['application/pdf', 'image/png', 'image/jpeg', 'image/webp', 'image/gif']::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "brochures public read" on storage.objects;
drop policy if exists "brochures insert own folder" on storage.objects;
drop policy if exists "brochures update own folder" on storage.objects;
drop policy if exists "brochures delete own folder" on storage.objects;
drop policy if exists "QR-bucket public read" on storage.objects;
drop policy if exists "QR-bucket insert" on storage.objects;
drop policy if exists "QR-bucket update" on storage.objects;
drop policy if exists "QR-bucket delete" on storage.objects;
drop policy if exists "QR-bucket public insert" on storage.objects;
drop policy if exists "QR-bucket public update" on storage.objects;
drop policy if exists "QR-bucket public delete" on storage.objects;
drop policy if exists "QR-bucket signed select" on storage.objects;
drop policy if exists "QR-bucket insert all" on storage.objects;
drop policy if exists "QR-bucket update all" on storage.objects;
drop policy if exists "QR-bucket delete all" on storage.objects;

create policy "QR-bucket signed select"
on storage.objects for select to public
using (
  bucket_id = 'QR-bucket'
  and storage.allow_only_operation('storage.object.sign')
);

create policy "QR-bucket insert"
on storage.objects for insert to public
with check (
  bucket_id = 'QR-bucket'
  and lower(storage.extension(name)) in ('pdf', 'png', 'jpg', 'jpeg', 'webp', 'gif')
);
