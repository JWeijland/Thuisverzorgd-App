-- Een hele vraag zoekt slechter dan de kern ervan. Gemeten op de echte
-- kennisbank: "wmo aanvragen" vindt "Hulp aanvragen bij de gemeente" met score
-- 8,0, maar "hoe vraag ik wmo aan" komt niet verder dan dagbesteding en
-- lotgenotencontact. De vraagwoorden verdunnen de zoekopdracht.
--
-- Daarom zoekt `wegwijzer_context` nu twee keer: op de vraag zoals hij is
-- getypt, en op de vraag zonder vraag- en vulwoorden. De onderwerpen uit beide
-- rondes gaan samen als context naar het model, met de beste score voorop.

/** De kern van een vraag: vraagwoorden en vulwoorden eruit. */
create or replace function public.wegwijzer_kernwoorden(p_vraag text)
returns text
language sql
immutable
set search_path = public
as $$
  select nullif(
    trim(regexp_replace(
      regexp_replace(
        lower(coalesce(p_vraag, '')),
        -- Vraagwoorden, voornaamwoorden en losse voorzetsels; alles wat in
        -- bijna elke vraag voorkomt en dus niets onderscheidt.
        '\m(hoe|wat|wie|waar|waarom|wanneer|welke|welk|kan|kun|kunnen|mag|moet|moeten|ik|je|jij|mijn|mij|me|we|wij|ons|onze|hij|zij|ze|het|de|een|is|zijn|was|word|wordt|worden|aan|van|voor|met|bij|op|in|te|om|dat|die|er|en|of|als|dan|nog|ook|wel|niet|maar)\M',
        ' ', 'g'
      ),
      '\s+', ' ', 'g'
    )),
    ''
  );
$$;

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
  gevonden as (
    select z.id, z.score from public.search_wegwijzer(p_vraag, 3) z
    union all
    select z.id, z.score
    from kern k
    cross join lateral public.search_wegwijzer(k.tekst, 3) z
    where k.tekst is not null and k.tekst <> lower(trim(p_vraag))
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

revoke all on function public.wegwijzer_kernwoorden(text) from public, anon;
revoke all on function public.wegwijzer_context(text, integer) from public, anon;
grant execute on function public.wegwijzer_kernwoorden(text) to authenticated;
grant execute on function public.wegwijzer_context(text, integer) to authenticated;
