-- Doulapp — publicaciones de demostración para la comunidad
--
-- Ejecutar en el SQL Editor de Supabase después de 0004. Necesita al menos una
-- cuenta creada desde la app: las publicaciones se reparten entre las tres
-- cuentas más antiguas. Se puede correr varias veces: no duplica filas.
-- El texto es un borrador para que el equipo lo revise; no ofrece consejo
-- médico.

with autoras as (
  select id, row_number() over (order by created_at) as n, count(*) over () as total
  from public.profiles
  where deleted_at is null
  order by created_at
  limit 3
),
nuevas (n, post_type, body, horas, categorias) as (values
  (1, 'experience',
   'Hoy fue la primera vez que salí a caminar sola diez minutos. No pasó nada extraordinario, pero volví sintiéndome un poco más yo. Si alguien lo necesita leer: está bien pedir que te cuiden al bebé un ratito.',
   2, array['red-de-apoyo','emociones']),
  (2, 'question',
   '¿A alguien más le pasa que de noche todo se siente más pesado? De día lo llevo bien y a las tres de la mañana me entra una tristeza que no sé explicar.',
   5, array['emociones','sueno-y-cansancio']),
  (3, 'message',
   'Para las que están en las primeras semanas: no tienen que tener la casa ordenada ni responder todos los mensajes. Sobrevivir el día ya es bastante.',
   9, array['primeras-semanas']),
  (1, 'question',
   '¿Qué les ayudó cuando la lactancia dolía? Ya hablé con mi médica, pero me gustaría saber cómo lo vivieron otras.',
   20, array['lactancia','cuerpo-y-recuperacion']),
  (2, 'experience',
   'Le pedí a mi hermana que viniera dos tardes por semana. Me costó muchísimo pedirlo y resultó que ella llevaba semanas queriendo ayudar sin saber cómo.',
   30, array['red-de-apoyo']),
  (3, 'experience',
   'Mi cuerpo no se parece al de antes y estoy aprendiendo a hablarle con más cariño. Algunos días lo logro y otros no, y está bien.',
   48, array['cuerpo-y-recuperacion','emociones'])
),
insertadas as (
  insert into public.posts (author_id, post_type, body, visibility, created_at, updated_at)
  select a.id, nv.post_type, nv.body, 'community',
         now() - make_interval(hours => nv.horas),
         now() - make_interval(hours => nv.horas)
  from nuevas nv
  join autoras a on a.n = ((nv.n - 1) % a.total) + 1
  where not exists (select 1 from public.posts p where p.body = nv.body)
  returning id, body
)
insert into public.post_categories (post_id, category_id)
select i.id, c.id
from insertadas i
join nuevas nv on nv.body = i.body
join public.community_categories c on c.slug = any (nv.categorias)
on conflict do nothing;

-- Comentarios de ejemplo ----------------------------------------------
with autoras as (
  select id, row_number() over (order by created_at) as n, count(*) over () as total
  from public.profiles
  where deleted_at is null
  order by created_at
  limit 3
),
nuevos (post_inicio, n, body) as (values
  ('¿A alguien más le pasa que de noche', 1,
   'Me pasaba igual. Hablarlo con alguien de confianza me ayudó a sentirme menos sola con eso.'),
  ('¿A alguien más le pasa que de noche', 3,
   'Gracias por escribirlo. Leerte me hizo sentir acompañada.'),
  ('Hoy fue la primera vez que salí', 2,
   'Diez minutos para ti cuentan muchísimo. Qué bueno que te diste ese espacio.'),
  ('¿Qué les ayudó cuando la lactancia', 3,
   'A mí me sirvió mucho que una asesora me acompañara en una toma. Cada caso es distinto, ojalá encuentres a alguien así.')
)
insert into public.comments (post_id, author_id, body)
select p.id, a.id, nv.body
from nuevos nv
join public.posts p on p.body like nv.post_inicio || '%'
join autoras a on a.n = ((nv.n - 1) % a.total) + 1
where not exists (
  select 1 from public.comments c where c.post_id = p.id and c.body = nv.body
);

-- Comprobación: publicaciones con su conteo de comentarios.
select p.post_type, left(p.body, 60) as inicio,
       (select count(*) from public.comments c where c.post_id = p.id) as comentarios
from public.posts p
order by p.created_at desc;
