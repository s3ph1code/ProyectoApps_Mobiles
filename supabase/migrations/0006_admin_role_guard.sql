-- 0006: una administradora no puede quitarse a sí misma el rol de administradora.
-- La política de user_roles deja a quien sea admin borrar cualquier fila; sin
-- esta guarda, un descuido en la app dejaría al proyecto sin administración.
-- Las operaciones sin sesión (panel de Supabase, service role) no se ven
-- afectadas: auth.uid() es nulo.

create or replace function public.guard_own_admin_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null
     and old.user_id = auth.uid()
     and old.role_id = (select id from public.roles where code = 'admin') then
    raise exception 'No puedes quitarte a ti misma el rol de administradora';
  end if;
  return old;
end;
$$;

revoke all on function public.guard_own_admin_role() from public, anon, authenticated;

drop trigger if exists guard_own_admin_role on public.user_roles;
create trigger guard_own_admin_role
  before delete on public.user_roles
  for each row execute function public.guard_own_admin_role();
