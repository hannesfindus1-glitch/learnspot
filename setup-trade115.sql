begin;
create table if not exists public.ls_genesis_items115(id uuid primary key default gen_random_uuid(), owner uuid not null references auth.users(id) on delete cascade, design jsonb not null, created_at timestamptz default now());
create table if not exists public.ls_genesis_offers115(id uuid primary key default gen_random_uuid(), sender uuid not null references auth.users(id), recipient uuid not null references auth.users(id), offered uuid not null, requested uuid not null, status text not null default 'pending', created_at timestamptz default now());
alter table public.ls_genesis_items115 enable row level security;
alter table public.ls_genesis_offers115 enable row level security;
revoke all on public.ls_genesis_items115,public.ls_genesis_offers115 from anon,authenticated;
create or replace function public.ls_trade_items115(peer uuid default null) returns setof public.ls_genesis_items115 language sql security definer set search_path='' as $$ select i.* from public.ls_genesis_items115 i where auth.uid() is not null and (i.owner=auth.uid() or (i.owner=peer and exists(select 1 from public.ls_connections c where c.accepted and ((c.sender=auth.uid() and c.recipient=peer) or (c.recipient=auth.uid() and c.sender=peer))))) $$;
create or replace function public.ls_trade_mint115(design jsonb) returns uuid language plpgsql security definer set search_path='' as $$ declare result uuid; o jsonb; begin
if auth.uid() is null or jsonb_typeof(design) is distinct from 'array' or octet_length(design::text)>6000 then raise exception 'Ungültiges Design'; end if;
if jsonb_array_length(design) not between 1 and 6 then raise exception 'Ungültiges Design'; end if;
foreach o in array array(select jsonb_array_elements(design)) loop
if coalesce(o->>'color','') !~ '^#[0-9a-fA-F]{6}$' or not (o ?& array['shape','size','x','y','angle','rings']) then raise exception 'Ungültiges Objekt'; end if;
if (o->>'shape')::int not between 0 and 2 or (o->>'size')::int not between 25 and 100 or (o->>'x')::int not between -120 and 120 or (o->>'y')::int not between -85 and 85 or (o->>'angle')::int not between 0 and 360 or (o->>'rings')::int not between 0 and 6 then raise exception 'Ungültiges Objekt'; end if;
end loop;
perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,115));
if (select count(*) from public.ls_genesis_items115 where owner=auth.uid())>=50 then raise exception 'Sammlung voll'; end if;
insert into public.ls_genesis_items115(owner,design) values(auth.uid(),design) returning id into result; return result; end $$;
create or replace function public.ls_trade_offer115(peer uuid, give_id uuid, take_id uuid) returns void language plpgsql security definer set search_path='' as $$ begin
if auth.uid() is null or peer=auth.uid() or not exists(select 1 from public.ls_connections c where c.accepted and ((c.sender=auth.uid() and c.recipient=peer) or (c.recipient=auth.uid() and c.sender=peer))) then raise exception 'Nur bestätigte Freunde'; end if;
if not exists(select 1 from public.ls_genesis_items115 where id=give_id and owner=auth.uid()) or not exists(select 1 from public.ls_genesis_items115 where id=take_id and owner=peer) then raise exception 'Gegenstand nicht verfügbar'; end if;
insert into public.ls_genesis_offers115(sender,recipient,offered,requested) values(auth.uid(),peer,give_id,take_id); end $$;
create or replace function public.ls_trade_list115() returns table(id uuid,sender uuid,recipient uuid,status text,give_design jsonb,take_design jsonb) language sql security definer set search_path='' as $$ select o.id,o.sender,o.recipient,o.status,a.design,b.design from public.ls_genesis_offers115 o join public.ls_genesis_items115 a on a.id=o.offered join public.ls_genesis_items115 b on b.id=o.requested where auth.uid() in(o.sender,o.recipient) order by o.created_at desc limit 100 $$;
create or replace function public.ls_trade_decide115(offer_id uuid, decision text) returns void language plpgsql security definer set search_path='' as $$ declare o public.ls_genesis_offers115%rowtype; begin
select * into o from public.ls_genesis_offers115 where id=offer_id for update;
if auth.uid() is null or o.id is null or o.status<>'pending' or decision not in ('accept','reject','cancel') or (decision='cancel' and auth.uid()<>o.sender) or (decision<>'cancel' and auth.uid()<>o.recipient) then raise exception 'Aktion nicht erlaubt'; end if;
if decision='accept' then
perform 1 from public.ls_genesis_items115 where id in(o.offered,o.requested) order by id for update;
if not exists(select 1 from public.ls_genesis_items115 where id=o.offered and owner=o.sender) or not exists(select 1 from public.ls_genesis_items115 where id=o.requested and owner=o.recipient) then raise exception 'Gegenstand inzwischen getauscht'; end if;
update public.ls_genesis_items115 set owner=case when id=o.offered then o.recipient else o.sender end where id in(o.offered,o.requested);
end if;
update public.ls_genesis_offers115 set status=decision where id=offer_id; end $$;
revoke execute on function public.ls_trade_items115(uuid),public.ls_trade_mint115(jsonb),public.ls_trade_offer115(uuid,uuid,uuid),public.ls_trade_list115(),public.ls_trade_decide115(uuid,text) from public,anon;
grant execute on function public.ls_trade_items115(uuid),public.ls_trade_mint115(jsonb),public.ls_trade_offer115(uuid,uuid,uuid),public.ls_trade_list115(),public.ls_trade_decide115(uuid,text) to authenticated;
commit;
