-- Buddyprofiel bekijken voordat je iemand uitnodigt (wens Jelle 11-08).
--
-- Je ziet nu alleen een naam en twee getallen in de suggestielijst. Wie je bij
-- een kwetsbaar iemand thuis uitnodigt, wil je eerst kunnen bekijken: een
-- korte beschrijving in zijn eigen woorden, zijn waardering en wat hij al
-- gedaan heeft.
--
-- Er staat nog nergens zo'n beschrijving, dus die komt hier bij. Bewust vrije
-- tekst en optioneel: niemand is verplicht iets over zichzelf te schrijven.

alter table public.profiles add column if not exists bio text;

comment on column public.profiles.bio is
  'Korte beschrijving in eigen woorden, zichtbaar op je buddykaartje.';

-- 1. De beschrijving en het aantal beoordelingen mee in het buddy-kaartje.
drop view if exists public.v_buddy_cards cascade;
create view public.v_buddy_cards as
select
  p.id,
  split_part(p.name, ' ', 1) as voornaam,
  p.city,
  p.helped_count,
  p.id_verified,
  p.avatar_path,
  p.bio,
  p.availability,
  (select round(avg(score)::numeric, 1) from public.reviews rv where rv.volunteer_id = p.id)
    as waardering,
  (select count(*) from public.reviews rv where rv.volunteer_id = p.id) as beoordelingen,
  (select count(distinct cm.circle_id) from public.circle_members cm
     where cm.profile_id = p.id and cm.status = 'actief' and cm.member_role = 'vrijwilliger')
    as kringen,
  p.location_rounded,
  p.help_radius_m
from public.profiles p
where p.role = 'vrijwilliger' and p.pool_opt_in;
revoke all on public.v_buddy_cards from anon;
grant select on public.v_buddy_cards to authenticated;

-- 2. `buddys_voor_kring` geeft de beschrijving nu mee. Het return-type wijzigt,
--    dus eerst droppen: `create or replace` kan dat niet.
drop function if exists public.buddys_voor_kring(uuid, integer);
create function public.buddys_voor_kring(p_circle uuid, p_limiet integer default 5)
returns table (
  id uuid,
  voornaam text,
  city text,
  helped_count integer,
  waardering numeric,
  kringen integer,
  avatar_path text,
  bio text,
  afstand_km numeric
)
language sql stable security definer set search_path = public as $$
  select
    b.id,
    b.voornaam,
    b.city,
    b.helped_count,
    b.waardering,
    b.kringen::integer,
    b.avatar_path,
    b.bio,
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

-- 3. Eén buddy opvragen om zijn kaartje te tonen. Alleen wie in de pool zit
--    en zichtbaar is; geen adres, geen telefoonnummer, geen e-mail.
create or replace function public.buddy_profiel(p_buddy uuid)
returns table (
  id uuid,
  voornaam text,
  city text,
  bio text,
  helped_count integer,
  waardering numeric,
  beoordelingen integer,
  kringen integer,
  avatar_path text,
  id_verified boolean,
  availability text[]
)
language sql stable security definer set search_path = public as $$
  select
    b.id,
    b.voornaam,
    b.city,
    b.bio,
    b.helped_count,
    b.waardering,
    b.beoordelingen::integer,
    b.kringen::integer,
    b.avatar_path,
    b.id_verified,
    b.availability
  from public.v_buddy_cards b
  where b.id = p_buddy;
$$;
revoke execute on function public.buddy_profiel(uuid) from public, anon;
grant execute on function public.buddy_profiel(uuid) to authenticated;
