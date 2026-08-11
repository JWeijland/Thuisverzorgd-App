-- De wegwijzer beantwoordt vragen nu met AI, gevoed door de eigen kennisbank
-- (feedback Jelle 11-08: het oude, extractieve antwoord was niet accuraat).
--
-- Deze functie doet alleen het ophalen: welke stukken tekst uit de kennisbank
-- gaan er over deze vraag? Het schrijven van het antwoord gebeurt in de edge
-- function `wegwijzer-ai`, die precies deze stukken meestuurt en het model
-- verbiedt er iets buiten te verzinnen. Zo staat er nooit een antwoord in de
-- app dat niet in onze eigen bronnen staat.

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
  with vraag as (
    select
      websearch_to_tsquery('dutch', p_vraag) as query,
      -- Losse woorden als vangnet: "mag mijn moeder bij mij wonen" levert
      -- met websearch_to_tsquery niets op als één woord niet voorkomt.
      plainto_tsquery('dutch', p_vraag) as ruime_query
  )
  select
    m.id,
    m.slug,
    m.titel,
    s.titel,
    s.body,
    m.wetten,
    greatest(
      ts_rank(s.zoek, v.query),
      ts_rank(s.zoek, v.ruime_query) * 0.8
    )::real as score
  from guide_sections s
  join guide_modules m on m.id = s.module_id
  join guide_themes t on t.id = m.theme_id
  cross join vraag v
  where m.published
    and t.published
    and (s.zoek @@ v.query or s.zoek @@ v.ruime_query)
  order by score desc
  limit greatest(1, least(p_limiet, 20));
$$;

revoke all on function public.wegwijzer_context(text, integer) from public, anon;
grant execute on function public.wegwijzer_context(text, integer) to authenticated;

comment on function public.wegwijzer_context(text, integer) is
  'Haalt de stukken kennisbank op die over een vraag gaan; voedt de edge function wegwijzer-ai.';
