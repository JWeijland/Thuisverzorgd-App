-- Wegwijzer: kennisbank over de wetten en regelingen rond mantelzorg.
--
-- Waar de opleidingen de vrijwilliger klaarstomen, wijst de Wegwijzer de
-- beheerder de weg in wetten en regelingen: financiën, wonen, werk, dementie,
-- zorg thuis en beslissen voor een ander. De beheerder zoekt zelf een antwoord;
-- komt hij er niet uit, dan gaat hij van hieruit door naar de hulpmakelaar.
--
-- Zoeken is het hart van deze functie. Daarom:
--  * elke module heeft `zoektermen`: synoniemen en spreektaal ("mantelwoning",
--    "kangoeroewoning") die mensen echt intypen. Nederlandse stemming knipt
--    samenstellingen niet uit elkaar, dus zonder die lijst vindt "mantelwoning"
--    de module "Mantelzorgwoning" nooit;
--  * naast full-text zoeken staat een trigram-vangnet (pg_trgm) voor typefouten;
--  * zoekopdrachten worden anoniem geteld, zodat we zien welke onderwerpen
--    mensen zoeken en niet vinden. Er gaat bewust géén profile_id mee.

create extension if not exists pg_trgm with schema extensions;

/**
 * array_to_string() is in Postgres als STABLE gemarkeerd (het leunt op de
 * uitvoerfunctie van het elementtype) en mag daardoor niet in een gegenereerde
 * kolom. Voor een lijst tekst is het samenvoegen wél gewoon immutable, dus
 * verpakken we dat ene geval in een eigen functie.
 */
create or replace function public.tekst_uit_lijst(p_lijst text[])
returns text
language sql immutable parallel safe as $$
  select coalesce(array_to_string(p_lijst, ' '), '');
$$;

-- ---------------------------------------------------------------------------
-- Tabellen
-- ---------------------------------------------------------------------------

create table public.guide_themes (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  titel text not null,
  omschrijving text,
  -- naam van het lucide-icoon; de app mapt hem op een component
  icoon text not null default 'BookOpen',
  -- kleurnaam uit het thema-palet van de app, nooit een losse hexwaarde
  kleur text not null default 'blauw' check (kleur in ('blauw', 'groen', 'oranje', 'paars')),
  sortering integer not null default 0,
  published boolean not null default true
);

create table public.guide_modules (
  id uuid primary key default gen_random_uuid(),
  theme_id uuid not null references public.guide_themes (id) on delete cascade,
  slug text not null unique,
  titel text not null,
  -- één of twee zinnen; staat op de kaart en in de zoekresultaten
  samenvatting text not null,
  -- "kort gezegd": de kern in een paar bullets, bovenaan het scherm
  kern text[] not null default '{}',
  -- wettelijke basis, bijv. {'Wmo 2015, artikel 2.3.2'}
  wetten text[] not null default '{}',
  -- spreektaal en synoniemen waarop mensen zoeken
  zoektermen text[] not null default '{}',
  leestijd_minuten integer not null default 4,
  -- staat als suggestie op het zoekscherm
  populair boolean not null default false,
  bijgewerkt_op date not null default current_date,
  sortering integer not null default 0,
  published boolean not null default true,
  zoek tsvector generated always as (
    setweight(to_tsvector('dutch'::regconfig, coalesce(titel, '')), 'A') ||
    setweight(to_tsvector('dutch'::regconfig, public.tekst_uit_lijst(zoektermen)), 'A') ||
    setweight(to_tsvector('dutch'::regconfig, coalesce(samenvatting, '')), 'B') ||
    setweight(to_tsvector('dutch'::regconfig, public.tekst_uit_lijst(kern)), 'B') ||
    setweight(to_tsvector('dutch'::regconfig, public.tekst_uit_lijst(wetten)), 'C')
  ) stored
);
create index guide_modules_zoek_idx on public.guide_modules using gin (zoek);
create index guide_modules_thema_idx on public.guide_modules (theme_id, sortering);
-- Geen trigram-index: word_similarity() wordt hier als uitdrukking berekend
-- over enkele tientallen rijen, daar helpt een index niet bij.

