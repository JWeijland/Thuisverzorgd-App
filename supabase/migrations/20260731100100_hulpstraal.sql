-- Hulpstraal (feedback 31-07): binnen welke afstand wil een vrijwilliger hulp
-- verlenen? Tot nu toe zag iedereen élke spontane hulpvraag en élke kring op de
-- kaart, ook aan de andere kant van het land. Nu bepaalt de vrijwilliger dat
-- zelf, met 300 meter als standaard: hulp uit de eigen straat.
--
-- De straal staat naast de twee schakelaars die er al waren en werkt alleen
-- als die aan staan: `spontaneous_available` voor spontane hulpvragen,
-- `pool_opt_in` om als buddy vindbaar te zijn voor een kring. Staat een
-- schakelaar uit, dan verandert de straal daar niets aan.
--
-- Gerekend wordt met `location_rounded` (~1 km vervaagd), nooit met het exacte
-- adres. Bij een kleine straal is dat merkbaar grof; daarom telt een aanvraag
-- mee zodra hij binnen de straal plus die vervagingsmarge valt, zodat je een
-- buurvrouw niet misloopt door de afronding.

alter table public.profiles
  add column if not exists help_radius_m integer not null default 300
    check (help_radius_m between 100 and 50000);

comment on column public.profiles.help_radius_m is
  'Straal in meters waarbinnen deze vrijwilliger hulp wil verlenen (standaard 300).';

-- Marge voor de locatievervaging: coördinaten zijn op 2 decimalen afgerond,
-- goed voor ruim een kilometer speling.
create or replace function public.hulpstraal_marge_m()
returns integer language sql immutable parallel safe as $$
  select 1200;
$$;

/**
 * Valt `p_punt` binnen de hulpstraal van `p_profiel`? Zonder locatie (bij de
 * kijker of bij het punt) geven we true terug: liever iets te veel tonen dan
 * iemand met een leeg scherm laten zitten.
 */
create or replace function public.binnen_hulpstraal(p_profiel uuid, p_punt geography)
returns boolean
language sql stable security definer set search_path = public as $$
  select case
    when p_punt is null then true
    else coalesce(
      (select p.location_rounded is null
              or st_dwithin(p.location_rounded, p_punt,
                            p.help_radius_m + public.hulpstraal_marge_m())
       from profiles p where p.id = p_profiel),
      true)
  end;
$$;

-- ---------------------------------------------------------------------------
-- Spontane hulpvragen: alleen binnen je straal
-- ---------------------------------------------------------------------------
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
where r.status in ('open', 'aanbod')
  -- je eigen aanvraag zie je altijd, hoe ver je ook van jezelf af staat
  and (r.requester_id = auth.uid() or public.binnen_hulpstraal(auth.uid(), r.location_rounded));
revoke all on public.v_open_requests from anon;

-- ---------------------------------------------------------------------------
-- Kringen op de kaart: alleen binnen je straal
-- ---------------------------------------------------------------------------
-- Een kring waar je lid van bent blijft altijd zichtbaar, ook als hij verderop
-- ligt: die heb je bewust gekozen.
drop view if exists public.v_map_circles;
create view public.v_map_circles as
select
  c.id,
  c.name,
  st_y(c.location_rounded::geometry) as lat,
  st_x(c.location_rounded::geometry) as lon,
  (select count(*)::int from public.tasks t
     where t.circle_id = c.id and t.status = 'open' and t.date >= current_date) as plekken_vrij
from public.circles c
where c.location_rounded is not null
  and (
    c.owner_id = auth.uid()
    or exists (
      select 1 from public.circle_members cm
      where cm.circle_id = c.id and cm.profile_id = auth.uid()
    )
    or public.binnen_hulpstraal(auth.uid(), c.location_rounded)
  );
revoke all on public.v_map_circles from anon;

-- ---------------------------------------------------------------------------
-- Andersom: een kring die buddy's zoekt, ziet alleen wie zo ver wil komen
-- ---------------------------------------------------------------------------
-- De straal gaat mee in de kaartjes, zodat de app kan filteren op de afstand
-- die hij toch al uitrekent. Zo krijgt een kring op 5 km geen buddy voorgesteld
-- die alleen in zijn eigen straat wil helpen.
drop view if exists public.v_buddy_cards;
create view public.v_buddy_cards as
select
  p.id,
  split_part(p.name, ' ', 1) as voornaam,
  p.city,
  p.helped_count,
  p.id_verified,
  p.avatar_path,
  p.help_radius_m,
  (select round(avg(score)::numeric, 1) from public.reviews rv where rv.volunteer_id = p.id) as waardering,
  (select count(distinct cm.circle_id) from public.circle_members cm
     where cm.profile_id = p.id and cm.status = 'actief' and cm.member_role = 'vrijwilliger') as kringen,
  p.location_rounded
from public.profiles p
where p.role = 'vrijwilliger' and p.pool_opt_in;
revoke all on public.v_buddy_cards from anon;

/**
 * Buddy's die een kring kan uitnodigen: alleen wie zich beschikbaar heeft
 * gesteld voor de pool én wiens eigen hulpstraal tot deze kring reikt. Het
 * rekenen gebeurt server-side, zodat vervaagde locaties de app niet in hoeven.
 */
create or replace function public.buddys_voor_kring(p_circle uuid, p_limiet integer default 5)
returns table (
  id uuid,
  voornaam text,
  city text,
  helped_count integer,
  waardering numeric,
  kringen integer,
  avatar_path text,
  afstand_km numeric
)
language sql stable security definer set search_path = public as $$
  select
    b.id,
    b.voornaam,
    b.city,
    b.helped_count,
    b.waardering,
    b.kringen,
    b.avatar_path,
    case
      when b.location_rounded is null or c.location_rounded is null then null
      else round((st_distance(b.location_rounded, c.location_rounded) / 1000)::numeric, 1)
    end as afstand_km
  from public.v_buddy_cards b
  cross join (select location_rounded from public.circles where id = p_circle) c
  where (public.is_circle_beheerder(p_circle) or public.is_circle_member(p_circle))
    and (
      b.location_rounded is null
      or c.location_rounded is null
      or st_dwithin(b.location_rounded, c.location_rounded,
                    b.help_radius_m + public.hulpstraal_marge_m())
    )
  order by b.helped_count desc
  limit greatest(p_limiet, 1);
$$;
revoke execute on function public.buddys_voor_kring(uuid, integer) from public, anon;
grant execute on function public.buddys_voor_kring(uuid, integer) to authenticated;

drop view if exists public.v_map_buddies;
create view public.v_map_buddies as
select id,
       split_part(name, ' ', 1) as voornaam,
       city,
       helped_count,
       avatar_path,
       help_radius_m,
       st_y(location_rounded::geometry) as lat,
       st_x(location_rounded::geometry) as lon
from public.profiles
where role = 'vrijwilliger'
  and pool_opt_in
  and not vacation_mode
  and location_rounded is not null;
revoke all on public.v_map_buddies from anon;
