-- Doulapp — migración 0004: comunidad, moderación y notificaciones (S3-T1)
--
-- Requiere 0001, 0002 y 0003 aplicadas. Crea las tablas de comunidad,
-- moderación y notificaciones (las mismas de schema.sql), les agrega
-- seguridad a nivel de fila y carga las categorías de la comunidad.
--
-- Se puede ejecutar varias veces: todo usa `if not exists`, `create or
-- replace` o borra la política antes de volver a crearla.
--
-- Criterio general:
--   * Una publicación o un comentario se ve si está publicado y su autora no
--     está bloqueada por quien consulta. La autora ve siempre lo suyo y la
--     moderación lo ve todo.
--   * Solo la autora edita el texto; solo moderadora o administradora cambian
--     el estado (`hidden`, `removed`). Lo garantiza un trigger, porque una
--     política no puede limitar qué columnas cambian.
--   * Reacciones, guardados, seguimientos, bloqueos y envíos: cada quien los
--     suyos. Los contadores del feed salen de funciones security definer para
--     no abrir las filas ajenas.

-- Funciones auxiliares (ya existen desde 0002; se repiten para que esta
-- migración no dependa del orden exacto en que se corrieron las anteriores).
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
-- TABLAS
-- =====================================================================

create table if not exists public.community_categories (
  id        uuid primary key default gen_random_uuid(),
  name      varchar(60) not null unique,
  slug      varchar(70) not null unique,
  is_active boolean     not null default true
);

