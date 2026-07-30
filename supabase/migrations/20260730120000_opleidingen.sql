-- Opleidingen (feedback 30-07): korte cursussen die je zelf op de telefoon doet
-- (tekst + video, afsluitende toets) en klassikale groepen waar een professional
-- op een locatie in de buurt les geeft.
--
-- Privacy/veiligheid: de juiste antwoorden staan in `course_questions` maar zijn
-- nooit leesbaar voor gebruikers; nakijken gebeurt server-side in
-- `submit_course_test`. Vragen worden gelezen via `v_course_questions`.

create table public.courses (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  subtitle text,
  description text,
  -- onderwerp: sluit aan bij de forumtags, vrij tekstveld voor de pil
  topic text,
  duur_minuten integer not null default 15,
  -- percentage goed dat nodig is om te halen
  drempel integer not null default 70 check (drempel between 0 and 100),
  sortering integer not null default 0,
  published boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  sortering integer not null default 0,
  title text not null,
  body text,
  -- optionele video; wordt in de in-app browser geopend
  video_url text,
  video_label text
);
create index course_modules_course_idx on public.course_modules (course_id, sortering);

create table public.course_questions (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  sortering integer not null default 0,
  question text not null,
  options text[] not null,
  correct_index integer not null,
  uitleg text
);
create index course_questions_course_idx on public.course_questions (course_id, sortering);

create table public.course_progress (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  course_id uuid not null references public.courses (id) on delete cascade,
  gelezen_modules uuid[] not null default '{}',
  laatste_score integer,
  gehaald boolean not null default false,
  gehaald_op timestamptz,
  updated_at timestamptz not null default now(),
  primary key (profile_id, course_id)
);

create table public.course_groups (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  titel text not null,
  begeleider text not null,
  locatie text not null,
  adres text,
  city text,
  start_op timestamptz not null,
  duur_minuten integer not null default 90,
  plekken integer not null default 12,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);
create index course_groups_start_idx on public.course_groups (start_op);

