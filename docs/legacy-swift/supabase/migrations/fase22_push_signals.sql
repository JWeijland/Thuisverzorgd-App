-- ============================================================================
-- Fase 22 — Signalen voor belangrijke pushmeldingen
-- ----------------------------------------------------------------------------
-- Voegt de velden toe die de edge functions nodig hebben om gerichte meldingen
-- te sturen (en niet dubbel):
--   • buddy-locatie + "sinds wanneer niet-beschikbaar" (voor "in je buurt" en
--     "je buurt heeft je nodig").
--   • mijlpaal-vlaggen voor teams (75% / 100%).
--   • competitie-vlaggen (bijna afgelopen / afgerond) + laatste ranglijstplek.
--   • throttle-tijdstempels voor de 3-dagen-herinneringen (cliënt/familie).
--   • inbox-kolom competition_id.
--   • pg_cron-planning die dagelijks de notify-scheduled functie aanroept.
--
-- Idempotent: veilig om opnieuw te draaien.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BUDDY: locatie + beschikbaarheidsklok
-- ---------------------------------------------------------------------------
alter table public.buddy_profiles
    add column if not exists address                  text,
    add column if not exists latitude                 double precision,
    add column if not exists longitude                double precision,
    add column if not exists availability_off_since   timestamptz,
    add column if not exists last_neighborhood_push_at timestamptz;

-- Houd availability_off_since bij: gezet zodra de buddy op niet-beschikbaar gaat,
-- leeg zodra hij weer beschikbaar is. Zo weet de cron hoe lang iemand "uit" staat.
create or replace function public.buddy_availability_timestamp()
returns trigger
language plpgsql
as $$
begin
    if new.is_available_now is distinct from old.is_available_now then
        new.availability_off_since := case when new.is_available_now then null else now() end;
    end if;
    return new;
end;
$$;

drop trigger if exists trg_buddy_availability_ts on public.buddy_profiles;
create trigger trg_buddy_availability_ts
    before update on public.buddy_profiles
    for each row execute function public.buddy_availability_timestamp();

-- Start de klok voor buddies die nu al op niet-beschikbaar staan.
update public.buddy_profiles
   set availability_off_since = now()
 where is_available_now = false and availability_off_since is null;

-- ---------------------------------------------------------------------------
-- CLIËNT / FAMILIE: throttle voor de 3-dagen-herinnering
-- ---------------------------------------------------------------------------
alter table public.elderly_profiles
    add column if not exists last_help_reminder_at timestamptz;

alter table public.profiles
    add column if not exists last_family_reminder_at timestamptz;

-- ---------------------------------------------------------------------------
-- TEAM: mijlpaal-vlaggen
-- ---------------------------------------------------------------------------
alter table public.teams
    add column if not exists milestone_75_notified  boolean not null default false,
    add column if not exists milestone_100_notified boolean not null default false;

-- ---------------------------------------------------------------------------
-- COMPETITIE: vlaggen + laatste ranglijstplek per deelnemer
-- ---------------------------------------------------------------------------
alter table public.competitions
    add column if not exists ending_soon_notified boolean not null default false,
    add column if not exists finished_notified    boolean not null default false;

alter table public.competition_participants
    add column if not exists last_rank int;

-- ---------------------------------------------------------------------------
-- INBOX: koppeling naar competitie (naast team_id / request_id)
-- ---------------------------------------------------------------------------
alter table public.notifications
    add column if not exists competition_id uuid references public.competitions(id) on delete cascade;

-- ---------------------------------------------------------------------------
-- DAGELIJKSE CRON → notify-scheduled edge function
-- ---------------------------------------------------------------------------
-- Vereist de extensies pg_cron en pg_net (in Supabase: Database → Extensions).
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- LET OP — projpatspecifiek invullen vóór gebruik:
--   <PROJECT-REF>          : je Supabase project-ref (subdomein).
--   <SERVICE_ROLE_KEY>     : de service-role key (Project Settings → API).
-- Draai onderstaand blok één keer met de juiste waarden ingevuld. Het plant de
-- functie elke dag om 09:00 UTC. (Apart gehouden omdat secrets niet in een
-- migratie horen; vandaar als comment-sjabloon.)
--
-- select cron.schedule(
--   'notify-scheduled-daily',
--   '0 9 * * *',
--   $$
--   select net.http_post(
--     url     := 'https://<PROJECT-REF>.functions.supabase.co/notify-scheduled',
--     headers := jsonb_build_object(
--       'Content-Type', 'application/json',
--       'Authorization', 'Bearer <SERVICE_ROLE_KEY>'
--     ),
--     body    := '{}'::jsonb
--   );
--   $$
-- );
