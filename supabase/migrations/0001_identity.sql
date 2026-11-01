-- Doulapp — esquema Postgres para Supabase
--
-- La identidad la gestiona Supabase Auth (esquema auth). Aquí no existen
-- tablas de contraseñas ni de identidades de proveedor: profiles cuelga
-- de auth.users y comparte su id.
--
-- Orden: ejecutar el bloque IDENTIDAD completo. El resto de bloques solo
-- cuando su módulo entre en alcance.

-- =====================================================================
-- IDENTIDAD
-- =====================================================================

create table public.roles (
  id    smallint primary key,
  code  varchar(30) not null unique check (code in ('user','moderator','admin')),
  name  varchar(60) not null
);

insert into public.roles (id, code, name) values
  (1, 'user',      'Usuaria'),
  (2, 'moderator', 'Moderadora'),
  (3, 'admin',     'Administradora');

create table public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  display_name   varchar(100) not null,
  avatar_url     text,
  bio            varchar(280),
  account_status varchar(20)  not null default 'active'
                 check (account_status in ('active','suspended','deactivated')),
  created_at     timestamptz  not null default now(),
  updated_at     timestamptz  not null default now(),
  deleted_at     timestamptz
);

create table public.user_preferences (
  user_id             uuid primary key references public.profiles (id) on delete cascade,
  profile_visibility  varchar(20) not null default 'community'
                      check (profile_visibility in ('public','community','private')),
  allow_notifications boolean     not null default true,
  wellbeing_reminders boolean     not null default true,
  language_code       varchar(10) not null default 'es',
  updated_at          timestamptz not null default now()
);

create table public.user_roles (
  user_id     uuid     not null references public.profiles (id) on delete cascade,
  role_id     smallint not null references public.roles (id)    on delete restrict,
  assigned_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

-- Crear el perfil en cuanto Supabase registra al usuario, para que nunca
-- exista una cuenta autenticada sin perfil.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  );
  insert into public.user_preferences (user_id) values (new.id);
  insert into public.user_roles (user_id, role_id) values (new.id, 1);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Mantener updated_at al día
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Seguridad a nivel de fila
alter table public.profiles         enable row level security;
alter table public.user_preferences enable row level security;
alter table public.user_roles       enable row level security;

-- La consulta de visibilidad va en una función security definer: si se
-- hiciera en línea, el propio RLS de user_preferences ocultaría las filas
-- ajenas y ningún perfil de otra usuaria sería visible nunca.
create or replace function public.profile_is_visible(p_id uuid)
returns boolean
language sql security definer stable set search_path = public
as $$
  select p_id = auth.uid()
      or exists (
        select 1 from public.user_preferences up
        where up.user_id = p_id and up.profile_visibility <> 'private'
      );
$$;

create policy "perfiles visibles segun preferencia"
  on public.profiles for select
  using (deleted_at is null and public.profile_is_visible(id));

create policy "cada quien edita su perfil"
  on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

create policy "cada quien lee sus preferencias"
  on public.user_preferences for select using (user_id = auth.uid());

create policy "cada quien edita sus preferencias"
  on public.user_preferences for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "cada quien lee sus roles"
  on public.user_roles for select using (user_id = auth.uid());