create table public.guide_sections (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.guide_modules (id) on delete cascade,
  sortering integer not null default 0,
  -- soort bepaalt hoe de app het blok tekent
  soort text not null default 'uitleg'
    check (soort in ('uitleg', 'stappen', 'wet', 'letop', 'voorbeeld', 'vraag')),
  titel text not null,
  body text not null,
  zoek tsvector generated always as (
    setweight(to_tsvector('dutch'::regconfig, coalesce(titel, '')), 'B') ||
    setweight(to_tsvector('dutch'::regconfig, coalesce(body, '')), 'C')
  ) stored,
  unique (module_id, sortering)
);
create index guide_sections_zoek_idx on public.guide_sections using gin (zoek);

create table public.guide_links (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.guide_modules (id) on delete cascade,
  sortering integer not null default 0,
  titel text not null,
  -- waar je verder leest of iets aanvraagt; opent in de in-app browser
  url text not null,
  unique (module_id, sortering)
);

-- Bewaard om later terug te lezen.
create table public.guide_bookmarks (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  module_id uuid not null references public.guide_modules (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (profile_id, module_id)
);

-- Laatst gelezen, voor "verder waar je gebleven was".
create table public.guide_reads (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  module_id uuid not null references public.guide_modules (id) on delete cascade,
  gelezen_op timestamptz not null default now(),
  primary key (profile_id, module_id)
);

-- Anonieme zoekstatistiek: welke vragen leven er, en waar vinden we niets op?
create table public.guide_searches (
  id uuid primary key default gen_random_uuid(),
  term text not null,
  resultaten integer not null default 0,
  created_at timestamptz not null default now()
);
create index guide_searches_term_idx on public.guide_searches (created_at desc);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.guide_themes enable row level security;
alter table public.guide_modules enable row level security;
alter table public.guide_sections enable row level security;
alter table public.guide_links enable row level security;
alter table public.guide_bookmarks enable row level security;
alter table public.guide_reads enable row level security;
alter table public.guide_searches enable row level security;

-- Inhoud: leesbaar voor iedereen die is ingelogd. Schrijven doen wij via migraties.
create policy guide_themes_select on public.guide_themes for select
  using (published and auth.uid() is not null);
create policy guide_modules_select on public.guide_modules for select
  using (published and auth.uid() is not null);
create policy guide_sections_select on public.guide_sections for select
  using (auth.uid() is not null);
create policy guide_links_select on public.guide_links for select
  using (auth.uid() is not null);

-- Bewaard en gelezen: alleen je eigen rijen.
create policy guide_bookmarks_select on public.guide_bookmarks for select
  using (profile_id = auth.uid());
create policy guide_bookmarks_insert on public.guide_bookmarks for insert
  with check (profile_id = auth.uid());
create policy guide_bookmarks_delete on public.guide_bookmarks for delete
  using (profile_id = auth.uid());

create policy guide_reads_select on public.guide_reads for select
  using (profile_id = auth.uid());
create policy guide_reads_insert on public.guide_reads for insert
  with check (profile_id = auth.uid());
create policy guide_reads_update on public.guide_reads for update
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Zoektermen: wegschrijven mag, teruglezen alleen het platformbeheer.
create policy guide_searches_insert on public.guide_searches for insert
  with check (auth.uid() is not null);
create policy guide_searches_select on public.guide_searches for select
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

-- Thema's met het aantal onderwerpen erin.
create view public.v_guide_themes as
select
  t.id,
  t.slug,
  t.titel,
  t.omschrijving,
  t.icoon,
  t.kleur,
  t.sortering,
  (select count(*)::int from public.guide_modules m
     where m.theme_id = t.id and m.published) as onderwerpen
from public.guide_themes t
where t.published
order by t.sortering, t.titel;
revoke all on public.v_guide_themes from anon;

-- Modules met hun thema erbij, plus of jij ze bewaarde of al las.
create view public.v_guide_modules as
select
  m.id,
  m.slug,
  m.titel,
  m.samenvatting,
  m.kern,
  m.wetten,
  m.zoektermen,
  m.leestijd_minuten,
  m.populair,
  m.bijgewerkt_op,
  m.sortering,
  t.id as theme_id,
  t.slug as thema_slug,
  t.titel as thema,
  t.kleur as thema_kleur,
  t.icoon as thema_icoon,
  exists (
    select 1 from public.guide_bookmarks b
    where b.module_id = m.id and b.profile_id = auth.uid()
  ) as bewaard,
  (select r.gelezen_op from public.guide_reads r
     where r.module_id = m.id and r.profile_id = auth.uid()) as gelezen_op
from public.guide_modules m
join public.guide_themes t on t.id = m.theme_id
where m.published and t.published
order by t.sortering, m.sortering, m.titel;
revoke all on public.v_guide_modules from anon;

-- ---------------------------------------------------------------------------
-- Zoeken
-- ---------------------------------------------------------------------------

/**
 * Zet een ingetypte zin om in een tsquery met prefix-matching, zodat je al
 * tijdens het typen resultaten ziet ("mantelz" vindt "mantelzorgwoning").
 * Geeft null terug als er niets bruikbaars in de zin staat.
 */
create or replace function public.wegwijzer_tsquery(p_zoek text)
returns tsquery
language plpgsql stable set search_path = public as $$
declare
  v_woorden text[];
  v_query text;
begin
  select array_agg(w) into v_woorden
  from unnest(regexp_split_to_array(lower(coalesce(p_zoek, '')), '[^[:alnum:]]+')) as w
  where length(w) >= 2;

  if v_woorden is null then
    return null;
  end if;

  select string_agg(w || ':*', ' & ') into v_query from unnest(v_woorden) as w;

  begin
    return to_tsquery('dutch'::regconfig, v_query);
  exception when others then
    return plainto_tsquery('dutch'::regconfig, p_zoek);
  end;
end;
$$;

/**
 * Zoeken door de Wegwijzer. Combineert vier manieren van vinden, en neemt per
 * module de sterkste score:
 *   1. full-text op titel, synoniemen, samenvatting en kern (zwaarst);
 *   2. full-text in de tekst van de onderdelen zelf;
 *   3. gewoon "bevat" op titel en synoniemen (vangt samenstellingen);
 *   4. trigram-gelijkenis, het vangnet voor typefouten.
 * `treffer` is het stukje tekst waarin het antwoord staat; het gevonden woord
 * staat tussen « en » zodat de app het dik kan zetten.
 */
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
  join public.guide_modules m on m.id = sc.module_id
  join public.guide_themes t on t.id = m.theme_id
  where sc.score >= 0.18 and t.published
  order by sc.score desc, m.sortering
  limit greatest(p_limiet, 1);
end;
$$;
revoke execute on function public.search_wegwijzer(text, integer) from anon;

/**
 * Suggesties onder het zoekveld: onderwerpnamen en synoniemen die op de
 * ingetypte tekst lijken. Levert de term én de module waar hij bij hoort.
 */
create or replace function public.wegwijzer_suggesties(p_zoek text, p_limiet integer default 6)
returns table (term text, slug text, titel text)
language sql stable set search_path = public, extensions as $$
  with kandidaten as (
    select m.titel as term, m.slug, m.titel, 1 as voorrang from public.guide_modules m
    where m.published
    union all
    select z as term, m.slug, m.titel, 2 as voorrang
    from public.guide_modules m, unnest(m.zoektermen) as z
    where m.published
  )
  select k.term, k.slug, k.titel
  from kandidaten k
  where length(trim(coalesce(p_zoek, ''))) >= 2
    and (
      lower(k.term) like '%' || lower(trim(p_zoek)) || '%'
      or word_similarity(lower(trim(p_zoek)), lower(k.term)) > 0.55
    )
  order by
    k.voorrang,
    case when lower(k.term) like lower(trim(p_zoek)) || '%' then 0 else 1 end,
    length(k.term)
  limit greatest(p_limiet, 1);
$$;
revoke execute on function public.wegwijzer_suggesties(text, integer) from anon;

-- ---------------------------------------------------------------------------
-- Acties
-- ---------------------------------------------------------------------------

-- Bewaren of het bewaren ongedaan maken; geeft terug of hij nu bewaard is.
create or replace function public.toggle_guide_bookmark(p_module uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_bestond boolean;
begin
  if auth.uid() is null then
    raise exception 'niet_ingelogd';
  end if;
  delete from guide_bookmarks
  where profile_id = auth.uid() and module_id = p_module;
  get diagnostics v_bestond = row_count;
  if v_bestond then
    return false;
  end if;
  insert into guide_bookmarks (profile_id, module_id) values (auth.uid(), p_module);
  return true;
end;
$$;

-- Onthouden dat je dit onderwerp opende, voor "verder lezen".
create or replace function public.mark_guide_read(p_module uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    return;
  end if;
  insert into guide_reads (profile_id, module_id, gelezen_op)
  values (auth.uid(), p_module, now())
  on conflict (profile_id, module_id) do update set gelezen_op = now();
end;
$$;

-- Anoniem bijhouden waarop gezocht is; losse letters slaan we niet op.
create or replace function public.log_guide_search(p_zoek text, p_resultaten integer)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or length(trim(coalesce(p_zoek, ''))) < 3 then
    return;
  end if;
  insert into guide_searches (term, resultaten)
  values (left(lower(trim(p_zoek)), 120), greatest(coalesce(p_resultaten, 0), 0));
end;
$$;

-- ---------------------------------------------------------------------------
-- Hulpjes voor de inhoudsmigraties (worden aan het eind weer opgeruimd)
-- ---------------------------------------------------------------------------

create or replace function public.wegwijzer_seed_module(
  p_thema text,
  p_slug text,
  p_titel text,
  p_samenvatting text,
  p_kern text[],
  p_wetten text[],
  p_zoektermen text[],
  p_leestijd integer,
  p_sortering integer,
  p_populair boolean default false
)
returns void
language sql as $$
  insert into public.guide_modules (
    theme_id, slug, titel, samenvatting, kern, wetten, zoektermen,
    leestijd_minuten, sortering, populair
  )
  select t.id, p_slug, p_titel, p_samenvatting, p_kern, p_wetten, p_zoektermen,
         p_leestijd, p_sortering, p_populair
  from public.guide_themes t
  where t.slug = p_thema
  on conflict (slug) do update set
    theme_id = excluded.theme_id,
    titel = excluded.titel,
    samenvatting = excluded.samenvatting,
    kern = excluded.kern,
    wetten = excluded.wetten,
    zoektermen = excluded.zoektermen,
    leestijd_minuten = excluded.leestijd_minuten,
    sortering = excluded.sortering,
    populair = excluded.populair;
$$;

create or replace function public.wegwijzer_seed_sectie(
  p_module text,
  p_sortering integer,
  p_soort text,
  p_titel text,
  p_body text
)
returns void
language sql as $$
  insert into public.guide_sections (module_id, sortering, soort, titel, body)
  select m.id, p_sortering, p_soort, p_titel, p_body
  from public.guide_modules m
  where m.slug = p_module
  on conflict (module_id, sortering) do update set
    soort = excluded.soort,
    titel = excluded.titel,
    body = excluded.body;
$$;

create or replace function public.wegwijzer_seed_link(
  p_module text,
  p_sortering integer,
  p_titel text,
  p_url text
)
returns void
language sql as $$
  insert into public.guide_links (module_id, sortering, titel, url)
  select m.id, p_sortering, p_titel, p_url
  from public.guide_modules m
  where m.slug = p_module
  on conflict (module_id, sortering) do update set
    titel = excluded.titel,
    url = excluded.url;
$$;

-- ---------------------------------------------------------------------------
-- Thema's
-- ---------------------------------------------------------------------------
insert into public.guide_themes (slug, titel, omschrijving, icoon, kleur, sortering) values
  ('basis', 'Hoe zit het zorgstelsel in elkaar',
   'Welke wet hoort bij jouw situatie, en hoe vraag je hulp aan.',
   'Compass', 'blauw', 1),
  ('financien', 'Geld en regelingen',
   'Vergoedingen, eigen bijdragen, belasting en wat inwonen met je uitkering doet.',
   'Wallet', 'groen', 2),
  ('wonen', 'Wonen en verbouwen',
   'Mantelzorgwoning, samen gaan wonen, de woning aanpassen en verhuizen.',
   'House', 'oranje', 3),
  ('werk', 'Werk en verlof',
   'Zorgverlof, je werktijden aanpassen en het gesprek met je werkgever.',
   'Briefcase', 'blauw', 4),
  ('dementie', 'Dementie',
   'Van de eerste signalen tot de casemanager, onvrijwillige zorg en het verpleeghuis.',
   'Brain', 'paars', 5),
  ('regelen', 'Beslissen voor een ander',
   'Volmacht, levenstestament, mentorschap en bewind, en inzage in het dossier.',
   'Scale', 'paars', 6),
  ('zorg-thuis', 'Zorg thuis regelen',
   'Wijkverpleging, huishoudelijke hulp, dagbesteding, respijtzorg en hulpmiddelen.',
   'HeartHandshake', 'groen', 7),
  ('jezelf', 'Zorgen voor jezelf',
   'Overbelasting op tijd zien, hulp inschakelen en wat er komt als de zorg stopt.',
   'HeartPulse', 'oranje', 8)
on conflict (slug) do update set
  titel = excluded.titel,
  omschrijving = excluded.omschrijving,
  icoon = excluded.icoon,
  kleur = excluded.kleur,
  sortering = excluded.sortering;
