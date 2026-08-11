-- De koppeling ging de verkeerde kant op (feedback Jelle 11-08). Tot nu toe
-- had de kríng een code die de oudere moest overtikken. In de praktijk is het
-- andersom: de oudere zit met de app in zijn hand, leest zijn eigen code voor
-- aan degene die de hulp regelt, en die vult hem in. De code is `tvz_id`, die
-- elk profiel al heeft (TVZ-XXXX).

create or replace function public.koppel_naaste(p_circle uuid, p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profiel uuid;
  v_rol public.user_role;
begin
  if not public.is_circle_beheerder(p_circle) then
    raise exception 'alleen_beheerder';
  end if;

  select id, role into v_profiel, v_rol
  from profiles
  where tvz_id = upper(trim(p_code));

  if v_profiel is null then
    raise exception 'code_onbekend';
  end if;

  if v_profiel = auth.uid() then
    raise exception 'eigen_code';
  end if;

  -- Alleen iemand die zelf "ik ontvang hulp" heeft gekozen kan de hulpvrager
  -- van een kring worden; een buddy koppel je via een uitnodiging.
  if v_rol is distinct from 'hulpvrager' then
    raise exception 'geen_hulpvrager';
  end if;

  -- Eén kring per hulpvrager: anders zien twee beheerders dezelfde persoon.
  if exists (
    select 1 from circle_members
    where profile_id = v_profiel
      and member_role = 'hulpvrager'
      and circle_id <> p_circle
      and status <> 'uitgenodigd'
  ) then
    raise exception 'al_in_kring';
  end if;

  insert into circle_members (circle_id, profile_id, member_role, status)
  values (p_circle, v_profiel, 'hulpvrager', 'kijkt_mee')
  on conflict (circle_id, profile_id) do update
    set member_role = 'hulpvrager', status = 'kijkt_mee';

  perform public.sync_member_roles(v_profiel);
  return v_profiel;
end;
$$;

revoke all on function public.koppel_naaste(uuid, text) from public;
grant execute on function public.koppel_naaste(uuid, text) to authenticated;

comment on function public.koppel_naaste(uuid, text) is
  'Beheerder koppelt de persoon voor wie hij zorgt aan zijn kring, met de persoonlijke code (tvz_id) van die persoon.';
