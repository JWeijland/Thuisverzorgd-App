-- Feedback 30-07: een vrijwilliger kan zich vanaf de kaart aanmelden bij een
-- hulpkring. Dat wordt een aanvraag (kind = 'aanvraag'); de beheerder beslist,
-- precies zoals bij "Best matches" al gebeurde. De RPC geeft nette fouten en
-- voorkomt dubbele aanvragen.

create or replace function public.request_to_join_circle(
  p_circle uuid,
  p_message text default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_role public.user_role;
  v_verified boolean;
  v_id uuid;
begin
  select role, id_verified into v_role, v_verified from profiles where id = auth.uid();
  if v_role is distinct from 'vrijwilliger' then
    raise exception 'alleen_vrijwilliger';
  end if;
  if not coalesce(v_verified, false) then
    raise exception 'id_check_nodig';
  end if;
  if not exists (select 1 from circles where id = p_circle) then
    raise exception 'kring_bestaat_niet';
  end if;
  if exists (
    select 1 from circle_members
    where circle_id = p_circle and profile_id = auth.uid() and status = 'actief'
  ) then
    raise exception 'al_lid';
  end if;

  -- Bestaat er al een open aanvraag? Dan die teruggeven (geen dubbele meldingen).
  select id into v_id from invitations
  where circle_id = p_circle and profile_id = auth.uid()
    and kind = 'aanvraag' and status = 'open'
  limit 1;
  if v_id is not null then
    return v_id;
  end if;

  insert into invitations (circle_id, kind, profile_id, invited_by, message)
  values (p_circle, 'aanvraag', auth.uid(), auth.uid(), nullif(trim(coalesce(p_message, '')), ''))
  returning id into v_id;
  return v_id;
end;
$$;

-- De kaart laat zien of je al lid bent of al een aanvraag hebt lopen, zodat de
-- knop de juiste tekst kan tonen.
create or replace function public.my_circle_status(p_circle uuid)
returns text
language sql stable security definer set search_path = public as $$
  select case
    when exists (
      select 1 from circle_members
      where circle_id = p_circle and profile_id = auth.uid() and status = 'actief'
    ) then 'lid'
    when exists (
      select 1 from invitations
      where circle_id = p_circle and profile_id = auth.uid()
        and kind = 'aanvraag' and status = 'open'
    ) then 'aangevraagd'
    else 'geen'
  end;
$$;
