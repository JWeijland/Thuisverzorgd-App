-- Fase 5: uitnodigen op e-mail of TVZ-ID. De lookup moet server-side,
-- want profielen van vreemden zijn (terecht) niet leesbaar via RLS.

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
begin
  if not public.is_circle_beheerder(p_circle) then
    raise exception 'alleen_beheerder';
  end if;

  select id into v_profile from profiles
  where tvz_id = upper(trim(p_target)) or lower(email) = lower(trim(p_target))
  limit 1;

  if v_profile is null then
    -- Geen bestaand account: uitnodiging op e-mailadres (mits het op een e-mail lijkt).
    if trim(p_target) not like '%@%' then
      raise exception 'niet_gevonden';
    end if;
    v_email := lower(trim(p_target));
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
