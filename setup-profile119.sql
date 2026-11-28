-- V120: Freunde-Profilkarte und Sichtbarkeit. Einmal im Supabase SQL Editor ausführen.
create or replace function public.ls_card119(peer uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select s.data->'profile'->'card119' from public.learnspot_state s
 where auth.uid() is not null and s.user_id=peer and exists(select 1 from public.ls_connections c where c.accepted and ((c.sender=auth.uid() and c.recipient=peer) or (c.recipient=auth.uid() and c.sender=peer))) $$;
create or replace function public.ls_profiles52() returns table(peer uuid,accepted boolean,incoming boolean,display_name text,image text,bio text) language sql stable security definer set search_path='' as $$
 select f.peer,f.accepted,f.incoming,f.display_name,
 case when f.accepted and coalesce((s.data->'profile'->'share119'->>'image')::boolean,true) then s.data->'profile'->>'image' end,
 case when f.accepted and coalesce((s.data->'profile'->'share119'->>'bio')::boolean,true) then s.data->'profile'->>'bio' end
 from public.ls_friends_named() f left join public.learnspot_state s on s.user_id=f.peer where auth.uid() is not null $$;
revoke all on function public.ls_card119(uuid),public.ls_profiles52() from public,anon;
grant execute on function public.ls_card119(uuid),public.ls_profiles52() to authenticated;
