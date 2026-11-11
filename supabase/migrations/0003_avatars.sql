-- 0003 · Foto de perfil (S2-11)
-- Bucket público `avatars`: cualquiera puede ver la foto por su URL; solo la
-- dueña puede subir, cambiar o borrar archivos de su carpeta `{auth.uid()}/`.
-- Límite de 2 MB y solo JPG, PNG o WebP, también del lado del servidor.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- La lectura pública por URL no necesita política; esta solo deja a cada
-- usuaria ver (y por tanto reemplazar o borrar) lo de su propia carpeta, sin
-- permitir listar las fotos de las demás.
create policy "avatares: cada quien ve su carpeta"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatares: cada quien sube a su carpeta"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatares: cada quien cambia lo suyo"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatares: cada quien borra lo suyo"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
