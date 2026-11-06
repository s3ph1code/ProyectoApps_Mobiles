-- Doulapp — migración 0002: microdescansos y bienestar emocional
--
-- Requiere 0001_identity.sql aplicada. Crea las tablas de multimedia,
-- microdescansos y bienestar (idénticas a las de schema.sql) y les agrega
-- seguridad a nivel de fila. Comunidad y notificaciones llegan en la 0003.
--
-- Criterio general:
--   * Catálogos (categorías, actividades, necesidades, recomendaciones):
--     lectura para cualquier usuaria autenticada, solo lo activo/publicado;
--     escritura únicamente para moderadora y administradora.
--   * Datos personales (check-ins, sesiones, guardados): cada usuaria ve y
--     crea solo lo suyo.

-- Funciones auxiliares ------------------------------------------------
-- security definer para que consultar user_roles desde una política no
-- dispare el RLS de user_roles (que solo deja ver las filas propias).
create or replace function public.has_role(p_code text)
returns boolean
language sql security definer stable set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid() and r.code = p_code
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql security definer stable set search_path = public
as $$
  select public.has_role('moderator') or public.has_role('admin');
$$;

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



create trigger activities_touch
  before update on public.activities
  for each row execute function public.touch_updated_at();

-- Seguridad a nivel de fila -------------------------------------------
alter table public.media_assets         enable row level security;
alter table public.activity_categories  enable row level security;
alter table public.activities           enable row level security;
alter table public.saved_activities     enable row level security;
alter table public.activity_sessions    enable row level security;
alter table public.mood_checkins        enable row level security;
alter table public.need_options         enable row level security;
alter table public.need_sessions        enable row level security;
alter table public.need_session_options enable row level security;
alter table public.need_recommendations enable row level security;

-- Multimedia
create policy "multimedia visible para usuarias autenticadas"
  on public.media_assets for select to authenticated using (true);
create policy "cada quien sube su multimedia"
  on public.media_assets for insert to authenticated with check (owner_id = auth.uid());
create policy "cada quien borra su multimedia"
  on public.media_assets for delete to authenticated using (owner_id = auth.uid());

-- Catálogos de microdescansos
create policy "categorias activas visibles"
  on public.activity_categories for select to authenticated
  using (is_active or public.is_staff());
create policy "staff gestiona categorias"
  on public.activity_categories for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

create policy "actividades publicadas visibles"
  on public.activities for select to authenticated
  using (is_published or public.is_staff());
create policy "staff gestiona actividades"
  on public.activities for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- Actividades guardadas y sesiones (datos propios)
create policy "cada quien lee sus actividades guardadas"
  on public.saved_activities for select to authenticated using (user_id = auth.uid());
create policy "cada quien guarda actividades"
  on public.saved_activities for insert to authenticated with check (user_id = auth.uid());
create policy "cada quien quita sus guardadas"
  on public.saved_activities for delete to authenticated using (user_id = auth.uid());

create policy "cada quien lee sus sesiones de actividad"
  on public.activity_sessions for select to authenticated using (user_id = auth.uid());
create policy "cada quien inicia sus sesiones de actividad"
  on public.activity_sessions for insert to authenticated with check (user_id = auth.uid());
create policy "cada quien actualiza sus sesiones de actividad"
  on public.activity_sessions for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Bienestar: check-ins (solo se crean y se leen; no se editan)
create policy "cada quien lee sus check-ins"
  on public.mood_checkins for select to authenticated using (user_id = auth.uid());
create policy "cada quien registra sus check-ins"
  on public.mood_checkins for insert to authenticated with check (user_id = auth.uid());

-- «No sé qué necesito»
create policy "opciones de necesidad activas visibles"
  on public.need_options for select to authenticated
  using (is_active or public.is_staff());
create policy "staff gestiona opciones de necesidad"
  on public.need_options for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

create policy "recomendaciones visibles"
  on public.need_recommendations for select to authenticated using (true);
create policy "staff gestiona recomendaciones"
  on public.need_recommendations for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

create policy "cada quien lee sus consultas de necesidades"
  on public.need_sessions for select to authenticated using (user_id = auth.uid());
create policy "cada quien registra sus consultas de necesidades"
  on public.need_sessions for insert to authenticated with check (user_id = auth.uid());

create policy "cada quien lee las opciones de sus consultas"
  on public.need_session_options for select to authenticated
  using (exists (
    select 1 from public.need_sessions s
    where s.id = need_session_id and s.user_id = auth.uid()
  ));
create policy "cada quien registra las opciones de sus consultas"
  on public.need_session_options for insert to authenticated
  with check (exists (
    select 1 from public.need_sessions s
    where s.id = need_session_id and s.user_id = auth.uid()
  ));
