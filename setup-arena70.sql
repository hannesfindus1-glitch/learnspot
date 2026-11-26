begin;
alter table public.ls_arena63 add column if not exists move_a text, add column if not exists move_b text;
update public.ls_arena63 set turn=null where mode='classic' and status='active' and move_a is null and move_b is null;
create or replace function public.ls_arena_list63() returns setof jsonb language sql security definer set search_path='' as $$ select (to_jsonb(t)-'deck'-'move_a'-'move_b') || jsonb_build_object('question',case when t.status='active' then t.deck->(t.round % greatest(1,jsonb_array_length(t.deck)))->'q' end) from public.ls_arena63 t where auth.uid() in(t.a,t.b) order by id desc $$;
create or replace function public.ls_arena_join63(bid bigint,pet text,lvl int,accept boolean) returns void language plpgsql security definer set search_path='' as $$ begin update public.ls_arena63 set turn=null,pb=pet,lb=greatest(1,least(5,lvl)),status=case when accept then 'active' else 'declined' end where id=bid and b=auth.uid() and status='pending'; end $$;
create or replace function public.ls_arena_act63(bid bigint,expected int,action text,answer text) returns void language plpgsql security definer set search_path='' as $$ declare t public.ls_arena63%rowtype; me uuid:=auth.uid(); dmg int; begin select * into t from public.ls_arena63 where id=bid and me in(a,b) for update; if not found or t.status<>'active' or t.seq<>expected then return; end if; if action='quit' then t.winner:=case when me=t.a then t.b else t.a end; elsif t.mode='classic' then
if action not in ('attack','special','guard') or t.turn=me then return; end if;
if me=t.a then t.move_a:=action; else t.move_b:=action; end if;
if t.move_a is null or t.move_b is null then
update public.ls_arena63 set move_a=t.move_a,move_b=t.move_b,turn=me,seq=t.seq+1,last_actor=null,last_action=null where id=bid; return;
end if;
-- Symmetric simultaneous damage; special available every third round, guard halves damage.
t.ha:=greatest(0,t.ha-(case when t.move_b='guard' then 0 when t.move_b='special' and t.round%3=0 then 28 else 18 end)/(case when t.move_a='guard' then 2 else 1 end));
t.hb:=greatest(0,t.hb-(case when t.move_a='guard' then 0 when t.move_a='special' and t.round%3=0 then 28 else 18 end)/(case when t.move_b='guard' then 2 else 1 end));
t.round:=t.round+1;t.turn:=null;t.move_a:=null;t.move_b:=null;
else if action<>'answer' or lower(trim(answer)) is distinct from lower(trim(t.deck->(t.round % jsonb_array_length(t.deck))->>'a')) then raise exception 'Antwort nicht richtig'; end if; if me=t.a then t.hb:=greatest(0,t.hb-20); else t.ha:=greatest(0,t.ha-20); end if; t.round:=t.round+1; end if; if t.ha=0 and t.hb=0 then t.winner:=null; elsif t.ha=0 then t.winner:=t.b; elsif t.hb=0 then t.winner:=t.a; end if; update public.ls_arena63 set move_a=t.move_a,move_b=t.move_b,ha=t.ha,hb=t.hb,round=t.round,turn=t.turn,winner=t.winner,status=case when t.winner is null and t.ha>0 and t.hb>0 then 'active' else 'finished' end,last_actor=me,last_action=action,seq=t.seq+1 where id=bid; end $$;

notify pgrst, 'reload schema';
commit;
