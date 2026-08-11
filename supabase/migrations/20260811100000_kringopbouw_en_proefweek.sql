-- Herstructurering (handoff-voorzieningen): de hulpkring wordt niet meer in
-- één scherm aangemaakt, maar in zes begeleide stappen met Bo. De antwoorden
-- van die stappen staan in één concept-record, zodat je de wizard kunt
-- onderbreken en later verder kunt. Stap 6 is een proefweek: Bo stelt een
-- rooster voor, de kring probeert het een week en bevestigt daarna.

create table public.circle_drafts (
  id uuid primary key default gen_random_uuid(),
  -- Eén lopend concept per persoon; een tweede kring begin je pas als de
  -- eerste af is.
  owner_id uuid not null unique references public.profiles (id) on delete cascade,
  -- Welke stap staat open (1 t/m 6).
  stap smallint not null default 1 check (stap between 1 and 6),
  -- De antwoorden tot nu toe: naam, relatie, adres, taken, dagdelen, notitie.
  antwoorden jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index on public.circle_drafts (owner_id);

alter table public.circle_drafts enable row level security;

-- Een concept is van jou alleen: er staan naam, relatie en adres van een
-- naaste in, en die persoon heeft nog nergens toestemming voor gegeven.
create policy circle_drafts_eigen on public.circle_drafts for all
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create trigger circle_drafts_updated_at
  before update on public.circle_drafts
  for each row execute function public.set_updated_at();

-- De proefweek zelf hangt aan de kring: wanneer is hij gestart, en heeft de
-- kring na die week bevestigd dat het rooster werkte?
alter table public.circles
  add column if not exists trial_started_at timestamptz,
  add column if not exists trial_confirmed_at timestamptz;

comment on column public.circles.trial_started_at is
  'Start van de proefweek; na 7 dagen vraagt Bo of het rooster werkte.';
comment on column public.circles.trial_confirmed_at is
  'Moment waarop de kring bevestigde dat het proefrooster klopt.';

-- Bevestigen kan alleen de beheerder van de kring, en alleen als er een
-- proefweek loopt.
create or replace function public.bevestig_proefweek(p_circle uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from circles
    where id = p_circle and owner_id = auth.uid()
  ) then
    raise exception 'geen_beheerder_van_kring';
  end if;

  update circles
  set trial_confirmed_at = now()
  where id = p_circle and trial_started_at is not null;
end;
$$;

revoke all on function public.bevestig_proefweek(uuid) from public;
grant execute on function public.bevestig_proefweek(uuid) to authenticated;
