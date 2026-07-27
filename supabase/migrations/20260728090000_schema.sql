-- Fase 3 · Migratie 1: extensies, types, tabellen, indexen, basistriggers.
-- Ontwerp: docs/design/README.md is leidend; besluiten in docs/ANALYSE.md en docs/ADR/.

create extension if not exists postgis;
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.user_role as enum ('beheerder', 'vrijwilliger', 'hulpvrager', 'admin', 'makelaar');
create type public.member_role as enum ('beheerder', 'vrijwilliger', 'hulpvrager');
create type public.member_status as enum ('actief', 'uitgenodigd', 'id_check', 'kijkt_mee');
create type public.invitation_kind as enum ('uitnodiging', 'aanvraag');
create type public.invitation_status as enum ('open', 'geaccepteerd', 'afgewezen', 'verlopen', 'ingetrokken');
create type public.task_type as enum ('boodschappen', 'wandelen', 'vervoer', 'gezelschap', 'anders');
create type public.task_recurrence as enum ('eenmalig', 'wekelijks');
create type public.task_status as enum ('open', 'ingepland', 'gedaan', 'geannuleerd');
create type public.request_type as enum ('boodschappen', 'vervoer', 'medicijnen', 'gezelschap');
create type public.request_status as enum ('open', 'aanbod', 'onderweg', 'afgerond', 'geannuleerd');
create type public.offer_status as enum ('aangeboden', 'geaccepteerd', 'afgewezen', 'ingetrokken');
create type public.forum_tag as enum ('wonen', 'werk', 'financien', 'dementie', 'overig');
create type public.report_status as enum ('open', 'afgehandeld');
create type public.subscription_status as enum ('gratis', 'proef', 'actief', 'verlopen');

-- ---------------------------------------------------------------------------
-- Hulpfuncties (geen tabellen nodig)
-- ---------------------------------------------------------------------------

-- Korte leesbare code zonder verwarrende tekens (geen 0/O/1/I).
create or replace function public.gen_short_code()
returns text
language sql
volatile
as $$
  select string_agg(
    substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + floor(random() * 32)::int, 1), ''
  )
  from generate_series(1, 4);
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Locatie afronden op ~1 km (2 decimalen) vóór er toestemming is.
create or replace function public.set_location_rounded()
returns trigger
language plpgsql
as $$
begin
  if new.location is null then
    new.location_rounded = null;
  else
    new.location_rounded = st_setsrid(
      st_makepoint(
        round(st_x(new.location::geometry)::numeric, 2)::float8,
        round(st_y(new.location::geometry)::numeric, 2)::float8
      ), 4326)::geography;
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Tabellen
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.user_role,
  name text not null default '',
  email text,
  tvz_id text not null unique default ('TVZ-' || public.gen_short_code()),
  avatar_path text,
  -- ID-documenten staan NOOIT in de database: alleen de bevestiging.
  id_verified boolean not null default false,
  id_verified_at timestamptz,
  phone text,
  city text,
  location geography (point, 4326),
  location_rounded geography (point, 4326),
  -- beschikbaarheid als dagcodes: {ma,di,wo,do,vr,za,zo}
  availability text[] not null default '{}',
  vacation_mode boolean not null default false,
  pool_opt_in boolean not null default false,
  large_text boolean not null default false,
  calendar_sync boolean not null default false,
  notification_prefs jsonb not null default '{}'::jsonb,
  helped_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.circles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  -- Koppelcode waarmee de hulpvrager meekijkt (TVZ-4Q7B).
  link_code text not null unique default ('TVZ-' || public.gen_short_code()),
  address text,
  location geography (point, 4326),
  location_rounded geography (point, 4326),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.circle_members (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  member_role public.member_role not null,
  status public.member_status not null default 'uitgenodigd',
  joined_at timestamptz not null default now(),
  unique (circle_id, profile_id)
);

