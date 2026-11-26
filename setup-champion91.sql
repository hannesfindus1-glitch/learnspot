create or replace function public.ls_champion91() returns uuid language sql stable security definer set search_path='' as $$
select peer from public.ls_global88() where points>=800 order by points desc,wins desc,peer limit 1
$$;
revoke all on function public.ls_champion91() from public,anon;
grant execute on function public.ls_champion91() to authenticated;
notify pgrst,'reload schema';
