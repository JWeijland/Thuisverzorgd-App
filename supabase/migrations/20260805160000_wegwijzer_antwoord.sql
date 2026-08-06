-- Direct antwoord in de Wegwijzer-zoekbalk.
--
-- Wie een vraag typt ("hoe vraag ik zorgverlof aan") wil geen lijst met
-- onderwerpen, maar het antwoord zelf. Dat antwoord staat er al: elke module
-- bestaat uit onderdelen (guide_sections) die precies zo'n vraag behandelen.
-- Deze functie zoekt het onderdeel dat de vraag het best beantwoordt en geeft
-- het terug mét de onderbouwing: het onderwerp waar het uit komt, de
-- wettelijke basis en de externe bronnen van dat onderwerp.
--
-- Waarom dit zonder taalmodel kan: wegwijzer_tsquery plakt alle betekenisvolle
-- woorden met & aan elkaar en de Nederlandse tekstconfiguratie gooit
-- vraagwoorden ("hoe", "wat", "kan", "moet") als stopwoorden weg. Een onderdeel
-- komt dus alleen terug als álle inhoudswoorden van de vraag erin voorkomen.
-- Dat maakt elk gevonden antwoord betrouwbaar; vinden we niets, dan toont de
-- app gewoon de zoekresultaten en de stap naar de hulpmakelaar.

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
  v_tsq tsquery := public.wegwijzer_tsquery(p_vraag);
  v_schoon text := lower(trim(coalesce(p_vraag, '')));
begin
  -- Vanaf drie tekens; bij één los woord is de gewone zoeklijst nuttiger
  -- dan een "antwoord", dus dan zwijgt deze functie ook.
  if v_tsq is null or length(v_schoon) < 3 then
    return;
  end if;

  return query
  with kandidaten as (
    select
      s.id,
      s.module_id,
      s.soort,
      s.titel,
      s.body,
      (
        ts_rank(s.zoek, v_tsq)
        -- het moduleniveau telt mee: een treffer in een module die als geheel
        -- over de vraag gaat, wint van een zijdelingse vermelding elders
        + ts_rank(m.zoek, v_tsq) * 0.5
        -- veelgestelde vragen zijn geschreven als antwoord; kleine voorsprong
        + case when s.soort = 'vraag' then 0.02 else 0 end
      )::real as score
    from public.guide_sections s
    join public.guide_modules m on m.id = s.module_id
    where m.published and s.zoek @@ v_tsq
  ),
  beste as (
    select coalesce(max(k.score), 0)::real as top from kandidaten k
  )
  select
    k.id as sectie_id,
    m.id as module_id,
    m.slug as module_slug,
    m.titel as module_titel,
    t.titel as thema,
    t.slug as thema_slug,
    t.kleur as thema_kleur,
    k.soort,
    k.titel,
    k.body as antwoord,
    m.wetten,
    coalesce(
      (select jsonb_agg(jsonb_build_object('titel', l.titel, 'url', l.url) order by l.sortering)
       from public.guide_links l where l.module_id = m.id),
      '[]'::jsonb
    ) as bronnen,
    k.score
  from kandidaten k
  cross join beste b
  join public.guide_modules m on m.id = k.module_id
  join public.guide_themes t on t.id = m.theme_id
  where t.published
    -- zwakke tweede antwoorden weglaten: alles onder 40% van de beste valt af
    and k.score >= b.top * 0.4
  order by k.score desc
  limit greatest(least(coalesce(p_limiet, 3), 5), 1);
end;
$$;

-- Zelfde slot als de andere Wegwijzer-functies: alleen ingelogde gebruikers.
revoke execute on function public.wegwijzer_antwoord(text, integer) from public, anon;
grant execute on function public.wegwijzer_antwoord(text, integer) to authenticated;
