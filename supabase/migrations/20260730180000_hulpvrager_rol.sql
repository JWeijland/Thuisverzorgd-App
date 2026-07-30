-- De hulpvrager-rol bleef soms leeg staan (feedback 30-07): het zetten van de
-- rol gebeurde in de app met een directe update, die door de rol-trigger kan
-- worden geblokkeerd. Nu zet de koppelcode-RPC de rol zelf, zodat "kijkt mee"
-- altijd samengaat met de rol hulpvrager.

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
    -- Trigger toestaan dat de rol wijzigt (zelfde route als change_role).
    perform set_config('tvz.rol_wijziging', 'toegestaan', true);
    update profiles set role = 'hulpvrager' where id = auth.uid();
  end if;

  insert into circle_members (circle_id, profile_id, member_role, status)
  values (v_circle, auth.uid(), 'hulpvrager', 'kijkt_mee')
  on conflict (circle_id, profile_id) do nothing;
  return v_circle;
end;
$$;