create table if not exists public.posts (
  id         uuid primary key default gen_random_uuid(),
  author_id  uuid        not null references public.profiles (id) on delete cascade,
  post_type  varchar(20) not null check (post_type in ('experience','question','message')),
  body       text        not null,
  visibility varchar(20) not null default 'community' check (visibility in ('public','community')),
  status     varchar(20) not null default 'published' check (status in ('published','hidden','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_author_idx on public.posts (author_id);
create index if not exists posts_published_recent_idx
  on public.posts (created_at desc) where status = 'published';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'posts_body_length') then
    alter table public.posts
      add constraint posts_body_length
      check (char_length(btrim(body)) between 1 and 2000);
  end if;
end;
$$;

create table if not exists public.post_categories (
  post_id     uuid not null references public.posts (id)                on delete cascade,
  category_id uuid not null references public.community_categories (id) on delete cascade,
  primary key (post_id, category_id)
);

create index if not exists post_categories_category_idx
  on public.post_categories (category_id);

create table if not exists public.comments (
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

create index if not exists comments_post_idx on public.comments (post_id, created_at);

create table if not exists public.reactions (
  user_id       uuid not null references public.profiles (id) on delete cascade,
  post_id       uuid not null references public.posts (id)    on delete cascade,
  reaction_type varchar(20) not null check (reaction_type in ('support','thanks','same')),
  created_at    timestamptz not null default now(),
  primary key (user_id, post_id)
);

create index if not exists reactions_post_idx on public.reactions (post_id);

create table if not exists public.saved_posts (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  post_id    uuid not null references public.posts (id)    on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

create table if not exists public.user_topic_follows (
  user_id     uuid not null references public.profiles (id)             on delete cascade,
  category_id uuid not null references public.community_categories (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, category_id)
);

create table if not exists public.post_shares (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid        not null references public.posts (id)    on delete cascade,
  shared_by  uuid        not null references public.profiles (id) on delete cascade,
  channel    varchar(20) not null check (channel in ('link','whatsapp','other')),
  created_at timestamptz not null default now()
);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint no_autobloqueo check (blocker_id <> blocked_id)
);

create table if not exists public.post_media (
  post_id  uuid not null references public.posts (id)        on delete cascade,
  media_id uuid not null references public.media_assets (id) on delete cascade,
  position smallint not null default 0,
  caption  varchar(250),
  primary key (post_id, media_id)
);

create table if not exists public.content_reports (
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

create index if not exists content_reports_status_idx
  on public.content_reports (status, created_at);

create table if not exists public.notifications (
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

create index if not exists notifications_unread_idx
  on public.notifications (recipient_id, created_at desc) where not is_read;


-- =====================================================================
-- TRIGGERS
-- =====================================================================

drop trigger if exists posts_touch on public.posts;
create trigger posts_touch
  before update on public.posts
  for each row execute function public.touch_updated_at();

drop trigger if exists comments_touch on public.comments;
create trigger comments_touch
  before update on public.comments
  for each row execute function public.touch_updated_at();

-- La política de update deja pasar a la autora y a la moderación; este
-- trigger decide qué puede cambiar cada una. Sirve para posts y comments.
create or replace function public.guard_content_update()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  -- Sin sesión es el SQL Editor o la service role: mantenimiento, no la app.
  if auth.uid() is null then
    return new;
  end if;

  if new.author_id <> old.author_id then
    raise exception 'No se puede cambiar la autora de un contenido';
  end if;

  if new.status <> old.status and not public.is_staff() then
    raise exception 'Solo la moderación puede cambiar el estado de un contenido';
  end if;

  if new.body is distinct from old.body and old.author_id <> auth.uid() then
    raise exception 'Solo la autora puede editar el texto';
  end if;

  if tg_table_name = 'posts'
     and (new.post_type is distinct from old.post_type
          or new.visibility is distinct from old.visibility)
     and old.author_id <> auth.uid() then
    raise exception 'Solo la autora puede editar la publicación';
  end if;

  return new;
end;
$$;

drop trigger if exists posts_guard_update on public.posts;
create trigger posts_guard_update
  before update on public.posts
  for each row execute function public.guard_content_update();

drop trigger if exists comments_guard_update on public.comments;
create trigger comments_guard_update
  before update on public.comments
  for each row execute function public.guard_content_update();


-- =====================================================================
-- FUNCIONES DE APOYO PARA RLS Y EL FEED
-- =====================================================================

-- security definer: user_blocks solo deja ver las filas propias, y aquí se
-- consulta justamente eso, pero así la política no reevalúa RLS por fila.
create or replace function public.is_blocked_by_me(p_user uuid)
returns boolean
language sql security definer stable set search_path = public
as $$
  select exists (
    select 1 from public.user_blocks b
    where b.blocker_id = auth.uid() and b.blocked_id = p_user
  );
$$;

-- Los contadores cuentan filas que la usuaria no puede leer una por una
-- (las reacciones de las demás), por eso van en funciones security definer
-- que solo devuelven el número.
create or replace function public.post_reaction_count(p_post uuid)
returns integer
language sql security definer stable set search_path = public
as $$
  select count(*)::int from public.reactions r where r.post_id = p_post;
$$;

create or replace function public.post_comment_count(p_post uuid)
returns integer
language sql security definer stable set search_path = public
as $$
  select count(*)::int
  from public.comments c
  where c.post_id = p_post
    and c.status = 'published'
    and not public.is_blocked_by_me(c.author_id);
$$;


-- =====================================================================
-- SEGURIDAD A NIVEL DE FILA
-- =====================================================================

alter table public.community_categories enable row level security;
alter table public.posts                enable row level security;
alter table public.post_categories      enable row level security;
alter table public.comments             enable row level security;
alter table public.reactions            enable row level security;
alter table public.saved_posts          enable row level security;
alter table public.user_topic_follows   enable row level security;
alter table public.post_shares          enable row level security;
alter table public.user_blocks          enable row level security;
alter table public.post_media           enable row level security;
alter table public.content_reports      enable row level security;
alter table public.notifications        enable row level security;

-- Categorías de comunidad ---------------------------------------------
drop policy if exists "categorias de comunidad activas visibles" on public.community_categories;
create policy "categorias de comunidad activas visibles"
  on public.community_categories for select to authenticated
  using (is_active or public.is_staff());

drop policy if exists "staff gestiona categorias de comunidad" on public.community_categories;
create policy "staff gestiona categorias de comunidad"
  on public.community_categories for all to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- Publicaciones -------------------------------------------------------
drop policy if exists "publicaciones visibles" on public.posts;
create policy "publicaciones visibles"
  on public.posts for select to authenticated
  using (
    (status = 'published' and not public.is_blocked_by_me(author_id))
    or author_id = auth.uid()
    or public.is_staff()
  );

drop policy if exists "cada quien publica como si misma" on public.posts;
create policy "cada quien publica como si misma"
  on public.posts for insert to authenticated
  with check (author_id = auth.uid() and status = 'published');

drop policy if exists "autora o moderacion actualizan publicaciones" on public.posts;
create policy "autora o moderacion actualizan publicaciones"
  on public.posts for update to authenticated
  using (author_id = auth.uid() or public.is_staff())
  with check (author_id = auth.uid() or public.is_staff());

drop policy if exists "cada quien borra sus publicaciones" on public.posts;
create policy "cada quien borra sus publicaciones"
  on public.posts for delete to authenticated
  using (author_id = auth.uid());

-- Categorías y multimedia de una publicación: siguen a la publicación. La
-- subconsulta sobre posts ya pasa por el RLS de posts.
drop policy if exists "categorias de publicaciones visibles" on public.post_categories;
create policy "categorias de publicaciones visibles"
  on public.post_categories for select to authenticated
  using (exists (select 1 from public.posts p where p.id = post_id));

drop policy if exists "la autora asigna categorias" on public.post_categories;
create policy "la autora asigna categorias"
  on public.post_categories for insert to authenticated
  with check (exists (
    select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()
  ));

drop policy if exists "la autora quita categorias" on public.post_categories;
create policy "la autora quita categorias"
  on public.post_categories for delete to authenticated
  using (exists (
    select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()
  ));

drop policy if exists "multimedia de publicaciones visible" on public.post_media;
create policy "multimedia de publicaciones visible"
  on public.post_media for select to authenticated
  using (exists (select 1 from public.posts p where p.id = post_id));

drop policy if exists "la autora adjunta multimedia" on public.post_media;
create policy "la autora adjunta multimedia"
  on public.post_media for insert to authenticated
  with check (exists (
    select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()
  ));

drop policy if exists "la autora quita multimedia" on public.post_media;
create policy "la autora quita multimedia"
  on public.post_media for delete to authenticated
  using (exists (
    select 1 from public.posts p where p.id = post_id and p.author_id = auth.uid()
  ));

-- Comentarios ---------------------------------------------------------
drop policy if exists "comentarios visibles" on public.comments;
create policy "comentarios visibles"
  on public.comments for select to authenticated
  using (
    (status = 'published'
      and not public.is_blocked_by_me(author_id)
      and exists (select 1 from public.posts p where p.id = post_id))
    or author_id = auth.uid()
    or public.is_staff()
  );

drop policy if exists "cada quien comenta como si misma" on public.comments;
create policy "cada quien comenta como si misma"
  on public.comments for insert to authenticated
  with check (
    author_id = auth.uid()
    and status = 'published'
    and exists (
      select 1 from public.posts p
      where p.id = post_id and p.status = 'published'
    )
  );

drop policy if exists "autora o moderacion actualizan comentarios" on public.comments;
create policy "autora o moderacion actualizan comentarios"
  on public.comments for update to authenticated
  using (author_id = auth.uid() or public.is_staff())
  with check (author_id = auth.uid() or public.is_staff());

drop policy if exists "cada quien borra sus comentarios" on public.comments;
create policy "cada quien borra sus comentarios"
  on public.comments for delete to authenticated
  using (author_id = auth.uid());

-- Reacciones, guardados y seguimientos (datos propios) ----------------
drop policy if exists "cada quien lee sus reacciones" on public.reactions;
create policy "cada quien lee sus reacciones"
  on public.reactions for select to authenticated using (user_id = auth.uid());
drop policy if exists "cada quien reacciona" on public.reactions;
create policy "cada quien reacciona"
  on public.reactions for insert to authenticated
  with check (user_id = auth.uid() and exists (
    select 1 from public.posts p where p.id = post_id and p.status = 'published'
  ));
drop policy if exists "cada quien cambia su reaccion" on public.reactions;
create policy "cada quien cambia su reaccion"
  on public.reactions for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "cada quien quita su reaccion" on public.reactions;
create policy "cada quien quita su reaccion"
  on public.reactions for delete to authenticated using (user_id = auth.uid());

drop policy if exists "cada quien lee sus guardados" on public.saved_posts;
create policy "cada quien lee sus guardados"
  on public.saved_posts for select to authenticated using (user_id = auth.uid());
drop policy if exists "cada quien guarda publicaciones" on public.saved_posts;
create policy "cada quien guarda publicaciones"
  on public.saved_posts for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "cada quien quita sus guardados" on public.saved_posts;
create policy "cada quien quita sus guardados"
  on public.saved_posts for delete to authenticated using (user_id = auth.uid());

drop policy if exists "cada quien lee los temas que sigue" on public.user_topic_follows;
create policy "cada quien lee los temas que sigue"
  on public.user_topic_follows for select to authenticated using (user_id = auth.uid());
drop policy if exists "cada quien sigue temas" on public.user_topic_follows;
create policy "cada quien sigue temas"
  on public.user_topic_follows for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "cada quien deja de seguir temas" on public.user_topic_follows;
create policy "cada quien deja de seguir temas"
  on public.user_topic_follows for delete to authenticated using (user_id = auth.uid());

drop policy if exists "cada quien lee lo que compartio" on public.post_shares;
create policy "cada quien lee lo que compartio"
  on public.post_shares for select to authenticated using (shared_by = auth.uid());
drop policy if exists "cada quien registra lo que comparte" on public.post_shares;
create policy "cada quien registra lo que comparte"
  on public.post_shares for insert to authenticated with check (shared_by = auth.uid());

-- Bloqueos ------------------------------------------------------------
drop policy if exists "cada quien lee sus bloqueos" on public.user_blocks;
create policy "cada quien lee sus bloqueos"
  on public.user_blocks for select to authenticated using (blocker_id = auth.uid());
drop policy if exists "cada quien bloquea" on public.user_blocks;
create policy "cada quien bloquea"
  on public.user_blocks for insert to authenticated with check (blocker_id = auth.uid());
drop policy if exists "cada quien desbloquea" on public.user_blocks;
create policy "cada quien desbloquea"
  on public.user_blocks for delete to authenticated using (blocker_id = auth.uid());

-- Reportes ------------------------------------------------------------
drop policy if exists "cada quien reporta" on public.content_reports;
create policy "cada quien reporta"
  on public.content_reports for insert to authenticated
  with check (reporter_id = auth.uid() and status = 'pending');

drop policy if exists "reportes propios o de moderacion" on public.content_reports;
create policy "reportes propios o de moderacion"
  on public.content_reports for select to authenticated
  using (reporter_id = auth.uid() or public.is_staff());

drop policy if exists "moderacion revisa reportes" on public.content_reports;
create policy "moderacion revisa reportes"
  on public.content_reports for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- Roles: la administradora asigna y retira; la lectura propia viene de 0001
drop policy if exists "administracion lee todos los roles" on public.user_roles;
create policy "administracion lee todos los roles"
  on public.user_roles for select to authenticated
  using (public.has_role('admin'));

drop policy if exists "administracion asigna roles" on public.user_roles;
create policy "administracion asigna roles"
  on public.user_roles for insert to authenticated
  with check (public.has_role('admin'));

drop policy if exists "administracion retira roles" on public.user_roles;
create policy "administracion retira roles"
  on public.user_roles for delete to authenticated
  using (public.has_role('admin'));

-- Notificaciones ------------------------------------------------------
drop policy if exists "cada quien lee sus notificaciones" on public.notifications;
create policy "cada quien lee sus notificaciones"
  on public.notifications for select to authenticated
  using (recipient_id = auth.uid());

drop policy if exists "cada quien marca sus notificaciones" on public.notifications;
create policy "cada quien marca sus notificaciones"
  on public.notifications for update to authenticated
  using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());


-- =====================================================================
-- FEED Y PUBLICAR
-- =====================================================================

-- security_invoker: la vista respeta el RLS de quien consulta, así que no
-- devuelve nada que posts no devolvería.
create or replace view public.post_feed
with (security_invoker = true)
as
select
  p.id,
  p.author_id,
  pr.display_name as author_name,
  pr.avatar_url   as author_avatar_url,
  p.post_type,
  p.body,
  p.visibility,
  p.status,
  p.created_at,
  p.updated_at,
  coalesce(
    (select jsonb_agg(
              jsonb_build_object('id', c.id, 'name', c.name, 'slug', c.slug)
              order by c.name)
       from public.post_categories pc
       join public.community_categories c on c.id = pc.category_id
      where pc.post_id = p.id),
    '[]'::jsonb
  ) as categories,
  coalesce(
    (select array_agg(pc.category_id)
       from public.post_categories pc
      where pc.post_id = p.id),
    '{}'::uuid[]
  ) as category_ids,
  public.post_reaction_count(p.id) as reaction_count,
  public.post_comment_count(p.id)  as comment_count
from public.posts p
left join public.profiles pr on pr.id = p.author_id;

grant select on public.post_feed to authenticated;

-- Crea la publicación y sus categorías en una sola transacción, para que no
-- quede una publicación sin categorías si falla la segunda inserción. Corre
-- como quien llama (security invoker), así que aplica el RLS de siempre.
create or replace function public.create_post(
  p_post_type    text,
  p_body         text,
  p_visibility   text,
  p_category_ids uuid[]
)
returns uuid
language plpgsql security invoker set search_path = public
as $$
declare
  v_post_id uuid;
  v_valid   int;
begin
  if auth.uid() is null then
    raise exception 'Se necesita una sesión activa para publicar';
  end if;

  if p_category_ids is null or cardinality(p_category_ids) = 0 then
    raise exception 'Elige al menos una categoría';
  end if;

  select count(*) into v_valid
  from public.community_categories
  where id = any (p_category_ids) and is_active;

  if v_valid <> cardinality(array(select distinct unnest(p_category_ids))) then
    raise exception 'Alguna categoría elegida no está disponible';
  end if;

  insert into public.posts (author_id, post_type, body, visibility)
  values (auth.uid(), p_post_type, btrim(p_body), p_visibility)
  returning id into v_post_id;

  insert into public.post_categories (post_id, category_id)
  select v_post_id, c from (select distinct unnest(p_category_ids) as c) s;

  return v_post_id;
end;
$$;

grant execute on function public.create_post(text, text, text, uuid[]) to authenticated;


-- =====================================================================
-- CATEGORÍAS DE LA COMUNIDAD
-- =====================================================================

insert into public.community_categories (name, slug) values
  ('Primeras semanas',      'primeras-semanas'),
  ('Lactancia',             'lactancia'),
  ('Sueño y cansancio',     'sueno-y-cansancio'),
  ('Emociones',             'emociones'),
  ('Cuerpo y recuperación', 'cuerpo-y-recuperacion'),
  ('Red de apoyo',          'red-de-apoyo')
on conflict (slug) do nothing;
