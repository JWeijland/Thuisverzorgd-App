-- Losse kernwoorden vinden het juiste onderwerp veel beter dan een hele zin.
-- Gemeten op de echte kennisbank:
--   "hoe vraag ik wmo aan" -> Dagbesteding (mis)
--   "vraag wmo"            -> Dagbesteding (mis)
--   "wmo"                  -> Hulp aanvragen bij de gemeente, score 6,3 (raak)
--   "overbelast"           -> Overbelasting herkennen, score 6,7 (raak)
--
-- De zin-zoekopdracht is dus geen goede ingang, maar per woord wel. Deze
-- versie zoekt daarom op drie manieren en voegt de uitkomsten samen: de hele
-- vraag, de vraag zonder vraagwoorden, en elk kernwoord apart. De vier best
-- scorende onderwerpen gaan als context naar het model.
--
-- Bewust géén wijziging aan `search_wegwijzer` zelf: dat is de zoekfunctie van
-- de app en die doet het goed op zoektermen. Dit is een laag eromheen voor
-- hele vragen.

create or replace function public.wegwijzer_context(p_vraag text, p_limiet integer default 8)
returns table (
  module_id uuid,
  module_slug text,
  module_titel text,
  sectie_titel text,
  body text,
  wetten text[],
  score real
)
language sql
stable
security definer
set search_path = public
as $$
  with kern as (
    select public.wegwijzer_kernwoorden(p_vraag) as tekst
  ),
  woorden as (
    -- Alleen woorden van 4 letters of langer: kortere zijn zelden
    -- onderscheidend en leveren vooral ruis op.
    select distinct woord
    from kern k, unnest(string_to_array(k.tekst, ' ')) as woord
    where k.tekst is not null and length(woord) >= 4
    limit 6
  ),
  gevonden as (
    -- 1. De vraag zoals hij getypt is.
    select z.id, z.score from public.search_wegwijzer(p_vraag, 3) z
    union all
    -- 2. De vraag zonder vraagwoorden.
    select z.id, z.score
    from kern k
    cross join lateral public.search_wegwijzer(k.tekst, 3) z
    where k.tekst is not null
    union all
    -- 3. Elk kernwoord apart; dit vangt de gevallen waarin de zin het
    --    onderwerp verdunt. Iets lager gewogen dan een volledige treffer.
    select z.id, z.score * 0.9
    from woorden w
    cross join lateral public.search_wegwijzer(w.woord, 2) z
  ),
  beste as (
    select id, max(score) as score
    from gevonden
    group by id
    order by max(score) desc
    limit 4
  )
  select
    m.id,
    m.slug,
    m.titel,
    s.titel,
    s.body,
    m.wetten,
    b.score::real
  from beste b
  join guide_modules m on m.id = b.id
  join guide_sections s on s.module_id = m.id
  order by b.score desc, s.sortering
  limit greatest(1, least(p_limiet, 20));
$$;

revoke all on function public.wegwijzer_context(text, integer) from public, anon;
grant execute on function public.wegwijzer_context(text, integer) to authenticated;
