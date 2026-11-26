create or replace function public.ls_friend_pet(peer_id uuid) returns jsonb language sql stable security definer set search_path='' as $$
select jsonb_build_object('id',s.data->'petSystem'->>'active','level',1+floor(coalesce((s.data->'petSystem'->'xp'->>(s.data->'petSystem'->>'active'))::numeric,0)/100)) from public.learnspot_state s where s.user_id=peer_id and exists(select 1 from public.ls_connections c where c.accepted and ((c.sender=auth.uid() and c.recipient=peer_id) or (c.recipient=auth.uid() and c.sender=peer_id))) $$;
revoke all on function public.ls_friend_pet(uuid) from public,anon;
grant execute on function public.ls_friend_pet(uuid) to authenticated;
notify pgrst, 'reload schema';
