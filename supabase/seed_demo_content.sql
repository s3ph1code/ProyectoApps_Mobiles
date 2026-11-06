-- Doulapp — contenido de demostración (microdescansos y «No sé qué necesito»)
--
-- Ejecutar en el SQL Editor de Supabase después de 0002. Se puede correr
-- varias veces: no duplica filas. El texto es un borrador para que el equipo
-- lo revise; no ofrece consejo médico.

-- Categorías ----------------------------------------------------------
insert into public.activity_categories (name, slug) values
  ('Respiración',      'respiracion'),
  ('Descanso',         'descanso'),
  ('Movimiento suave', 'movimiento'),
  ('Mente amable',     'mente-amable')
on conflict (slug) do nothing;

-- Actividades ---------------------------------------------------------
with nuevas (cat, title, description, modality, minutes, content) as (values
  ('respiracion', 'Respiración 4-7-8',
   'Una pausa para bajar el ritmo cuando todo se siente acelerado.',
   'do', 3,
   'Siéntate o recuéstate. Inhala por la nariz contando 4, sostén el aire contando 7 y suéltalo despacio por la boca contando 8. Repite cuatro veces. Si te mareas, vuelve a respirar con normalidad.'),
  ('respiracion', 'Respiración de caja',
   'Cuatro tiempos iguales para encontrar un ritmo estable.',
   'do', 4,
   'Inhala contando 4, sostén 4, exhala 4 y sostén 4. Imagina que dibujas los lados de una caja. Hazlo durante unos minutos, a tu ritmo.'),
  ('descanso', 'Cinco minutos con los ojos cerrados',
   'No tienes que dormir: solo parar un momento.',
   'do', 5,
   'Busca un lugar donde estar cómoda y cierra los ojos. No hace falta pensar en nada. Si llegan ideas, déjalas pasar. Cuando termines, abre los ojos despacio.'),
  ('descanso', 'Escáner corporal',
   'Recorrer el cuerpo con atención, sin exigirle nada.',
   'read', 6,
   'Empieza por los pies y sube poco a poco: piernas, caderas, espalda, hombros, rostro. En cada zona, solo nota cómo está. No hay forma correcta de sentirse.'),
  ('descanso', 'Una bebida caliente sin pantallas',
   'Un ratito de calma con algo que te guste tomar.',
   'do', 10,
   'Prepara tu bebida favorita y tómala sin celular. Fíjate en el calor de la taza, el aroma y el sabor. Es un momento para ti.'),
  ('movimiento', 'Estiramiento de cuello y hombros',
   'Soltar la tensión de cargar, dar de comer y mecer.',
   'do', 4,
   'Sentada, deja caer la oreja derecha hacia el hombro y respira tres veces. Cambia de lado. Luego sube los hombros hacia las orejas y suéltalos de golpe, tres veces.'),
  ('movimiento', 'Movilidad suave de espalda',
   'Movimientos lentos para aliviar la espalda baja.',
   'do', 5,
   'A cuatro apoyos, arquea la espalda hacia arriba al exhalar y bájala al inhalar, despacio. Repite ocho veces. Detente si algo te molesta.'),
  ('mente-amable', 'Tres cosas buenas de hoy',
   'Notar lo pequeño que sí salió bien.',
   'do', 3,
   'Piensa o escribe tres cosas del día que te hayan hecho bien, por pequeñas que sean: un café caliente, una sonrisa, diez minutos de silencio.'),
  ('mente-amable', 'Una carta para mí',
   'Háblate como le hablarías a una amiga.',
   'read', 6,
   'Escribe unas líneas a ti misma como si se las escribieras a una amiga que está pasando por lo mismo. Sin juicios y sin exigencias: solo con cariño.')
)
insert into public.activities
  (category_id, title, description, modality, duration_minutes, content_text, is_published)
select c.id, n.title, n.description, n.modality, n.minutes, n.content, true
from nuevas n
join public.activity_categories c on c.slug = n.cat
where not exists (select 1 from public.activities a where a.title = n.title);

-- Opciones de necesidad -----------------------------------------------
insert into public.need_options (code, label) values
  ('cansancio',  'Estoy muy cansada'),
  ('ansiedad',   'Me siento ansiosa o abrumada'),
  ('tristeza',   'Me siento triste o sin ganas'),
  ('soledad',    'Me siento sola'),
  ('cuerpo',     'Me duele el cuerpo'),
  ('sin_tiempo', 'No tengo tiempo para mí'),
  ('hablar',     'Quiero hablar con otras madres')
on conflict (code) do nothing;

-- Recomendaciones (la lógica vive como datos) -------------------------
with recs (need, act, dest, msg, prio) as (values
  ('cansancio',  'Cinco minutos con los ojos cerrados', 'activities',   'Una pausa corta puede ayudarte a recargar un poco.', 10),
  ('cansancio',  'Una bebida caliente sin pantallas',   'activities',   'Un momento de calma con algo que te guste.', 20),
  ('ansiedad',   'Respiración 4-7-8',                   'activities',   'Respirar despacio puede ayudarte a bajar el ritmo.', 10),
  ('ansiedad',   'Respiración de caja',                 'activities',   'Cuatro tiempos iguales para encontrar estabilidad.', 20),
  ('tristeza',   null,                                  'mood_checkin', 'Contarte cómo te sientes también cuenta. Hazlo sin presión.', 10),
  ('tristeza',   'Una carta para mí',                   'activities',   'Háblate con el cariño que le darías a una amiga.', 20),
  ('soledad',    null,                                  'community',    'Otras madres están viviendo algo parecido. Puedes leerlas o escribir.', 10),
  ('soledad',    'Tres cosas buenas de hoy',            'activities',   'Notar lo pequeño que sí salió bien.', 20),
  ('cuerpo',     'Estiramiento de cuello y hombros',    'activities',   'Un estiramiento suave para soltar la tensión.', 10),
  ('cuerpo',     'Movilidad suave de espalda',          'activities',   'Movimientos lentos para tu espalda, a tu ritmo.', 20),
  ('sin_tiempo', 'Respiración 4-7-8',                   'activities',   'Solo tres minutos. Es suficiente para empezar.', 10),
  ('hablar',     null,                                  'community',    'La comunidad es un espacio sin juicios para compartir.', 10)
)
insert into public.need_recommendations (need_option_id, activity_id, destination_code, message, priority)
select o.id, a.id, r.dest, r.msg, r.prio
from recs r
join public.need_options o on o.code = r.need
left join public.activities a on a.title = r.act
where not exists (
  select 1 from public.need_recommendations x
  where x.need_option_id = o.id and x.message = r.msg
);

-- Comprobación: conteos esperados 4 / 9 / 7 / 12
select
  (select count(*) from public.activity_categories) as categorias,
  (select count(*) from public.activities where is_published) as actividades,
  (select count(*) from public.need_options) as necesidades,
  (select count(*) from public.need_recommendations) as recomendaciones;
