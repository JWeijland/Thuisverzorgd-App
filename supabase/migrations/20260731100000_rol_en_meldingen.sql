-- Vrijwilligersmeldingen bij een hulpvrager of beheerder (feedback 31-07).
--
-- Wat er misging: `change_role` en `redeem_circle_code` wijzigen wél
-- `profiles.role`, maar laten `circle_members.member_role` en al aangenomen
-- taken staan. Wie als vrijwilliger begon en daarna hulpvrager werd, bleef dus
-- in de kring "vrijwilliger": hij kreeg "Nieuwe taak in je kring" en zijn oude
-- aangenomen taken bleven aan hem hangen, waardoor de taakbanner bovenin
-- "... · jij gaat" toonde. In de database stonden 3 taken op naam van een
-- hulpvrager en 2 onterechte taak_nieuw-meldingen.
--
-- Drie sloten, zodat het niet opnieuw kan:
--   1. bij een rolwissel gaan lidmaatschap en aangenomen taken mee;
--   2. de meldingstrigger kijkt óók naar de profielrol, niet alleen naar de
--      rol in de kring;
--   3. een hulpvrager kan geen taak meer aannemen.
-- Daarna wordt de bestaande scheefstand rechtgezet.

-- ---------------------------------------------------------------------------
-- 1. Lidmaatschap volgt de rol
-- ---------------------------------------------------------------------------

/**
 * Zet de lidmaatschappen van iemand recht na een rolwissel.
 *
 * In je eigen kring blijf je beheerder, want je bent er de eigenaar van. In
 * kringen van een ander word je "kijkt mee" (hulpvrager) zodra je geen
 * vrijwilliger meer bent; de app kent voor een beheerder of hulpvrager immers
 * geen vrijwilligersscherm. Toekomstige taken die je had aangenomen gaan terug
 * naar open, zodat de kring ze opnieuw kan oppakken in plaats van te rekenen op
 * iemand die ze niet meer ziet.
 *
 * Terugpromoveren naar vrijwilliger gebeurt hier bewust niet: dat loopt via een
 * uitnodiging of aanmelding, zodat de beheerder erover gaat en de gratis limiet
 * blijft gelden.
 */
create or replace function public.sync_member_roles(p_profile uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_role public.user_role;
begin
  select role into v_role from profiles where id = p_profile;
  if v_role is null or v_role = 'vrijwilliger' then
    return;
  end if;

  -- Aangenomen taken teruggeven in kringen die niet van hem zijn.
  update tasks t
  set claimed_by = null, status = 'open'
  where t.claimed_by = p_profile
    and t.status = 'ingepland'
    and t.date >= current_date
    and not exists (select 1 from circles c where c.id = t.circle_id and c.owner_id = p_profile);

  -- Vrijwilligerslidmaatschappen elders worden "kijkt mee".
  update circle_members cm
  set member_role = 'hulpvrager'
  where cm.profile_id = p_profile
    and cm.member_role = 'vrijwilliger'
    and not exists (select 1 from circles c where c.id = cm.circle_id and c.owner_id = p_profile);
end;
$$;
revoke execute on function public.sync_member_roles(uuid) from public, anon;

create or replace function public.change_role(p_role text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_current public.user_role;
begin
  if p_role not in ('beheerder', 'vrijwilliger', 'hulpvrager') then
    raise exception 'ongeldige_rol';
  end if;
  select role into v_current from profiles where id = auth.uid();
  if v_current in ('admin', 'makelaar') then
    raise exception 'rol_kan_niet_wijzigen';
  end if;
  perform set_config('tvz.rol_wijziging', 'toegestaan', true);
  update profiles set role = p_role::public.user_role where id = auth.uid();
  -- Lidmaatschap en aangenomen taken meenemen, anders blijven er
  -- vrijwilligersmeldingen binnenkomen bij iemand die dat niet meer is.
  perform public.sync_member_roles(auth.uid());
end;
$$;

create or replace function public.redeem_circle_code(p_code text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
  v_role public.user_role;
begin
  select id into v_circle from circles where link_code = upper(trim(p_code));
  if v_circle is null then
    raise exception 'code_onbekend';
  end if;

  select role into v_role from profiles where id = auth.uid();
  if v_role is distinct from 'hulpvrager' and v_role not in ('admin', 'makelaar') then
    perform set_config('tvz.rol_wijziging', 'toegestaan', true);
    update profiles set role = 'hulpvrager' where id = auth.uid();
  end if;

  insert into circle_members (circle_id, profile_id, member_role, status)
  values (v_circle, auth.uid(), 'hulpvrager', 'kijkt_mee')
  on conflict (circle_id, profile_id) do nothing;

  perform public.sync_member_roles(auth.uid());
  return v_circle;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. De meldingstrigger kijkt ook naar de profielrol
-- ---------------------------------------------------------------------------

create or replace function public.trg_task_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  member record;
begin
  if new.status <> 'open' then return new; end if;
  -- kopieën uit een weekreeks niet apart melden (de eerste taak meldt al)
  if new.series_id is not null then return new; end if;
  for member in
    select cm.profile_id from circle_members cm
    join profiles p on p.id = cm.profile_id
    where cm.circle_id = new.circle_id
      and cm.member_role = 'vrijwilliger'
      and cm.status = 'actief'
      and cm.profile_id <> new.created_by
      -- vangnet: alleen wie ook echt vrijwilliger ís krijgt taakmeldingen
      and p.role = 'vrijwilliger'
  loop
    perform public.notify(
      member.profile_id, 'taak_nieuw', 'Nieuwe taak in je kring',
      public.task_label(new.type, new.custom_label) || ' · ' ||
        to_char(new.date, 'DD-MM') || ' om ' || to_char(new.time, 'HH24:MI'),
      'tvz://rooster'
    );
  end loop;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Een hulpvrager kan geen taak aannemen
-- ---------------------------------------------------------------------------

-- De beheerder van de kring mag dat wél: hij pakt in zijn eigen kring soms zelf
-- een taak op, en de meldingstrigger houdt daar al rekening mee.
create or replace function public.claim_task(p_task uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
  v_role public.user_role;
begin
  select circle_id into v_circle from tasks where id = p_task;
  if v_circle is null or not public.is_circle_member(v_circle) then
    raise exception 'geen_lid_van_kring';
  end if;
  select role into v_role from profiles where id = auth.uid();
  if v_role = 'hulpvrager' and not public.is_circle_beheerder(v_circle) then
    raise exception 'hulpvrager_neemt_geen_taken_aan';
  end if;
  update tasks
  set claimed_by = auth.uid(), status = 'ingepland'
  where id = p_task and status = 'open' and claimed_by is null;
  return found;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Bestaande scheefstand rechtzetten
-- ---------------------------------------------------------------------------

-- Taken teruggeven en lidmaatschappen bijwerken van iedereen die geen
-- vrijwilliger (meer) is.
do $$
declare
  r record;
begin
  for r in select id from profiles where role is not null and role <> 'vrijwilliger'
  loop
    perform public.sync_member_roles(r.id);
  end loop;
end;
$$;

-- Al verstuurde taakmeldingen bij wie ze niet hoorde weghalen: "Nieuwe taak in
-- je kring" bij iemand die geen vrijwilliger is, en herinneringen aan taken die
-- hierboven zijn teruggegeven.
delete from public.notifications n
using public.profiles p
where p.id = n.profile_id
  and n.kind in ('taak_nieuw', 'taak_geannuleerd')
  and p.role is distinct from 'vrijwilliger';
