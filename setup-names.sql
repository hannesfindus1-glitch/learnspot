begin;
create or replace function public.ls_friends_named() returns table(peer uuid,accepted boolean,incoming boolean,display_name text) language sql stable security definer set search_path='' as $$
select f.peer,f.accepted,f.incoming,coalesce(nullif(btrim(s.data->'profile'->>'name'),''),'Unbekanntes Profil') from public.ls_friends() f left join public.learnspot_state s on s.user_id=f.peer where auth.uid() is not null $$;
create or replace function public.ls_chat_named(peer uuid) returns table(sender uuid,body text,material jsonb,display_name text) language sql stable security definer set search_path='' as $$
select m.sender,m.body,m.material,coalesce(nullif(btrim(s.data->'profile'->>'name'),''),'Unbekanntes Profil') from public.ls_chat(peer) m left join public.learnspot_state s on s.user_id=m.sender where auth.uid() is not null $$;
create or replace function public.ls_group_chat_named(gid uuid) returns table(sender uuid,body text,material jsonb,display_name text) language sql stable security definer set search_path='' as $$
select m.sender,m.body,m.material,coalesce(nullif(btrim(s.data->'profile'->>'name'),''),'Unbekanntes Profil') from public.ls_group_chat(gid) m left join public.learnspot_state s on s.user_id=m.sender where auth.uid() is not null $$;
revoke all on function public.ls_friends_named(),public.ls_chat_named(uuid),public.ls_group_chat_named(uuid) from public,anon;
grant execute on function public.ls_friends_named(),public.ls_chat_named(uuid),public.ls_group_chat_named(uuid) to authenticated;
notify pgrst, 'reload schema';
commit;
