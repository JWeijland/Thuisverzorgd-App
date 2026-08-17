-- Aanbieder-agenda (17-08): aanbieders (kapper, tuinman, ...) krijgen een
-- eigen account en beheren hun beschikbaarheid zelf. De tijdsloten op de
-- dienstpagina komen voortaan uit de database (werkritme - afwezigheid -
-- bestaande boekingen) in plaats van de vier vaste nepmomenten in de app.
--
-- Toegang: een aanbieder-account is NIET zelf aan te maken. Thuisverzorgd
-- (admin) maakt het account aan met gebruikersnaam + wachtwoord (edge function
-- `aanbieder-account`) en koppelt het aan een providers-rij. `change_role`
-- accepteert 'aanbieder' bewust niet, en de prevent_role_change-trigger
-- blokkeert directe updates; alleen de service-role kan de rol zetten.
--
-- Dubbelboeken kan hierna niet meer: `create_booking` neemt een advisory lock
-- per aanbieder en controleert het gekozen moment tegen dezelfde berekening
-- als de app toont.

-- ---------------------------------------------------------------------------
-- Rol en kolommen
-- ---------------------------------------------------------------------------

-- Nieuwe enumwaarde. Alleen gebruikt in functieteksten (runtime), dus veilig
-- binnen deze transactie.
alter type public.user_role add value if not exists 'aanbieder';

alter table public.providers
  -- Het account van de aanbieder; null zolang er nog geen account is.
  add column if not exists profile_id uuid unique references public.profiles (id) on delete set null,
  -- Reistijd tussen twee bezoeken, meegeteld als bezet rond elke boeking.
  add column if not exists buffer_min integer not null default 0 check (buffer_min between 0 and 120);

-- ---------------------------------------------------------------------------
-- Werkritme en afwezigheid
-- ---------------------------------------------------------------------------

