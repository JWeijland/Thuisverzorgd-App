-- Vangnet voor het directe antwoord.
--
-- De eerste versie eiste dat álle inhoudswoorden van de vraag in één onderdeel
-- voorkomen. Dat is precies, maar echte vragen bevatten ruis: "mag mijn vader
-- nog autorijden" gaat over autorijden, niet over vaders. Daarom nu:
--  1. familie- en aanspreekwoorden tellen niet mee als zoekwoord;
--  2. vindt de strenge alle-woorden-zoektocht niets, dan volstaat een ruime
--     meerderheid (60 procent) van de woorden op moduleniveau, en tonen we
--     het best passende onderdeel uit die module.
-- De volgorde blijft: eerst het precieze antwoord, pas daarna het vangnet.

create or replace function public.wegwijzer_antwoord(p_vraag text, p_limiet integer default 3)
returns table (
  sectie_id uuid,
  module_id uuid,
  module_slug text,
  module_titel text,
  thema text,
  thema_slug text,
  thema_kleur text,
  soort text,
  titel text,
  antwoord text,
  wetten text[],
  bronnen jsonb,
  score real
)
language plpgsql stable set search_path = public, extensions as $$
declare
  v_schoon text := lower(trim(coalesce(p_vraag, '')));
  v_woorden text[];
  v_tsq tsquery;
  v_of tsquery;
begin
  if length(v_schoon) < 3 then
    return;
  end if;

  -- Inhoudswoorden: minimaal drie tekens, zonder familie- en aanspreekwoorden.
  select array_agg(distinct w) into v_woorden
  from unnest(regexp_split_to_array(v_schoon, '[^[:alnum:]]+')) as w
  where length(w) >= 3
    and w not in (
      'vader', 'moeder', 'ouder', 'ouders', 'man', 'vrouw', 'zoon', 'dochter',
      'broer', 'zus', 'zusje', 'broertje', 'partner', 'opa', 'oma',
      'schoonvader', 'schoonmoeder', 'vriend', 'vriendin', 'buurman',
      'buurvrouw', 'iemand', 'mijn', 'onze', 'zijn', 'haar'
    );
  if v_woorden is null then
    return;
  end if;

  -- Strenge variant: alle woorden, met prefix-matching.
  begin
    v_tsq := to_tsquery('dutch'::regconfig,
      (select string_agg(w || ':*', ' & ') from unnest(v_woorden) as w));
  exception when others then
    v_tsq := plainto_tsquery('dutch'::regconfig, v_schoon);
  end;

  if v_tsq is not null then
    return query
    with kandidaten as (
      select s.id, s.module_id as mid, s.soort as ssoort, s.titel as stitel, s.body,
        (
          ts_rank(s.zoek, v_tsq)
          + ts_rank(m.zoek, v_tsq) * 0.5
          + case when s.soort = 'vraag' then 0.02 else 0 end
        )::real as sscore
      from public.guide_sections s
      join public.guide_modules m on m.id = s.module_id
      where m.published and s.zoek @@ v_tsq
    ),
    beste as (select coalesce(max(k.sscore), 0)::real as top from kandidaten k)
    select k.id, m.id, m.slug, m.titel, t.titel, t.slug, t.kleur,
      k.ssoort, k.stitel, k.body, m.wetten,
      coalesce((select jsonb_agg(jsonb_build_object('titel', l.titel, 'url', l.url) order by l.sortering)
                from public.guide_links l where l.module_id = m.id), '[]'::jsonb),
      k.sscore
    from kandidaten k
    cross join beste b
    join public.guide_modules m on m.id = k.mid
    join public.guide_themes t on t.id = m.theme_id
    where t.published and k.sscore >= b.top * 0.4
    order by k.sscore desc
    limit greatest(least(coalesce(p_limiet, 3), 5), 1);
    if found then
      return;
    end if;
  end if;

  -- Vangnet: een ruime meerderheid van de woorden moet in de module voorkomen.
  begin
    v_of := to_tsquery('dutch'::regconfig,
      (select string_agg(w || ':*', ' | ') from unnest(v_woorden) as w));
  exception when others then
    v_of := null;
  end;
  if v_of is null then
    return;
  end if;

  return query
  with woorden as (
    select w from unnest(v_woorden) as w
    where numnode(to_tsquery('dutch'::regconfig, w || ':*')) > 0
  ),
  moduletreffers as (
    select m.id as mid,
      count(*) filter (where m.zoek @@ to_tsquery('dutch'::regconfig, wo.w || ':*'))::real
        / greatest(count(*), 1) as fractie
    from public.guide_modules m
    cross join woorden wo
    where m.published
    group by m.id
  ),
  kandidaten as (
    select distinct on (s.module_id)
      s.id, s.module_id as mid, s.soort as ssoort, s.titel as stitel, s.body,
      ((ts_rank(s.zoek, v_of) + ts_rank(m.zoek, v_of) * 0.5
        + case when s.soort = 'vraag' then 0.02 else 0 end) * mt.fractie)::real as sscore
    from moduletreffers mt
    join public.guide_modules m on m.id = mt.mid
    join public.guide_sections s on s.module_id = m.id
    where mt.fractie >= 0.6 and s.zoek @@ v_of
    order by s.module_id,
      (ts_rank(s.zoek, v_of) + case when s.soort = 'vraag' then 0.02 else 0 end) desc
  ),
  beste as (select coalesce(max(k.sscore), 0)::real as top from kandidaten k)
  select k.id, m.id, m.slug, m.titel, t.titel, t.slug, t.kleur,
    k.ssoort, k.stitel, k.body, m.wetten,
    coalesce((select jsonb_agg(jsonb_build_object('titel', l.titel, 'url', l.url) order by l.sortering)
              from public.guide_links l where l.module_id = m.id), '[]'::jsonb),
    k.sscore
  from kandidaten k
  cross join beste b
  join public.guide_modules m on m.id = k.mid
  join public.guide_themes t on t.id = m.theme_id
  where t.published and k.sscore >= b.top * 0.5
  order by k.sscore desc
  limit greatest(least(coalesce(p_limiet, 3), 5), 1);
end;
$$;

revoke execute on function public.wegwijzer_antwoord(text, integer) from public, anon;
grant execute on function public.wegwijzer_antwoord(text, integer) to authenticated;
