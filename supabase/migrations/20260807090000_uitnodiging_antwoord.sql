-- Workflow-test 07-08: wie een uitnodiging of aanvraag beantwoordde, liet de
-- andere kant in het ongewisse. Voortaan krijgt die een melding terug, en kan
-- er een persoonlijk berichtje mee (nieuw kind: 'uitnodiging_antwoord').

drop function if exists public.respond_invitation(uuid, boolean);

create or replace function public.respond_invitation(
  p_invitation uuid,
  p_accept boolean,
  p_message text default null
)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  inv record;
  v_owner uuid;
  v_circle_name text;
  v_msg text := nullif(trim(coalesce(p_message, '')), '');
begin
  select * into inv from invitations where id = p_invitation and status = 'open';
  if inv is null then
    return false;
  end if;
  select owner_id, name into v_owner, v_circle_name from circles where id = inv.circle_id;

  if inv.kind = 'uitnodiging' then
    -- alleen de uitgenodigde zelf
    if inv.profile_id is distinct from auth.uid() then
      raise exception 'niet_jouw_uitnodiging';
    end if;
    update invitations set status = case when p_accept then 'geaccepteerd' else 'afgewezen' end::invitation_status
    where id = p_invitation;
    if p_accept then
      insert into circle_members (circle_id, profile_id, member_role, status)
      values (inv.circle_id, auth.uid(), 'vrijwilliger', 'actief')
      on conflict (circle_id, profile_id) do update set status = 'actief';
      perform public.notify(
        v_owner, 'uitnodiging_antwoord',
        public.first_name(auth.uid()) || ' doet mee!',
        coalesce(v_msg, public.first_name(auth.uid()) || ' heeft de uitnodiging voor ' ||
          v_circle_name || ' geaccepteerd.'),
        'tvz://kring'
      );
    else
      perform public.notify(
        v_owner, 'uitnodiging_antwoord',
        public.first_name(auth.uid()) || ' kan dit keer niet',
        coalesce(v_msg, 'De uitnodiging voor ' || v_circle_name || ' is afgeslagen.'),
        'tvz://kring'
      );
    end if;
  else
    -- aanvraag: alleen de beheerder van de kring beslist
    if not public.is_circle_beheerder(inv.circle_id) then
      raise exception 'alleen_beheerder';
    end if;
    update invitations set status = case when p_accept then 'geaccepteerd' else 'afgewezen' end::invitation_status
    where id = p_invitation;
    if p_accept then
      insert into circle_members (circle_id, profile_id, member_role, status)
      values (inv.circle_id, inv.profile_id, 'vrijwilliger', 'actief')
      on conflict (circle_id, profile_id) do update set status = 'actief';
      perform public.notify(
        inv.profile_id, 'uitnodiging_antwoord',
        'Welkom in ' || v_circle_name || '!',
        coalesce(v_msg, 'Je aanvraag is geaccepteerd. De kring staat nu voor je klaar.'),
        'tvz://kring'
      );
    else
      perform public.notify(
        inv.profile_id, 'uitnodiging_antwoord',
        'Dit keer niet',
        coalesce(v_msg, 'De beheerder koos dit keer iemand anders. Fijn dat je wilde helpen!'),
        'tvz://buurt'
      );
    end if;
  end if;
  return true;
end;
$$;
