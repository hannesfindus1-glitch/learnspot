create table if not exists public.ls_shop64(user_id uuid primary key, owned text[] not null default '{}', equipped text);
alter table public.ls_shop64 enable row level security;
revoke all on public.ls_shop64 from anon,authenticated;
create or replace function public.ls_shop64_state() returns jsonb language sql security definer set search_path='' as $$
select jsonb_build_object('coins', greatest(0,(select coalesce(sum(case when mode='ranked' then 40 else 20 end),0) from public.ls_arena63 where winner=auth.uid() and status='finished')- (select coalesce(sum(case x when 'gold' then 100 when 'ice' then 150 when 'cosmic' then 200 when 'royal' then 800 when 'wings' then 1400 when 'title' then 2200 when 'halo' then 3200 else 0 end),0) from public.ls_shop64 s cross join lateral unnest(s.owned) x where s.user_id=auth.uid())), 'owned',coalesce((select owned from public.ls_shop64 where user_id=auth.uid()),'{}'::text[]),'equipped',(select equipped from public.ls_shop64 where user_id=auth.uid())) where auth.uid() is not null $$;
create or replace function public.ls_shop64_buy(item text) returns jsonb language plpgsql security definer set search_path='' as $$ declare price int; s public.ls_shop64%rowtype; begin
if auth.uid() is null then raise exception 'Anmelden'; end if;
price:=case item when 'gold' then 100 when 'ice' then 150 when 'cosmic' then 200 when 'royal' then 800 when 'wings' then 1400 when 'title' then 2200 when 'halo' then 3200 else null end;
if price is null then raise exception 'Unbekanntes Item'; end if;
insert into public.ls_shop64(user_id) values(auth.uid()) on conflict do nothing;
select * into s from public.ls_shop64 where user_id=auth.uid() for update;
if not item=any(s.owned) then if (public.ls_shop64_state()->>'coins')::int<price then raise exception 'Nicht genug Coins'; end if; update public.ls_shop64 set owned=array_append(owned,item),equipped=item where user_id=auth.uid(); else update public.ls_shop64 set equipped=case when equipped=item then null else item end where user_id=auth.uid(); end if;
return public.ls_shop64_state(); end $$;
revoke execute on function public.ls_shop64_state(),public.ls_shop64_buy(text) from public,anon;
grant execute on function public.ls_shop64_state(),public.ls_shop64_buy(text) to authenticated;
