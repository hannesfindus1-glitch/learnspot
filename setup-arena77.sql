begin;
alter table public.ls_arena63 add column if not exists resolved_a73 text, add column if not exists resolved_b73 text;
alter table public.ls_arena63 add column if not exists energy_a int not null default 1, add column if not exists energy_b int not null default 1, add column if not exists xp72 boolean not null default false;
alter table public.ls_arena63 add column if not exists move_a text, add column if not exists move_b text;
update public.ls_arena63 set turn=null where mode='classic' and status='active' and move_a is null and move_b is null;
create or replace function public.ls_arena_list63() returns setof jsonb language sql security definer set search_path='' as $$ select (to_jsonb(t)-'deck'-'move_a'-'move_b') || jsonb_build_object('question',case when t.status='active' then t.deck->(t.round % greatest(1,jsonb_array_length(t.deck)))->'q' end) from public.ls_arena63 t where auth.uid() in(t.a,t.b) order by id desc $$;
create or replace function public.ls_arena_join63(bid bigint,pet text,lvl int,accept boolean) returns void language plpgsql security definer set search_path='' as $$ begin update public.ls_arena63 set turn=null,pb=pet,lb=greatest(1,least(5,lvl)),ha=case when mode='classic' then 100+5*(greatest(1,least(5,la))-1) else 100 end,hb=case when mode='classic' then 100+5*(greatest(1,least(5,lvl))-1) else 100 end,status=case when accept then 'active' else 'declined' end where id=bid and b=auth.uid() and status='pending'; end $$;
create or replace function public.ls_damage72(m text,op text) returns int language sql immutable set search_path='' as $$ select case m when 'attack' then case op when 'guard' then 0 when 'special' then 28 else 16 end when 'guard' then case op when 'attack' then 28 else 0 end when 'special' then case op when 'attack' then 0 when 'guard' then 28 else 16 end else 0 end $$;
create or replace function public.ls_damage77(m text,op text,att int,def int) returns int language sql immutable set search_path='' as $$ select case when public.ls_damage72(m,op)=0 then 0 else greatest(1,round((public.ls_damage72(m,op)+greatest(0,least(4,att-1)))*(1-0.02*greatest(0,least(4,def-1))))::int end $$;
create or replace function public.ls_arena_act63(bid bigint,expected int,action text,answer text) returns void language plpgsql security definer set search_path='' as $$ declare t public.ls_arena63%rowtype; me uuid:=auth.uid(); dmg int; begin select * into t from public.ls_arena63 where id=bid and me in(a,b) for update; if not found or t.status<>'active' or (t.seq<>expected and not (t.mode='classic' and t.seq=expected+1 and t.turn is not null and t.turn<>me)) then return; end if; if action='quit' then t.winner:=case when me=t.a then t.b else t.a end; elsif t.mode='classic' then
if action not in ('attack','special','guard') or t.turn=me then return; end if;

if me=t.a then t.move_a:=action; else t.move_b:=action; end if;
if t.move_a is null or t.move_b is null then
update public.ls_arena63 set move_a=t.move_a,move_b=t.move_b,turn=me,seq=t.seq+1,last_actor=null,last_action=null where id=bid; return;
end if;
-- Simultaneous counter system. Attack interrupts special, special breaks guard, guard counters attack.
t.ha:=greatest(0,t.ha-public.ls_damage77(t.move_b,t.move_a,t.lb,t.la));
t.hb:=greatest(0,t.hb-public.ls_damage77(t.move_a,t.move_b,t.la,t.lb));
t.energy_a:=1;
t.energy_b:=1;
t.resolved_a73:=t.move_a;t.resolved_b73:=t.move_b;t.round:=t.round+1;t.turn:=null;t.move_a:=null;t.move_b:=null;
else t.resolved_a73:=case when me=t.a then 'answer' end;t.resolved_b73:=case when me=t.b then 'answer' end; if action<>'answer' or lower(trim(answer)) is distinct from lower(trim(t.deck->(t.round % jsonb_array_length(t.deck))->>'a')) then raise exception 'Antwort nicht richtig'; end if; if me=t.a then t.hb:=greatest(0,t.hb-20); else t.ha:=greatest(0,t.ha-20); end if; t.round:=t.round+1; end if; if t.ha=0 and t.hb=0 then t.winner:=null; elsif t.ha=0 then t.winner:=t.b; elsif t.hb=0 then t.winner:=t.a; end if; update public.ls_arena63 set resolved_a73=t.resolved_a73,resolved_b73=t.resolved_b73,xp72=(action<>'quit' and t.winner is not null),energy_a=t.energy_a,energy_b=t.energy_b,move_a=t.move_a,move_b=t.move_b,ha=t.ha,hb=t.hb,round=t.round,turn=t.turn,winner=t.winner,status=case when t.winner is null and t.ha>0 and t.hb>0 then 'active' else 'finished' end,last_actor=me,last_action=action,seq=t.seq+1 where id=bid; end $$;

notify pgrst, 'reload schema';
commit;
