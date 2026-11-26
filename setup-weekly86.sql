begin;
alter table public.ls_arena63 add column if not exists finished86 timestamptz;
update public.ls_arena63 set finished86=now() where status='finished' and finished86 is null;
create or replace function public.ls_stamp86() returns trigger language plpgsql set search_path='' as $$
begin
 if new.status='finished' and old.status is distinct from 'finished' then new.finished86:=now(); end if;
 return new;
end;
$$;
drop trigger if exists ls_stamp86 on public.ls_arena63;
create trigger ls_stamp86 before update on public.ls_arena63 for each row execute function public.ls_stamp86();
create or replace function public.ls_weekly86() returns uuid language sql stable security definer set search_path='' as $$
with people as (select auth.uid() as uid where auth.uid() is not null union select f.peer from public.ls_friends() f where f.accepted and auth.uid() is not null),
cutoff as (select date_trunc('week',now() at time zone 'Europe/Berlin') at time zone 'Europe/Berlin' as stamp),
scores as (select p.uid,greatest(0,coalesce(sum(case when t.winner=p.uid then 25 when t.winner is not null then -10 else 0 end),0)) as points,count(*) filter(where t.winner=p.uid) as wins from people p cross join cutoff c left join public.ls_arena63 t on p.uid in(t.a,t.b) and t.mode='ranked' and t.status='finished' and t.finished86<c.stamp group by p.uid)
select uid from scores where wins>0 order by points desc,wins desc,uid limit 1
$$;
revoke all on function public.ls_weekly86() from public,anon;
grant execute on function public.ls_weekly86() to authenticated;
notify pgrst,'reload schema';
commit;
