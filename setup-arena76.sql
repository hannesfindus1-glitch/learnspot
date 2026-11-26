begin;
create or replace function public.ls_arena_join63(bid bigint,pet text,lvl int,accept boolean) returns void language plpgsql security definer set search_path='' as $$ begin update public.ls_arena63 set turn=null,pb=pet,lb=greatest(1,least(5,lvl)),ha=case when mode='classic' then 100+5*(greatest(1,least(5,la))-1) else 100 end,hb=case when mode='classic' then 100+5*(greatest(1,least(5,lvl))-1) else 100 end,status=case when accept then 'active' else 'declined' end where id=bid and b=auth.uid() and status='pending'; end $$;
notify pgrst, 'reload schema';
commit;