create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  kind public.invitation_kind not null,
  -- uitnodiging: wie er wordt uitgenodigd; aanvraag: wie zich aanmeldt.
  profile_id uuid references public.profiles (id) on delete cascade,
  email text,
  invited_by uuid not null references public.profiles (id) on delete cascade,
  message text,
  status public.invitation_status not null default 'open',
  -- pas na de videokennismaking verschijnt "Toelaten tot de kring"
  video_done boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (profile_id is not null or email is not null)
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  type public.task_type not null,
  -- vrije invoer bij type "anders"
  custom_label text,
  date date not null,
  time time not null,
  recurrence public.task_recurrence not null default 'eenmalig',
  series_id uuid,
  status public.task_status not null default 'open',
  claimed_by uuid references public.profiles (id) on delete set null,
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Conceptplanning: alleen zichtbaar voor de beheerder tot "Publiceren".
create table public.task_drafts (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  type public.task_type not null,
  custom_label text,
  date date not null,
  time time not null,
  recurrence public.task_recurrence not null default 'eenmalig',
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Logboekje na afronden; verschijnt bij de beheerder onder "Uit de kring".
create table public.task_logs (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks (id) on delete cascade,
  circle_id uuid not null references public.circles (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  note text not null,
  created_at timestamptz not null default now()
);

create table public.spontaneous_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  circle_id uuid references public.circles (id) on delete set null,
  type public.request_type not null,
  note text,
  status public.request_status not null default 'open',
  -- exact adres/locatie pas zichtbaar na toestemming; tot die tijd alleen afgerond
  address text,
  location geography (point, 4326),
  location_rounded geography (point, 4326),
  helper_id uuid references public.profiles (id) on delete set null,
  cancelled_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.request_offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.spontaneous_requests (id) on delete cascade,
  volunteer_id uuid not null references public.profiles (id) on delete cascade,
  message text,
  status public.offer_status not null default 'aangeboden',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (request_id, volunteer_id)
);

-- Kringchat.
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null,
  title text not null,
  body text,
  deeplink text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.forum_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text not null,
  tag public.forum_tag not null default 'overig',
  city text,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.forum_replies (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.forum_posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  is_broker boolean not null default false,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.forum_reports (
  id uuid primary key default gen_random_uuid(),
  target_kind text not null check (target_kind in ('post', 'reply', 'message', 'profile')),
  target_id uuid not null,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason text,
  status public.report_status not null default 'open',
  created_at timestamptz not null default now()
);

-- Blokkeren tussen gebruikers (App Store-eis bij user-generated content).
create table public.user_blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

-- Live chat met hulpmakelaars.
create table public.broker_chats (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'open' check (status in ('open', 'gesloten')),
  created_at timestamptz not null default now()
);

create table public.broker_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.broker_chats (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

-- Waardering van vrijwilligers (getoond bij "Aanvraag beoordelen").
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  reviewer_id uuid not null references public.profiles (id) on delete cascade,
  volunteer_id uuid not null references public.profiles (id) on delete cascade,
  score integer not null check (score between 1 and 5),
  note text,
  created_at timestamptz not null default now(),
  unique (circle_id, reviewer_id, volunteer_id)
);

-- Entitlement; echte betaling volgt later (ADR-0002). Eén abonnement per account,
-- geldt voor alle kringen van de beheerder.
create table public.subscriptions (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  status public.subscription_status not null default 'gratis',
  source text not null default 'stub',
  started_at timestamptz,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid,
  action text not null,
  entity text not null,
  entity_id uuid,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Indexen
-- ---------------------------------------------------------------------------
create index on public.circle_members (circle_id);
create index on public.circle_members (profile_id);
create index on public.invitations (circle_id, status);
create index on public.invitations (profile_id, status);
create index on public.tasks (circle_id, date);
create index on public.tasks (claimed_by);
create index on public.task_drafts (circle_id);
create index on public.task_logs (circle_id, created_at desc);
create index on public.spontaneous_requests (status, created_at desc);
create index on public.spontaneous_requests using gist (location_rounded);
create index on public.request_offers (request_id);
create index on public.messages (circle_id, created_at desc);
create index on public.notifications (profile_id, read, created_at desc);
create index on public.forum_posts (tag, created_at desc);
create index on public.forum_replies (post_id, created_at);
create index on public.broker_messages (chat_id, created_at);
create index on public.reviews (volunteer_id);
create index on public.profiles using gist (location_rounded);
create index on public.circles using gist (location_rounded);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger circles_updated_at before update on public.circles
  for each row execute function public.set_updated_at();
create trigger tasks_updated_at before update on public.tasks
  for each row execute function public.set_updated_at();
create trigger invitations_updated_at before update on public.invitations
  for each row execute function public.set_updated_at();
create trigger requests_updated_at before update on public.spontaneous_requests
  for each row execute function public.set_updated_at();
create trigger offers_updated_at before update on public.request_offers
  for each row execute function public.set_updated_at();

create trigger profiles_round_location before insert or update of location on public.profiles
  for each row execute function public.set_location_rounded();
create trigger circles_round_location before insert or update of location on public.circles
  for each row execute function public.set_location_rounded();
create trigger requests_round_location before insert or update of location on public.spontaneous_requests
  for each row execute function public.set_location_rounded();

-- Nieuw auth-account → profiel + gratis abonnementsregel.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data ->> 'name', ''));
  insert into public.subscriptions (profile_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Rol kan één keer gekozen worden en daarna niet meer gewijzigd door de gebruiker zelf.
create or replace function public.prevent_role_change()
returns trigger
language plpgsql
as $$
begin
  if old.role is not null
     and new.role is distinct from old.role
     and coalesce(auth.jwt() ->> 'role', '') <> 'service_role' then
    raise exception 'rol_kan_niet_wijzigen';
  end if;
  return new;
end;
$$;

create trigger profiles_prevent_role_change
  before update of role on public.profiles
  for each row execute function public.prevent_role_change();
