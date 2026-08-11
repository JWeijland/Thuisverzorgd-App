-- Je kon je wel aanmelden bij een kring, maar die aanmelding niet meer
-- terugnemen (feedback Jelle 11-08). Zolang de beheerder nog niets heeft
-- besloten, hoor je je woord te kunnen terugnemen; daarna ben je lid en
-- verlaat je de kring op de gewone manier.

create or replace function public.trek_aanmelding_in(p_circle uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update invitations
  set status = 'ingetrokken'
  where circle_id = p_circle
    and profile_id = auth.uid()
    and kind = 'aanvraag'
    and status = 'open';

  return found;
end;
$$;

revoke all on function public.trek_aanmelding_in(uuid) from public;
grant execute on function public.trek_aanmelding_in(uuid) to authenticated;

comment on function public.trek_aanmelding_in(uuid) is
  'Vrijwilliger trekt zijn eigen, nog onbeantwoorde aanmelding bij een kring in.';
