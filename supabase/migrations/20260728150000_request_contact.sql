-- Fase 6: contactgegevens bij een actieve directe hulpvraag.
-- De aanvrager mag naam + telefoon van de geaccepteerde helper zien ("Tim is onderweg"),
-- en andersom; alleen zolang de aanvraag loopt of net is afgerond.

create or replace function public.get_request_contact(p_request uuid)
returns table (naam text, telefoon text)
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
    return query select p.name, p.phone from profiles p where p.id = r.helper_id;
  elsif auth.uid() = r.helper_id then
    return query select p.name, p.phone from profiles p where p.id = r.requester_id;
  else
    raise exception 'geen_toestemming';
  end if;
end;
$$;

-- Kaartviews krijgen lat/lon als getallen (geography is client-side onbruikbaar).
drop view if exists public.v_map_circles;
create view public.v_map_circles as
select id, name,
       st_y(location_rounded::geometry) as lat,
       st_x(location_rounded::geometry) as lon
from public.circles
where location_rounded is not null;
revoke all on public.v_map_circles from anon;

drop view if exists public.v_map_buddies;
create view public.v_map_buddies as
select id,
       split_part(name, ' ', 1) as voornaam,
       city,
       helped_count,
       st_y(location_rounded::geometry) as lat,
       st_x(location_rounded::geometry) as lon
from public.profiles
where role = 'vrijwilliger'
  and pool_opt_in
  and not vacation_mode
  and location_rounded is not null;
revoke all on public.v_map_buddies from anon;

drop view if exists public.v_open_requests;
create view public.v_open_requests as
select
  r.id,
  r.type,
  r.status,
  r.created_at,
  split_part(p.name, ' ', 1) as voornaam,
  st_y(r.location_rounded::geometry) as lat,
  st_x(r.location_rounded::geometry) as lon
from public.spontaneous_requests r
join public.profiles p on p.id = r.requester_id
where r.status in ('open', 'aanbod');
revoke all on public.v_open_requests from anon;

-- Locatie meegeven bij het plaatsen van een aanvraag (PostGIS-punt uit lat/lon).
create or replace function public.create_spontaneous_request(
  p_type public.request_type,
  p_note text default null,
  p_address text default null,
  p_lat double precision default null,
  p_lon double precision default null,
  p_circle uuid default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  -- één actieve aanvraag tegelijk (les uit de legacy-app)
  if exists (
    select 1 from spontaneous_requests
    where requester_id = auth.uid() and status in ('open', 'aanbod', 'onderweg')
  ) then
    raise exception 'al_actieve_aanvraag';
  end if;

  insert into spontaneous_requests (requester_id, circle_id, type, note, address, location)
  values (
    auth.uid(), p_circle, p_type, p_note, p_address,
    case when p_lat is not null and p_lon is not null
      then st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography
      else null end
  )
  returning id into v_id;
  return v_id;
end;
$$;
