-- Registreren met alleen een gebruikersnaam (feedback 30-07). Supabase Auth
-- werkt met e-mailadressen, dus zo'n account krijgt intern het adres
-- <gebruikersnaam>@tvz.invalid. `.invalid` is door RFC 2606 gereserveerd en
-- bestaat dus nooit echt: er kan nooit per ongeluk mail naartoe.
--
-- Gevolg: zonder e-mailadres is wachtwoordherstel niet mogelijk. Dat staat ook
-- als waarschuwing bij het aanmelden in de app.

alter table public.profiles
  add column if not exists username text;

create unique index if not exists profiles_username_key on public.profiles (lower(username));

-- Nieuw account → profiel. Bij een intern adres wordt de gebruikersnaam
-- overgenomen en blijft het e-mailveld leeg (er is immers geen mailbox).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_intern boolean := new.email like '%@tvz.invalid';
begin
  insert into public.profiles (id, email, username, name)
  values (
    new.id,
    case when v_intern then null else new.email end,
    case when v_intern then split_part(new.email, '@', 1) else null end,
    coalesce(new.raw_user_meta_data ->> 'name', '')
  );
  insert into public.subscriptions (profile_id) values (new.id);
  return new;
end;
$$;

-- Is deze gebruikersnaam nog vrij? Mag vóór het inloggen worden opgevraagd,
-- daarom expliciet ook voor `anon`. Geeft niets anders prijs dan vrij/bezet.
create or replace function public.username_beschikbaar(p_username text)
returns boolean
language sql stable security definer set search_path = public as $$
  select not exists (
    select 1 from public.profiles where lower(username) = lower(trim(p_username))
  );
$$;
grant execute on function public.username_beschikbaar(text) to anon, authenticated;

-- Uitnodigen kan nu ook op gebruikersnaam (naast e-mail en TVZ-ID).
create or replace function public.create_invitation(
  p_circle uuid,
  p_target text,
  p_message text default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_profile uuid;
  v_email text;
  v_id uuid;
  v_target text := trim(p_target);
begin
  if not public.is_circle_beheerder(p_circle) then
    raise exception 'alleen_beheerder';
  end if;

  select id into v_profile from profiles
  where tvz_id = upper(v_target)
     or lower(email) = lower(v_target)
     or lower(username) = lower(v_target)
  limit 1;

  if v_profile is null then
    -- Geen bestaand account: uitnodiging op e-mailadres (mits het op een e-mail lijkt).
    if v_target not like '%@%' then
      raise exception 'niet_gevonden';
    end if;
    v_email := lower(v_target);
  end if;

  if v_profile is not null and exists (
    select 1 from circle_members
    where circle_id = p_circle and profile_id = v_profile and status = 'actief'
  ) then
    raise exception 'al_lid';
  end if;

  insert into invitations (circle_id, kind, profile_id, email, invited_by, message)
  values (p_circle, 'uitnodiging', v_profile, v_email, auth.uid(), p_message)
  returning id into v_id;
  return v_id;
end;
$$;
