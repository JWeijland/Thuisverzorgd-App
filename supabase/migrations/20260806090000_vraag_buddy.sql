-- Ontwerp 4.0: de hulpvrager kan zelf een buddy vragen. De vraag wordt een
-- open taak in de eigen kring (de rode draad: alles eindigt als een afspraak
-- in de week). Insert-policy op tasks blijft beheerder-only; deze RPC is de
-- ene, afgebakende uitzondering en dwingt zelf de grenzen af.

create or replace function public.vraag_buddy(
  p_circle uuid,
  p_type public.task_type,
  p_custom text default null,
  p_date date default null,
  p_time time default '10:00'
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task uuid;
begin
  -- Alleen de hulpvrager (of beheerder) van deze kring mag dit.
  if not exists (
    select 1 from circle_members
    where circle_id = p_circle
      and profile_id = auth.uid()
      and member_role in ('hulpvrager', 'beheerder')
  ) then
    raise exception 'geen_lid_van_kring';
  end if;

  insert into tasks (circle_id, type, custom_label, date, time, recurrence, status, created_by)
  values (
    p_circle,
    p_type,
    case when p_type = 'anders' then p_custom else null end,
    coalesce(p_date, current_date + 1),
    p_time,
    'eenmalig',
    'open',
    auth.uid()
  )
  returning id into v_task;

  return v_task;
end;
$$;

revoke all on function public.vraag_buddy(uuid, public.task_type, text, date, time) from public;
grant execute on function public.vraag_buddy(uuid, public.task_type, text, date, time) to authenticated;
