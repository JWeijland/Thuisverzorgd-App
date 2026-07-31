-- Profielfoto's overal waar een persoon in beeld komt.
--
-- De avatars-bucket gaf al toegang tot de foto's die hier nodig zijn (eigen
-- foto, kringgenoten, makelaars en zichtbare pool-buddy's), maar de views en
-- de contact-RPC lieten het pad zelf weg. Zonder pad kon de app alleen de
-- initiaal-cirkel tonen. Geen nieuwe leesrechten: alleen het pad meegeven.

-- 1. Buddy-kaartje (best matches + aanbod op een directe hulpvraag).
drop view if exists public.v_buddy_cards;
create view public.v_buddy_cards as
select
  p.id,
  split_part(p.name, ' ', 1) as voornaam,
  p.city,
  p.helped_count,
  p.id_verified,
  p.avatar_path,
  (select round(avg(score)::numeric, 1) from public.reviews rv where rv.volunteer_id = p.id) as waardering,
  (select count(distinct cm.circle_id) from public.circle_members cm
     where cm.profile_id = p.id and cm.status = 'actief' and cm.member_role = 'vrijwilliger') as kringen,
  p.location_rounded
from public.profiles p
where p.role = 'vrijwilliger' and p.pool_opt_in;
revoke all on public.v_buddy_cards from anon;

-- 2. Beoordeel-scherm: de vrijwilliger die zich aanmeldt of is uitgenodigd.
drop view if exists public.v_invitation_detail;
create view public.v_invitation_detail as
select
  i.id,
  i.circle_id,
  i.kind,
  i.status,
  i.message,
  i.video_done,
  i.created_at,
  c.name as kring_naam,
  c.owner_id,
  i.profile_id,
  split_part(p.name, ' ', 1) as voornaam,
  p.city,
  p.helped_count,
  p.id_verified,
  p.avatar_path,
  (select round(avg(score)::numeric, 1) from public.reviews rv where rv.volunteer_id = p.id)
    as waardering,
  (select count(distinct cm.circle_id) from public.circle_members cm
     where cm.profile_id = p.id and cm.status = 'actief' and cm.member_role = 'vrijwilliger')
    as kringen
from public.invitations i
join public.circles c on c.id = i.circle_id
left join public.profiles p on p.id = i.profile_id
where i.profile_id = auth.uid()
   or i.invited_by = auth.uid()
   or c.owner_id = auth.uid();
revoke all on public.v_invitation_detail from anon;

-- 3. Contactgegevens bij een lopende directe hulpvraag: foto erbij, zodat de
--    aanvrager het gezicht ziet van wie onderweg is. Return-type wijzigt, dus
--    eerst droppen (create or replace kan dat niet).
drop function if exists public.get_request_contact(uuid);
create function public.get_request_contact(p_request uuid)
returns table (naam text, telefoon text, avatar_path text)
language plpgsql security definer set search_path = public as $$
declare
  r record;
begin
  select requester_id, helper_id, status into r
  from spontaneous_requests
  where id = p_request and status in ('onderweg', 'afgerond');

  if r is null then
    raise exception 'geen_toestemming';
  end if;

  if auth.uid() = r.requester_id then
    return query select p.name, p.phone, p.avatar_path from profiles p where p.id = r.helper_id;
  elsif auth.uid() = r.helper_id then
    return query select p.name, p.phone, p.avatar_path from profiles p where p.id = r.requester_id;
  else
    raise exception 'geen_toestemming';
  end if;
end;
$$;
