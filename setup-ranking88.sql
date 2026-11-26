begin;
create or replace function public.ls_global88() returns table(peer uuid,points bigint,wins bigint,display_name text,image text) language sql stable security definer set search_path='' as $$
select s.user_id,greatest(0,coalesce(sum(case when t.winner=s.user_id then 25 when t.winner is not null then -10 else 0 end),0)),count(*) filter(where t.winner=s.user_id),coalesce(nullif(btrim(s.data->'profile'->>'name'),''),'Spieler'),s.data->'profile'->>'image'
from public.learnspot_state s left join public.ls_arena63 t on s.user_id in(t.a,t.b) and t.mode='ranked' and t.status='finished' where auth.uid() is not null group by s.user_id,s.data order by 2 desc,3 desc,1 limit 10
$$;
create or replace function public.ls_weekly86() returns uuid language sql stable security definer set search_path='' as $$
with cutoff as (select date_trunc('week',now() at time zone 'Europe/Berlin') at time zone 'Europe/Berlin' as stamp), scores as (select s.user_id,greatest(0,coalesce(sum(case when t.winner=s.user_id then 25 when t.winner is not null then -10 else 0 end),0)) as points,count(*) filter(where t.winner=s.user_id) as wins from public.learnspot_state s cross join cutoff c left join public.ls_arena63 t on s.user_id in(t.a,t.b) and t.mode='ranked' and t.status='finished' and t.finished86<c.stamp where auth.uid() is not null group by s.user_id) select user_id from scores where wins>0 order by points desc,wins desc,user_id limit 1
$$;
revoke all on function public.ls_global88(),public.ls_weekly86() from public,anon;
grant execute on function public.ls_global88(),public.ls_weekly86() to authenticated;
notify pgrst,'reload schema';
commit;
