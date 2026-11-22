-- Doulapp — migración 0005: endurecimiento de funciones (hallazgos del linter de Supabase)
--
-- Requiere 0001–0004 aplicadas. Idempotente.
--   * touch_updated_at fija su search_path.
--   * Las funciones auxiliares security definer dejan de ser ejecutables por
--     `anon` (ni por PUBLIC): solo las usuarias autenticadas las necesitan.
--   * Las funciones de trigger no se exponen como RPC: los triggers siguen
--     funcionando porque el permiso EXECUTE solo se revisa al crear el trigger.

alter function public.touch_updated_at() set search_path = public;

revoke execute on function public.has_role(text)            from public, anon;
revoke execute on function public.is_staff()                from public, anon;
revoke execute on function public.profile_is_visible(uuid)  from public, anon;
revoke execute on function public.is_blocked_by_me(uuid)    from public, anon;
revoke execute on function public.post_reaction_count(uuid) from public, anon;
revoke execute on function public.post_comment_count(uuid)  from public, anon;
revoke execute on function public.create_post(text, text, text, uuid[]) from public, anon;

grant execute on function public.has_role(text)            to authenticated;
grant execute on function public.is_staff()                to authenticated;
grant execute on function public.profile_is_visible(uuid)  to authenticated;
grant execute on function public.is_blocked_by_me(uuid)    to authenticated;
grant execute on function public.post_reaction_count(uuid) to authenticated;
grant execute on function public.post_comment_count(uuid)  to authenticated;
grant execute on function public.create_post(text, text, text, uuid[]) to authenticated;

revoke execute on function public.handle_new_user()      from public, anon, authenticated;
revoke execute on function public.guard_content_update() from public, anon, authenticated;
