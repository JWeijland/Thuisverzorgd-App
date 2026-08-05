-- Voorzieningen: de marktplaats met hulp aan huis (handoff aug 2026).
-- Aanbieders zijn gescreende, aan Thuisverzorgd gelieerde vaste gezichten.
-- Betalen gebeurt in de app en pas ná het bezoek (capture-later); tijdens de
-- pilot wordt er nog niets afgeschreven, de echte Stripe-koppeling volgt.

-- ---------------------------------------------------------------------------
-- Tabellen
-- ---------------------------------------------------------------------------

create table public.providers (
  id uuid primary key default gen_random_uuid(),
  -- Voornaam zoals op de detailpagina ("met Samira").
  name text not null,
  -- Bedrijfsnaam zoals op de tegel ("Buurtsuper Daan").
  business text not null,
  -- Handgeschreven notitie (Caveat) over de aanbieder op de detailpagina.
  note text not null,
  -- Demoafstand voor de pilot; echte matching op locatie volgt later.
  distance_km numeric(3, 1) not null default 1.0,
  avatar_path text,
  affiliated boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  -- "Wat kun je verwachten" op de detailpagina.
  description text not null,
  price_cents integer not null check (price_cents >= 0),
  unit text not null default 'bezoek' check (unit in ('bezoek', 'uur')),
  duration_min integer,
  rating numeric(2, 1) not null default 4.8,
  rating_count integer not null default 0,
  provider_id uuid not null references public.providers (id) on delete restrict,
  sort_order integer not null default 100,
  active boolean not null default true
);

create type public.booking_status as enum ('geboekt', 'afgerond', 'geannuleerd');

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  service_id uuid not null references public.services (id),
  slot_at timestamptz not null,
  status public.booking_status not null default 'geboekt',
  payment_method text not null check (payment_method in ('apple_pay', 'ideal')),
  -- 'na_bezoek' = afgesproken maar nog niet afgeschreven (capture-later).
  payment_status text not null default 'na_bezoek'
    check (payment_status in ('na_bezoek', 'betaald')),
  -- Prijs vastgelegd op het boekmoment, zodat een latere prijswijziging
  -- bestaande afspraken niet raakt.
  price_cents integer not null,
  created_at timestamptz not null default now(),
  cancelled_at timestamptz
);
create index on public.bookings (profile_id, slot_at);

-- ---------------------------------------------------------------------------
-- RLS: catalogus leesbaar voor ingelogde gebruikers, boekingen alleen je eigen.
-- Schrijven kan uitsluitend via de RPC's hieronder; de catalogus wordt via
-- migraties beheerd.
-- ---------------------------------------------------------------------------

alter table public.providers enable row level security;
alter table public.services enable row level security;
alter table public.bookings enable row level security;

create policy providers_select on public.providers for select to authenticated using (true);
create policy services_select on public.services for select to authenticated using (true);
create policy bookings_select on public.bookings for select to authenticated
  using (profile_id = auth.uid());

-- ---------------------------------------------------------------------------
-- RPC's
-- ---------------------------------------------------------------------------

