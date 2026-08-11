-- De eerste versie van `wegwijzer_context` deed zijn eigen tekstzoekopdracht en
-- was daardoor slechter dan de zoekfunctie die de app al gebruikt: op "mag mijn
-- moeder bij mij in huis wonen" gaf hij nul treffers, en met een losse
-- OR-variant kwam "Steeds naar huis willen" bovenaan in plaats van de
-- mantelzorgwoning.
--
-- Deze versie leunt daarom op `search_wegwijzer`, dat al is afgesteld op
-- spreektaal, synoniemen (`zoektermen`) en typefouten. We nemen de best
-- scorende onderwerpen en geven de secties daarvan als context mee. Bijkomend
-- voordeel: het AI-antwoord baseert zich op dezelfde onderwerpen die de
-- gebruiker eronder in de resultaten ziet staan.

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
  with beste as (
    -- Hooguit drie onderwerpen: meer levert vooral ruis op, en elk onderwerp
    -- brengt al zijn eigen secties mee.
    select z.id, z.score
    from public.search_wegwijzer(p_vraag, 3) z
  )
  select
    m.id,
    m.slug,
    m.titel,
    s.titel,
    s.body,
    m.wetten,
    b.score
  from beste b
  join guide_modules m on m.id = b.id
  join guide_sections s on s.module_id = m.id
  order by b.score desc, s.sortering
  limit greatest(1, least(p_limiet, 20));
$$;

revoke all on function public.wegwijzer_context(text, integer) from public, anon;
grant execute on function public.wegwijzer_context(text, integer) to authenticated;

comment on function public.wegwijzer_context(text, integer) is
  'Secties van de best passende onderwerpen bij een vraag; voedt de edge function wegwijzer-ai.';
