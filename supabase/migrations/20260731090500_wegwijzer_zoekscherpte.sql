-- Zoekresultaten scherper maken.
--
-- Het trigram-vangnet vangt typefouten op, maar geeft ook zwakke gelijkenis een
-- kleine score. Daardoor leverde "mantelwoning" naast de juiste module nog
-- veertien vage treffers op. Een absolute ondergrens is niet genoeg, want hoe
-- hoog een score uitvalt hangt af van de zoekterm. Daarom nu ook een relatieve
-- grens: alles onder 12% van de beste treffer valt af.

create or replace function public.search_wegwijzer(p_zoek text, p_limiet integer default 25)
returns table (
  id uuid,
  slug text,
  titel text,
  samenvatting text,
  thema text,
  thema_slug text,
  thema_kleur text,
  leestijd_minuten integer,
  treffer text,
  score real
)
language plpgsql stable set search_path = public, extensions as $$
declare
  v_tsq tsquery := public.wegwijzer_tsquery(p_zoek);
  v_like text := '%' || lower(trim(coalesce(p_zoek, ''))) || '%';
  v_schoon text := lower(trim(coalesce(p_zoek, '')));
begin
  if length(v_schoon) < 2 then
    return;
  end if;

  return query
  with scores as (
    select
      m.id as module_id,
      greatest(
        case when v_tsq is not null then ts_rank(m.zoek, v_tsq) * 8 else 0 end,
        case when v_tsq is not null then coalesce((
          select max(ts_rank(s.zoek, v_tsq)) * 4
          from public.guide_sections s where s.module_id = m.id and s.zoek @@ v_tsq
        ), 0) else 0 end,
        case when lower(m.titel) like v_like then 0.9 else 0 end,
        case when exists (
          select 1 from unnest(m.zoektermen) as z where lower(z) like v_like
        ) then 0.85 else 0 end,
        case when lower(m.samenvatting) like v_like then 0.5 else 0 end,
        word_similarity(v_schoon, lower(m.titel || ' ' || array_to_string(m.zoektermen, ' '))) * 0.8
      )::real as score
    from public.guide_modules m
    where m.published
  ),
  beste as (
    select coalesce(max(sc.score), 0)::real as top from scores sc
  )
  select
    m.id,
    m.slug,
    m.titel,
    m.samenvatting,
    t.titel as thema,
    t.slug as thema_slug,
    t.kleur as thema_kleur,
    m.leestijd_minuten,
    coalesce(
      case when v_tsq is not null then (
        select ts_headline(
          'dutch'::regconfig, s.body, v_tsq,
          'StartSel=«, StopSel=», MaxWords=32, MinWords=16, MaxFragments=1, FragmentDelimiter= … '
        )
        from public.guide_sections s
        where s.module_id = m.id and s.zoek @@ v_tsq
        order by ts_rank(s.zoek, v_tsq) desc
        limit 1
      ) end,
      m.samenvatting
    ) as treffer,
    sc.score
  from scores sc
  cross join beste b
  join public.guide_modules m on m.id = sc.module_id
  join public.guide_themes t on t.id = m.theme_id
  where t.published
    and sc.score >= 0.25
    and sc.score >= b.top * 0.12
  order by sc.score desc, m.sortering
  limit greatest(p_limiet, 1);
end;
$$;
revoke execute on function public.search_wegwijzer(text, integer) from anon;