-- Eén blok per weekdag (ma=1 ... zo=7, zoals isodow). Geen rij = die dag dicht.
create table public.provider_hours (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers (id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  start_time time not null,
  end_time time not null,
  unique (provider_id, weekday),
  check (end_time > start_time)
);

-- "Ik ben er even niet": hele dagen, van t/m.
create table public.provider_absences (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers (id) on delete cascade,
  start_date date not null,
  end_date date not null,
  reason text not null default '',
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);
create index on public.provider_absences (provider_id, end_date);

alter table public.provider_hours enable row level security;
alter table public.provider_absences enable row level security;

-- Alleen de aanbieder zelf leest en schrijft zijn agenda; klanten zien enkel
-- de uitkomst via `beschikbare_slots` (security definer).
create policy provider_hours_eigen on public.provider_hours for all to authenticated
  using (exists (
    select 1 from public.providers p
    where p.id = provider_id and p.profile_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.providers p
    where p.id = provider_id and p.profile_id = (select auth.uid())
  ));

create policy provider_absences_eigen on public.provider_absences for all to authenticated
  using (exists (
    select 1 from public.providers p
    where p.id = provider_id and p.profile_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.providers p
    where p.id = provider_id and p.profile_id = (select auth.uid())
  ));

-- ---------------------------------------------------------------------------
-- Beschikbare tijdsloten
-- ---------------------------------------------------------------------------

-- De komende 14 dagen, raster van 30 minuten, tijden in Europe/Amsterdam:
--   werkritme - afwezigheid - (boekingen van deze aanbieder + buffer),
-- en minstens 2 uur vooruit. Een slot moet volledig binnen de werktijd van
-- die dag passen (einde = start + duur van de dienst).
create or replace function public.beschikbare_slots(p_service uuid)
returns table (slot_at timestamptz)
language plpgsql
stable
security definer set search_path = public as $$
declare
  v_provider uuid;
  v_dur integer;
  v_buffer integer;
begin
  if auth.uid() is null then
    raise exception 'niet_ingelogd';
  end if;

  select s.provider_id, coalesce(s.duration_min, 60), p.buffer_min
    into v_provider, v_dur, v_buffer
  from services s
  join providers p on p.id = s.provider_id
  where s.id = p_service and s.active;
  if v_provider is null then
    raise exception 'dienst_onbekend';
  end if;

  return query
  with dagen as (
    select ((now() at time zone 'Europe/Amsterdam')::date + offs) as dag
    from generate_series(0, 13) as offs
  ),
  ritme as (
    select d.dag, h.start_time, h.end_time
    from dagen d
    join provider_hours h
      on h.provider_id = v_provider
     and h.weekday = extract(isodow from d.dag)::smallint
    where not exists (
      select 1 from provider_absences a
      where a.provider_id = v_provider
        and d.dag between a.start_date and a.end_date
    )
  ),
  momenten as (
    select (moment at time zone 'Europe/Amsterdam') as slot_ts
    from ritme r
    cross join lateral generate_series(
      (r.dag + r.start_time)::timestamp,
      (r.dag + r.end_time)::timestamp - make_interval(mins => v_dur),
      interval '30 minutes'
    ) as moment
  )
  select m.slot_ts
  from momenten m
  where m.slot_ts >= now() + interval '2 hours'
    and not exists (
      select 1
      from bookings b
      join services bs on bs.id = b.service_id
      where bs.provider_id = v_provider
        and b.status = 'geboekt'
        -- overlap van [slot, slot+duur+buffer) met [boeking, boeking+duur+buffer)
        and b.slot_at < m.slot_ts + make_interval(mins => v_dur + v_buffer)
        and m.slot_ts < b.slot_at + make_interval(mins => coalesce(bs.duration_min, 60) + v_buffer)
    )
  order by m.slot_ts;
end;
$$;

revoke execute on function public.beschikbare_slots(uuid) from public, anon;
grant execute on function public.beschikbare_slots(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Boeken: zelfde rekensom als de app, met slot per aanbieder
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
  select s.name, s.price_cents, s.provider_id,
         p.name as provider_name, p.profile_id as provider_profile
    into v_service
  from services s
  join providers p on p.id = s.provider_id
  where s.id = p_service and s.active;
  if v_service is null then
    raise exception 'dienst_onbekend';
  end if;
  if p_method not in ('apple_pay', 'ideal') then
    raise exception 'betaalwijze_onbekend';
  end if;

  -- Eén boeking tegelijk per aanbieder: wie tegelijk hetzelfde moment kiest,
  -- wacht hier even en krijgt daarna netjes 'moment_niet_beschikbaar'.
  perform pg_advisory_xact_lock(hashtext('boeking-' || v_service.provider_id::text));

  if not exists (
    select 1 from public.beschikbare_slots(p_service) s where s.slot_at = p_slot
  ) then
    raise exception 'moment_niet_beschikbaar';
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
    '/regelen/planning'
  );
  -- De aanbieder hoort het meteen in de app.
  perform public.notify(
    v_service.provider_profile,
    'boeking_aanbieder',
    'Nieuwe afspraak',
    v_service.name || ' op '
      || to_char(p_slot at time zone 'Europe/Amsterdam', 'DD-MM om HH24:MI') || ' uur.',
    '/aanbieder/afspraken'
  );
  return v_id;
end;
$$;

-- Annuleren: bestaande regels blijven (tot 24 uur vooraf); de aanbieder krijgt
-- er nu een melding bij, want zijn agenda verandert.
create or replace function public.cancel_booking(p_booking uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_booking record;
  v_dienst record;
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

  select s.name, p.profile_id as provider_profile
    into v_dienst
  from services s
  join providers p on p.id = s.provider_id
  where s.id = v_booking.service_id;
  perform public.notify(
    v_dienst.provider_profile,
    'boeking_aanbieder',
    'Afspraak geannuleerd',
    v_dienst.name || ' op '
      || to_char(v_booking.slot_at at time zone 'Europe/Amsterdam', 'DD-MM om HH24:MI')
      || ' uur gaat niet door.',
    '/aanbieder/afspraken'
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- De agenda van de aanbieder zelf
-- ---------------------------------------------------------------------------

-- Komende afspraken (vanaf vandaag) van de ingelogde aanbieder, met wat hij
-- nodig heeft om langs te gaan: bij wie en waar. Adres alleen hier: een
-- boeking is de toestemming om langs te komen.
create or replace function public.aanbieder_afspraken()
returns table (
  id uuid,
  slot_at timestamptz,
  service_name text,
  duration_min integer,
  klant_naam text,
  klant_adres text,
  klant_plaats text
)
language plpgsql
stable
security definer set search_path = public as $$
declare
  v_provider uuid;
begin
  select p.id into v_provider from providers p where p.profile_id = auth.uid();
  if v_provider is null then
    raise exception 'geen_aanbieder';
  end if;

  return query
  select b.id, b.slot_at, s.name, coalesce(s.duration_min, 60),
         coalesce(nullif(pr.name, ''), pr.username, 'Onbekend'),
         pr.street_address, pr.city
  from bookings b
  join services s on s.id = b.service_id
  join profiles pr on pr.id = b.profile_id
  where s.provider_id = v_provider
    and b.status = 'geboekt'
    and b.slot_at >= date_trunc('day', now() at time zone 'Europe/Amsterdam')
                       at time zone 'Europe/Amsterdam'
  order by b.slot_at;
end;
$$;

revoke execute on function public.aanbieder_afspraken() from public, anon;
grant execute on function public.aanbieder_afspraken() to authenticated;

-- ---------------------------------------------------------------------------
-- Startritme voor de bestaande (demo)aanbieders: ma t/m vr 09:00-17:00.
-- Zonder rijen zou geen enkele dienst nog boekbaar zijn na deze migratie.
-- ---------------------------------------------------------------------------

insert into public.provider_hours (provider_id, weekday, start_time, end_time)
select p.id, w, time '09:00', time '17:00'
from public.providers p
cross join generate_series(1, 5) as w
on conflict (provider_id, weekday) do nothing;
