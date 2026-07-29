-- Feedbackronde 29-07 (vervolg):
-- 1. Vrijwilligers kunnen zich op de kaart aan/afmelden voor spontane hulpvragen.
-- 2. Beschikbaarheid staat standaard op álle dagen (in plaats van leeg).

alter table public.profiles
  add column if not exists spontaneous_available boolean not null default true;

alter table public.profiles
  alter column availability set default '{ma,di,wo,do,vr,za,zo}';

-- Bestaande profielen zonder ingevulde beschikbaarheid krijgen ook alles aan.
update public.profiles
set availability = '{ma,di,wo,do,vr,za,zo}'
where availability = '{}';

-- 3. Beschikbaarheid per week (bijv. {"2026-W32": ["ma","di"]}); zonder invulling
--    geldt het vaste weekpatroon uit `availability`.
alter table public.profiles
  add column if not exists availability_weeks jsonb not null default '{}'::jsonb;
