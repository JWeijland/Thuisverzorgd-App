-- Feedbackronde 29-07 (deel 3):
-- 1. Directe hulp kent nu ook "Anders": de aanvrager typt zelf wat er nodig is;
--    die omschrijving (note) is zichtbaar voor buddy's op de kaart.
-- 2. Buddy's op de kaart krijgen hun profielfoto (in plaats van een initiaal).

-- 1a. Nieuw aanvraagtype.
alter type public.request_type add value if not exists 'anders';

-- 1b. De omschrijving meegeven aan de kaart-view (adres blijft verborgen).
drop view if exists public.v_open_requests;
create view public.v_open_requests as
select
  r.id,
  r.type,
  r.status,
  r.created_at,
  r.note,
  split_part(p.name, ' ', 1) as voornaam,
  st_y(r.location_rounded::geometry) as lat,
  st_x(r.location_rounded::geometry) as lon
from public.spontaneous_requests r
join public.profiles p on p.id = r.requester_id
where r.status in ('open', 'aanbod');
revoke all on public.v_open_requests from anon;

-- 2a. Foto-pad meegeven aan de buddy-kaartview.
drop view if exists public.v_map_buddies;
create view public.v_map_buddies as
select id,
       split_part(name, ' ', 1) as voornaam,
       city,
       helped_count,
       avatar_path,
       st_y(location_rounded::geometry) as lat,
       st_x(location_rounded::geometry) as lon
from public.profiles
where role = 'vrijwilliger'
  and pool_opt_in
  and not vacation_mode
  and location_rounded is not null;
revoke all on public.v_map_buddies from anon;

-- 2b. Foto's van buddy's die zichtbaar op de kaart staan (pool aan, niet met
--     vakantie) mogen door ingelogde gebruikers gelezen worden.
create policy "avatars pool-buddys lezen" on storage.objects
  for select
  using (
    bucket_id = 'avatars'
    and exists (
      select 1 from public.profiles pr
      where pr.id::text = (storage.foldername(name))[1]
        and pr.role = 'vrijwilliger'
        and pr.pool_opt_in
        and not pr.vacation_mode
    )
  );
