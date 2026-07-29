-- Rol wijzigen vanuit de app (feedback 29-07): de rolkeuze belooft "je kunt dit
-- later altijd aanpassen", maar de trigger blokkeerde elke wijziging. Wisselen
-- tussen beheerder/vrijwilliger/hulpvrager kan nu via een RPC; admin en
-- makelaar blijven onbereikbaar en onveranderbaar voor gebruikers zelf.

-- Trigger laat de wijziging door wanneer de RPC dat expliciet aangeeft.
create or replace function public.prevent_role_change()
returns trigger
language plpgsql
as $$
begin
  if old.role is not null
     and new.role is distinct from old.role
     and coalesce(auth.jwt() ->> 'role', '') <> 'service_role'
     and coalesce(current_setting('tvz.rol_wijziging', true), '') <> 'toegestaan' then
    raise exception 'rol_kan_niet_wijzigen';
  end if;
  return new;
end;
$$;

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
end;
$$;
