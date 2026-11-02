-- Doulapp — roles de demostración
--
-- Toda cuenta nueva recibe el rol `user` (lo asigna el trigger
-- handle_new_user). Las cuentas de moderadora y de administradora no se
-- registran desde la app: primero se crean como cualquier cuenta y luego se
-- ejecuta este script en el SQL Editor de Supabase.
--
-- Cambia los correos por los de las cuentas que creaste. La cuenta conserva
-- el rol `user` y suma el nuevo; la app muestra el de mayor jerarquía.

insert into public.user_roles (user_id, role_id)
select u.id, r.id
from auth.users u
join public.roles r on r.code = 'moderator'
where u.email = 'moderadora@doulapp.test'
on conflict do nothing;

insert into public.user_roles (user_id, role_id)
select u.id, r.id
from auth.users u
join public.roles r on r.code = 'admin'
where u.email = 'admin@doulapp.test'
on conflict do nothing;

-- Comprobación: debe listar una fila por cada rol de cada cuenta.
select u.email, r.code as rol
from public.user_roles ur
join auth.users u on u.id = ur.user_id
join public.roles r on r.id = ur.role_id
order by u.email, r.id;