create or replace function public.create_booking(
  p_service uuid,
  p_slot timestamptz,
  p_method text
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_service record;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'niet_ingelogd';
  end if;
  select s.name, s.price_cents, p.name as provider_name
    into v_service
  from services s
  join providers p on p.id = s.provider_id
  where s.id = p_service and s.active;
  if v_service is null then
    raise exception 'dienst_onbekend';
  end if;
  if p_slot < now() then
    raise exception 'moment_voorbij';
  end if;
  if p_method not in ('apple_pay', 'ideal') then
    raise exception 'betaalwijze_onbekend';
  end if;

  insert into bookings (profile_id, service_id, slot_at, payment_method, price_cents)
  values (auth.uid(), p_service, p_slot, p_method, v_service.price_cents)
  returning id into v_id;

  perform public.notify(
    auth.uid(),
    'boeking',
    v_service.name || ' geboekt',
    v_service.provider_name || ' komt op '
      || to_char(p_slot at time zone 'Europe/Amsterdam', 'DD-MM om HH24:MI') || ' uur.',
    '/rooster'
  );
  return v_id;
end;
$$;

-- Gratis annuleren tot 24 uur vóór het bezoek; daarna server-side geweigerd.
create or replace function public.cancel_booking(p_booking uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_booking record;
begin
  select * into v_booking
  from bookings
  where id = p_booking and profile_id = auth.uid();
  if v_booking is null then
    raise exception 'boeking_onbekend';
  end if;
  if v_booking.status <> 'geboekt' then
    raise exception 'al_afgehandeld';
  end if;
  if now() > v_booking.slot_at - interval '24 hours' then
    raise exception 'annuleren_te_laat';
  end if;
  update bookings
  set status = 'geannuleerd', cancelled_at = now()
  where id = p_booking;
end;
$$;

-- PUBLIC houdt anders een execute-grant op nieuwe functies (les uit de
-- Wegwijzer-migraties): expliciet intrekken en alleen authenticated toestaan.
revoke execute on function public.create_booking(uuid, timestamptz, text) from public, anon;
grant execute on function public.create_booking(uuid, timestamptz, text) to authenticated;
revoke execute on function public.cancel_booking(uuid) from public, anon;
grant execute on function public.cancel_booking(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Catalogus: de negen betaalde diensten uit de handoff. Vaste uuid's zodat de
-- migratie herhaalbaar blijft en latere migraties erop kunnen verwijzen.
-- Buddy (gratis, vrijwillig) is bewust géén dienst: die tegel verwijst naar de
-- hulpkring en de buurtkaart.
-- ---------------------------------------------------------------------------

insert into public.providers (id, name, business, note, distance_km) values
  ('a0000000-0000-4000-8000-000000000001', 'Samira', 'Kapper Samira',
   'Samira knipt al twaalf jaar bij mensen thuis en neemt altijd ruim de tijd.', 1.2),
  ('a0000000-0000-4000-8000-000000000002', 'Daan', 'Buurtsuper Daan',
   'Daan brengt de boodschappen zelf langs en zet ze op verzoek meteen in de kast.', 0.8),
  ('a0000000-0000-4000-8000-000000000003', 'Truus', 'Keuken van Truus',
   'Truus kookt elke dag vers, Hollandse kost zoals vroeger.', 1.5),
  ('a0000000-0000-4000-8000-000000000004', 'Linda', 'Helder Thuis',
   'Linda en haar team maken schoon met oog voor wat u belangrijk vindt.', 2.1),
  ('a0000000-0000-4000-8000-000000000005', 'Ali', 'Groenwerk Ali',
   'Ali houdt tuinen al twintig jaar netjes, van snoeien tot terras vegen.', 1.7),
  ('a0000000-0000-4000-8000-000000000006', 'Mark', 'Fysio de Pijp',
   'Mark komt aan huis voor massage en oefeningen, rustig en vakkundig.', 2.4),
  ('a0000000-0000-4000-8000-000000000007', 'Rob', 'Rijd mee met Rob',
   'Rob rijdt u naar afspraak of familie en helpt bij het in- en uitstappen.', 1.1),
  ('a0000000-0000-4000-8000-000000000008', 'Sanne', 'Waf & Wandel',
   'Sanne laat honden in kleine groepjes uit en stuurt na afloop een foto.', 0.9),
  ('a0000000-0000-4000-8000-000000000009', 'Kees', 'Klussen met Kees',
   'Kees regelt de kleine klussen in huis, van lamp ophangen tot lekkende kraan.', 1.9)
on conflict (id) do nothing;

insert into public.services
  (id, slug, name, description, price_cents, unit, duration_min, rating, rating_count, provider_id, sort_order)
values
  ('b0000000-0000-4000-8000-000000000001', 'kapper', 'Kapper aan huis',
   'Knippen, föhnen of een volledige behandeling, gewoon aan uw eigen keukentafel.',
   2900, 'bezoek', 45, 4.9, 86, 'a0000000-0000-4000-8000-000000000001', 10),
  ('b0000000-0000-4000-8000-000000000002', 'boodschappen', 'Boodschappen',
   'Uw boodschappenlijstje wordt dezelfde dag nog thuisbezorgd.',
   700, 'bezoek', 30, 4.8, 132, 'a0000000-0000-4000-8000-000000000002', 20),
  ('b0000000-0000-4000-8000-000000000003', 'maaltijden', 'Maaltijden',
   'Een verse, warme maaltijd aan de deur, ook voor speciale diëten.',
   900, 'bezoek', 15, 4.7, 95, 'a0000000-0000-4000-8000-000000000003', 30),
  ('b0000000-0000-4000-8000-000000000004', 'schoonmaak', 'Schoonmaak',
   'Vaste hulp die uw huis schoonmaakt zoals u dat gewend bent.',
   2200, 'uur', 60, 4.8, 74, 'a0000000-0000-4000-8000-000000000004', 40),
  ('b0000000-0000-4000-8000-000000000005', 'tuinman', 'Tuinman',
   'Snoeien, maaien en de tuin netjes het seizoen door helpen.',
   3500, 'uur', 60, 4.6, 41, 'a0000000-0000-4000-8000-000000000005', 50),
  ('b0000000-0000-4000-8000-000000000006', 'massage-fysio', 'Massage & fysio',
   'Behandeling aan huis bij stijve spieren of na een blessure.',
   4500, 'bezoek', 45, 4.9, 58, 'a0000000-0000-4000-8000-000000000006', 60),
  ('b0000000-0000-4000-8000-000000000007', 'vervoer', 'Vervoer',
   'Van deur tot deur naar ziekenhuis, kapper of familie.',
   1200, 'bezoek', 30, 4.8, 167, 'a0000000-0000-4000-8000-000000000007', 70),
  ('b0000000-0000-4000-8000-000000000008', 'hond-uitlaten', 'Hond uitlaten',
   'Een fijne wandeling voor uw hond, ook bij slecht weer.',
   1000, 'bezoek', 30, 4.9, 203, 'a0000000-0000-4000-8000-000000000008', 80),
  ('b0000000-0000-4000-8000-000000000009', 'klusjesman', 'Klusjesman',
   'Kleine reparaties en klussen in en om het huis.',
   3000, 'uur', 60, 4.7, 66, 'a0000000-0000-4000-8000-000000000009', 90)
on conflict (id) do nothing;
