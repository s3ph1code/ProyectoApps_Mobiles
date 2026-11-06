-- Doulapp — esquema Postgres para Supabase
--
-- La identidad la gestiona Supabase Auth (esquema auth). Aquí no existen
-- tablas de contraseñas ni de identidades de proveedor: profiles cuelga
-- de auth.users y comparte su id.
--
-- Este archivo es la referencia completa del modelo. Para crear la base se
-- aplican las migraciones de supabase/migrations en orden (0001, 0002, ...):
-- cada una incluye sus tablas y su seguridad a nivel de fila. Los bloques de
-- comunidad y notificaciones se aplicarán en la 0003.

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


-- =====================================================================
-- MULTIMEDIA  (compartido por comunidad y microdescansos)
-- =====================================================================

create table public.media_assets (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid        not null references public.profiles (id) on delete cascade,
  storage_key text        not null unique,
  media_type  varchar(10) not null check (media_type in ('image','audio','video')),
  mime_type   varchar(100) not null,
  size_bytes  bigint      not null,
  created_at  timestamptz not null default now()
);

create index on public.media_assets (owner_id);


-- =====================================================================
-- MICRODESCANSOS
-- =====================================================================

create table public.activity_categories (
  id        uuid primary key default gen_random_uuid(),
  name      varchar(60) not null unique,
  slug      varchar(70) not null unique,
  is_active boolean     not null default true
);

create table public.activities (
  id               uuid primary key default gen_random_uuid(),
  category_id      uuid        not null references public.activity_categories (id) on delete restrict,
  title            varchar(120) not null,
  description      text        not null,
  modality         varchar(15) not null check (modality in ('read','listen','watch','do')),
  duration_minutes smallint    not null check (duration_minutes > 0),
  content_text     text,
  media_id         uuid references public.media_assets (id) on delete set null,
  external_url     text,
  is_published     boolean     not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index on public.activities (category_id);
create index on public.activities (duration_minutes) where is_published;

create table public.saved_activities (
  user_id     uuid not null references public.profiles (id)   on delete cascade,
  activity_id uuid not null references public.activities (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, activity_id)
);

create table public.activity_sessions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid        not null references public.profiles (id)   on delete cascade,
  activity_id      uuid        not null references public.activities (id) on delete cascade,
  started_at       timestamptz not null default now(),
  completed_at     timestamptz,
  status           varchar(20) not null default 'in_progress'
                   check (status in ('in_progress','completed','abandoned')),
  elapsed_seconds  integer check (elapsed_seconds >= 0)
);

create index on public.activity_sessions (user_id, started_at desc);


-- =====================================================================
-- COMUNIDAD
-- =====================================================================

create table public.community_categories (
  id        uuid primary key default gen_random_uuid(),
  name      varchar(60) not null unique,
  slug      varchar(70) not null unique,
  is_active boolean     not null default true
);

