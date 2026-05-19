-- Run in Supabase → SQL Editor after creating project.
-- Default bucket name matches kSupabaseStorageBucket ("brochures") unless you override
-- with --dart-define=SUPABASE_STORAGE_BUCKET=other_bucket

insert into storage.buckets (id, name, public)
values ('brochures', 'brochures', true)
on conflict (id) do update set public = excluded.public;

-- Public read (QR scanners need HTTPS URL without Supabase login).
create policy "brochures public read"
on storage.objects for select
using (bucket_id = 'brochures');

-- Authenticated users (including anonymous) upload only under folder {their_auth_uid}/...
create policy "brochures insert own folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'brochures'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "brochures update own folder"
on storage.objects for update to authenticated
using (
  bucket_id = 'brochures'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'brochures'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "brochures delete own folder"
on storage.objects for delete to authenticated
using (
  bucket_id = 'brochures'
  and (storage.foldername(name))[1] = auth.uid()::text
);
