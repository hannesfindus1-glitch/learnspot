begin;
create or replace function public.ls_public_notes58(peer_id uuid)
returns table(subject_name text, material jsonb)
language sql stable security definer set search_path='' as $$
select s->>'name', jsonb_build_object('t',n->>'t','txt',n->>'txt','link',n->>'link','imgs',coalesce(n->'imgs','[]'::jsonb),'files',coalesce(n->'files','[]'::jsonb))
from public.learnspot_state st
cross join lateral jsonb_array_elements(st.data->'subjects') s
cross join lateral jsonb_array_elements(s->'notes') n
where st.user_id=peer_id and auth.uid() is not null
and n->'public58' = 'true'::jsonb
and exists(select 1 from public.ls_connections c where c.accepted and ((c.sender=auth.uid() and c.recipient=peer_id) or (c.recipient=auth.uid() and c.sender=peer_id)));
$$;
revoke all on function public.ls_public_notes58(uuid) from public,anon;
grant execute on function public.ls_public_notes58(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