create table public.course_group_signups (
  group_id uuid not null references public.course_groups (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (group_id, profile_id)
);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.courses enable row level security;
alter table public.course_modules enable row level security;
alter table public.course_questions enable row level security;
alter table public.course_progress enable row level security;
alter table public.course_groups enable row level security;
alter table public.course_group_signups enable row level security;

-- Cursusinhoud: iedereen die ingelogd is mag lezen.
create policy courses_select on public.courses for select
  using (published and auth.uid() is not null);
create policy course_modules_select on public.course_modules for select
  using (auth.uid() is not null);

-- Vragen: géén directe leesrechten (het juiste antwoord zit in dezelfde rij).
-- Lezen gaat via v_course_questions, nakijken via submit_course_test().

-- Voortgang: alleen je eigen rij.
create policy course_progress_select on public.course_progress for select
  using (profile_id = auth.uid());
create policy course_progress_insert on public.course_progress for insert
  with check (profile_id = auth.uid());
create policy course_progress_update on public.course_progress for update
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Groepen: iedereen ziet ze; alleen hulpmakelaars/beheer van het platform
-- maken of wijzigen ze (een professional geeft de les).
create policy course_groups_select on public.course_groups for select
  using (auth.uid() is not null);
create policy course_groups_insert on public.course_groups for insert
  with check (public.is_makelaar() or public.is_admin());
create policy course_groups_update on public.course_groups for update
  using (public.is_makelaar() or public.is_admin());
create policy course_groups_delete on public.course_groups for delete
  using (public.is_makelaar() or public.is_admin());

-- Aanmeldingen: je eigen aanmelding beheren; makelaars zien de deelnemers.
create policy signups_select on public.course_group_signups for select
  using (profile_id = auth.uid() or public.is_makelaar());
create policy signups_insert on public.course_group_signups for insert
  with check (profile_id = auth.uid());
create policy signups_delete on public.course_group_signups for delete
  using (profile_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------------------

-- Toetsvragen zonder het juiste antwoord.
create view public.v_course_questions as
select q.id, q.course_id, q.sortering, q.question, q.options
from public.course_questions q
order by q.course_id, q.sortering;
revoke all on public.v_course_questions from anon;

-- Cursusoverzicht met het aantal onderdelen, vragen en jouw voortgang.
create view public.v_courses as
select
  c.id,
  c.slug,
  c.title,
  c.subtitle,
  c.description,
  c.topic,
  c.duur_minuten,
  c.drempel,
  c.sortering,
  (select count(*)::int from public.course_modules m where m.course_id = c.id) as onderdelen,
  (select count(*)::int from public.course_questions q where q.course_id = c.id) as vragen,
  coalesce(array_length(p.gelezen_modules, 1), 0) as gelezen,
  coalesce(p.gehaald, false) as gehaald,
  p.laatste_score,
  (select count(*)::int from public.course_groups g
     where g.course_id = c.id and g.start_op > now()) as groepen_binnenkort
from public.courses c
left join public.course_progress p on p.course_id = c.id and p.profile_id = auth.uid()
where c.published
order by c.sortering, c.title;
revoke all on public.v_courses from anon;

-- Groepen met plekken over en of jij al bent aangemeld.
create view public.v_course_groups as
select
  g.id,
  g.course_id,
  c.title as cursus,
  g.titel,
  g.begeleider,
  g.locatie,
  g.city,
  g.start_op,
  g.duur_minuten,
  g.plekken,
  (select count(*)::int from public.course_group_signups s where s.group_id = g.id) as aangemeld,
  exists (
    select 1 from public.course_group_signups s
    where s.group_id = g.id and s.profile_id = auth.uid()
  ) as ik_ga
from public.course_groups g
join public.courses c on c.id = g.course_id
where g.start_op > now() - interval '2 hours'
order by g.start_op;
revoke all on public.v_course_groups from anon;

-- ---------------------------------------------------------------------------
-- RPC's
-- ---------------------------------------------------------------------------

-- Een onderdeel als gelezen markeren (idempotent).
create or replace function public.mark_module_read(p_module uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_course uuid;
begin
  select course_id into v_course from course_modules where id = p_module;
  if v_course is null then
    raise exception 'onderdeel_bestaat_niet';
  end if;
  insert into course_progress (profile_id, course_id, gelezen_modules)
  values (auth.uid(), v_course, array[p_module])
  on conflict (profile_id, course_id) do update
    set gelezen_modules = (
          select array_agg(distinct m)
          from unnest(course_progress.gelezen_modules || array[p_module]) as m
        ),
        updated_at = now();
end;
$$;

/**
 * Toets nakijken. `p_answers` is een array van gekozen indexen in dezelfde
 * volgorde als v_course_questions. Geeft score (percentage) en of je gehaald
 * bent terug; de juiste antwoorden verlaten de server niet.
 */
create or replace function public.submit_course_test(p_course uuid, p_answers integer[])
returns table (score integer, gehaald boolean, drempel integer)
language plpgsql security definer set search_path = public as $$
declare
  v_totaal integer;
  v_goed integer := 0;
  v_drempel integer;
  v_score integer;
  v_gehaald boolean;
  r record;
  i integer := 1;
begin
  select c.drempel into v_drempel from courses c where c.id = p_course;
  if v_drempel is null then
    raise exception 'cursus_bestaat_niet';
  end if;
  select count(*) into v_totaal from course_questions q where q.course_id = p_course;
  if v_totaal = 0 then
    raise exception 'geen_vragen';
  end if;

  for r in
    select q.correct_index from course_questions q
    where q.course_id = p_course order by q.sortering
  loop
    if coalesce(p_answers[i], -1) = r.correct_index then
      v_goed := v_goed + 1;
    end if;
    i := i + 1;
  end loop;

  v_score := round((v_goed::numeric / v_totaal) * 100);
  v_gehaald := v_score >= v_drempel;

  insert into course_progress (profile_id, course_id, laatste_score, gehaald, gehaald_op)
  values (auth.uid(), p_course, v_score, v_gehaald, case when v_gehaald then now() end)
  on conflict (profile_id, course_id) do update
    set laatste_score = v_score,
        -- een gehaalde toets blijft gehaald, ook na een mindere poging
        gehaald = course_progress.gehaald or v_gehaald,
        gehaald_op = coalesce(course_progress.gehaald_op, case when v_gehaald then now() end),
        updated_at = now();

  return query select v_score, v_gehaald, v_drempel;
end;
$$;

-- Welke antwoorden waren goed? Alleen ná het inleveren, voor de uitleg.
create or replace function public.course_answers(p_course uuid)
returns table (question_id uuid, correct_index integer, uitleg text)
language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from course_progress
    where profile_id = auth.uid() and course_id = p_course and laatste_score is not null
  ) then
    raise exception 'nog_niet_ingeleverd';
  end if;
  return query
    select q.id, q.correct_index, q.uitleg
    from course_questions q where q.course_id = p_course order by q.sortering;
end;
$$;

-- Aan- en afmelden voor een klassikale groep, met plekcontrole.
create or replace function public.join_course_group(p_group uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_plekken integer;
  v_aangemeld integer;
begin
  select plekken into v_plekken from course_groups where id = p_group;
  if v_plekken is null then
    raise exception 'groep_bestaat_niet';
  end if;
  select count(*) into v_aangemeld from course_group_signups where group_id = p_group;
  if v_aangemeld >= v_plekken and not exists (
    select 1 from course_group_signups where group_id = p_group and profile_id = auth.uid()
  ) then
    raise exception 'groep_vol';
  end if;
  insert into course_group_signups (group_id, profile_id)
  values (p_group, auth.uid())
  on conflict do nothing;
end;
$$;

create or replace function public.leave_course_group(p_group uuid)
returns void
language sql security definer set search_path = public as $$
  delete from course_group_signups where group_id = p_group and profile_id = auth.uid();
$$;
