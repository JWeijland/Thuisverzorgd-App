-- Feedbackronde 29-07 (deel 2): makelaarsprofielen en gerichte gesprekken.
-- 1. Hulpmakelaars krijgen een profiel (bio + onderwerpen) dat iedereen kan zien.
-- 2. Een chat kan aan één specifieke makelaar gericht worden (broker_id);
--    zonder keuze blijft het de algemene wachtrij zoals voorheen.

-- 1a. Profielvelden voor makelaars.
alter table public.profiles
  add column if not exists broker_bio text,
  add column if not exists broker_topics text[] not null default '{}';

-- 1b. Bestaande makelaars een net startprofiel geven (aanpasbaar via de database).
update public.profiles
set
  broker_bio = coalesce(
    broker_bio,
    'Al jaren wegwijzer in zorg en regelingen. Ik luister, denk met je mee en verwijs je door naar de juiste persoon of instantie. Geen vraag is te klein.'
  ),
  broker_topics = case
    when broker_topics = '{}' then
      array['Regelingen en vergoedingen', 'Wonen en zorg', 'Overbelasting', 'Dementie']
    else broker_topics
  end
where role = 'makelaar';

-- 1c. De publieke makelaars-view uitbreiden met het profiel.
drop view if exists public.v_makelaars;
create view public.v_makelaars as
select
  pr.id,
  split_part(pr.name, ' ', 1) as voornaam,
  pr.avatar_path,
  pr.broker_bio as bio,
  pr.broker_topics as onderwerpen,
  pr.city
from public.profiles pr
where pr.role = 'makelaar';
revoke all on public.v_makelaars from anon;

-- 2a. Chats kunnen aan een makelaar gericht zijn.
alter table public.broker_chats
  add column if not exists broker_id uuid references public.profiles (id) on delete set null;

-- 2b. ensure_broker_chat krijgt een optionele makelaar; oude signatuur weg om
--     dubbelzinnige overloads te voorkomen.
drop function if exists public.ensure_broker_chat();
create or replace function public.ensure_broker_chat(p_broker uuid default null)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  if p_broker is not null and not exists (
    select 1 from profiles where id = p_broker and role = 'makelaar'
  ) then
    raise exception 'geen_makelaar';
  end if;
  select id into v_id from broker_chats
  where profile_id = auth.uid() and status = 'open'
    and broker_id is not distinct from p_broker
  order by created_at desc limit 1;
  if v_id is null then
    insert into broker_chats (profile_id, broker_id)
    values (auth.uid(), p_broker) returning id into v_id;
  end if;
  return v_id;
end;
$$;

-- 2c. Console-overzicht toont aan wie de vraag gericht is.
drop view if exists public.v_broker_chat_overview;
create view public.v_broker_chat_overview as
select
  c.id,
  c.status,
  c.created_at,
  split_part(pr.name, ' ', 1) as voornaam,
  c.broker_id,
  split_part(mk.name, ' ', 1) as makelaar_voornaam,
  (select body from public.broker_messages m
     where m.chat_id = c.id order by m.created_at desc limit 1) as laatste_bericht,
  (select max(m.created_at) from public.broker_messages m where m.chat_id = c.id)
    as laatste_activiteit
from public.broker_chats c
join public.profiles pr on pr.id = c.profile_id
left join public.profiles mk on mk.id = c.broker_id
where public.is_makelaar();
revoke all on public.v_broker_chat_overview from anon;