create table public.posts (
  id         uuid primary key default gen_random_uuid(),
  author_id  uuid        not null references public.profiles (id) on delete cascade,
  post_type  varchar(20) not null check (post_type in ('experience','question','message')),
  body       text        not null,
  visibility varchar(20) not null default 'community' check (visibility in ('public','community')),
  status     varchar(20) not null default 'published' check (status in ('published','hidden','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index on public.posts (author_id);
create index on public.posts (created_at desc) where status = 'published';

create table public.post_categories (
  post_id     uuid not null references public.posts (id)                on delete cascade,
  category_id uuid not null references public.community_categories (id) on delete cascade,
  primary key (post_id, category_id)
);

create table public.comments (
  id                uuid primary key default gen_random_uuid(),
  post_id           uuid        not null references public.posts (id)    on delete cascade,
  author_id         uuid        not null references public.profiles (id) on delete cascade,
  parent_comment_id uuid references public.comments (id) on delete cascade,
  body              text        not null,
  status            varchar(20) not null default 'published'
                    check (status in ('published','hidden','removed')),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index on public.comments (post_id, created_at);

create table public.reactions (
  user_id       uuid not null references public.profiles (id) on delete cascade,
  post_id       uuid not null references public.posts (id)    on delete cascade,
  reaction_type varchar(20) not null check (reaction_type in ('support','thanks','same')),
  created_at    timestamptz not null default now(),
  primary key (user_id, post_id)
);

create table public.saved_posts (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  post_id    uuid not null references public.posts (id)    on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

create table public.user_topic_follows (
  user_id     uuid not null references public.profiles (id)             on delete cascade,
  category_id uuid not null references public.community_categories (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, category_id)
);

create table public.post_shares (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid        not null references public.posts (id)    on delete cascade,
  shared_by  uuid        not null references public.profiles (id) on delete cascade,
  channel    varchar(20) not null check (channel in ('link','whatsapp','other')),
  created_at timestamptz not null default now()
);

create table public.user_blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint no_autobloqueo check (blocker_id <> blocked_id)
);

create table public.post_media (
  post_id  uuid not null references public.posts (id)        on delete cascade,
  media_id uuid not null references public.media_assets (id) on delete cascade,
  position smallint not null default 0,
  caption  varchar(250),
  primary key (post_id, media_id)
);

create table public.content_reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid        not null references public.profiles (id) on delete cascade,
  post_id     uuid references public.posts (id)    on delete cascade,
  comment_id  uuid references public.comments (id) on delete cascade,
  reason_code varchar(30) not null
              check (reason_code in ('spam','harassment','misinformation','inappropriate','other')),
  details     text,
  status      varchar(20) not null default 'pending'
              check (status in ('pending','reviewing','resolved','dismissed')),
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  created_at  timestamptz not null default now(),
  -- Un reporte apunta a una publicación o a un comentario, nunca a ambos
  constraint objetivo_unico check (num_nonnulls(post_id, comment_id) = 1)
);

create index on public.content_reports (status, created_at);


-- =====================================================================
-- BIENESTAR
-- =====================================================================

create table public.mood_checkins (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid        not null references public.profiles (id) on delete cascade,
  mood_score  smallint    not null check (mood_score between 1 and 5),
  note        varchar(500),
  recorded_at timestamptz not null default now()
);

create index on public.mood_checkins (user_id, recorded_at desc);

create table public.need_options (
  id        uuid primary key default gen_random_uuid(),
  code      varchar(40)  not null unique,
  label     varchar(100) not null,
  is_active boolean      not null default true
);

create table public.need_sessions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid        not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.need_session_options (
  need_session_id uuid not null references public.need_sessions (id) on delete cascade,
  need_option_id  uuid not null references public.need_options (id)  on delete cascade,
  primary key (need_session_id, need_option_id)
);

-- La lógica de recomendación vive aquí, como datos y no como código
create table public.need_recommendations (
  id               uuid primary key default gen_random_uuid(),
  need_option_id   uuid        not null references public.need_options (id) on delete cascade,
  activity_id      uuid references public.activities (id) on delete set null,
  destination_code varchar(20) check (destination_code in ('activities','community','mood_checkin')),
  message          varchar(240) not null,
  priority         smallint     not null default 10
);

create index on public.need_recommendations (need_option_id, priority);


-- =====================================================================
-- NOTIFICACIONES
-- =====================================================================

create table public.notifications (
  id                uuid primary key default gen_random_uuid(),
  recipient_id      uuid        not null references public.profiles (id) on delete cascade,
  actor_id          uuid references public.profiles (id) on delete set null,
  notification_type varchar(30) not null
                    check (notification_type in ('comment','reaction','reply','system','reminder')),
  post_id           uuid references public.posts (id)    on delete cascade,
  comment_id        uuid references public.comments (id) on delete cascade,
  title             varchar(120) not null,
  body              varchar(300) not null,
  is_read           boolean      not null default false,
  created_at        timestamptz  not null default now(),
  read_at           timestamptz
);

create index on public.notifications (recipient_id, created_at desc) where not is_read;
