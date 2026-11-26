begin;
create or replace function public.ls_rank74() returns table(peer uuid, points bigint, wins bigint) language sql stable security definer set search_path='' as $$
with people as (select auth.uid() as uid where auth.uid() is not null union select f.peer from public.ls_friends() f where f.accepted and auth.uid() is not null)
select p.uid, greatest(0,coalesce(sum(case when t.winner=p.uid then 25 when t.winner is not null then -10 else 0 end),0)), count(*) filter(where t.winner=p.uid) from people p left join public.ls_arena63 t on p.uid in(t.a,t.b) and t.mode='ranked' and t.status='finished' group by p.uid
$$;
revoke all on function public.ls_rank74() from public,anon;
grant execute on function public.ls_rank74() to authenticated;
notify pgrst,'reload schema';
commit;
