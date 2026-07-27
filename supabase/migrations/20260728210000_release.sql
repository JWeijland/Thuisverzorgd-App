-- Fase 11 · Release: aanvraag-deeplinks, uitnodigingsdetail-view en de
-- dagelijkse opruiming van ID-documenten (30 dagen, ADR-0005).

create extension if not exists pg_cron;

-- Uitnodigingen/aanvragen linken voortaan direct naar het beoordeel-scherm.
create or replace function public.trg_invitation_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_circle_name text;
begin
  select owner_id, name into v_owner, v_circle_name from circles where id = new.circle_id;
  if new.kind = 'uitnodiging' and new.profile_id is not null then
    perform public.notify(
      new.profile_id, 'uitnodiging', 'Uitnodiging voor ' || v_circle_name,
      coalesce(new.message, public.first_name(new.invited_by) || ' nodigt je uit als vrijwilliger.'),
      'tvz://aanvraag/' || new.id
    );
  elsif new.kind = 'aanvraag' then
    perform public.notify(
      v_owner, 'uitnodiging', 'Aanvraag voor je kring',
      public.first_name(new.profile_id) || ' wil zich aansluiten en stuurde een voorstelbericht mee.',
      'tvz://aanvraag/' || new.id
    );
  end if;
  return new;
end;
$$;

-- Detail voor het beoordeel-scherm: uitnodiging + buddy-kaart in één rij.
create view public.v_invitation_detail as
select
  i.id,
  i.circle_id,
  i.kind,
  i.status,
  i.message,
  i.video_done,
  i.created_at,
  c.name as kring_naam,
  c.owner_id,
  i.profile_id,
  split_part(p.name, ' ', 1) as voornaam,
  p.city,
  p.helped_count,
  p.id_verified,
  (select round(avg(score)::numeric, 1) from public.reviews rv where rv.volunteer_id = p.id)
    as waardering,
  (select count(distinct cm.circle_id) from public.circle_members cm
     where cm.profile_id = p.id and cm.status = 'actief' and cm.member_role = 'vrijwilliger')
    as kringen
from public.invitations i
join public.circles c on c.id = i.circle_id
left join public.profiles p on p.id = i.profile_id
where i.profile_id = auth.uid()
   or i.invited_by = auth.uid()
   or c.owner_id = auth.uid();
revoke all on public.v_invitation_detail from anon;

-- Videokennismaking afvinken (pilot: markering; echte call volgt met Daily.co).
create or replace function public.mark_invitation_video_done(p_invitation uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  update invitations set video_done = true
  where id = p_invitation
    and (profile_id = auth.uid() or public.is_circle_beheerder(circle_id));
end;
$$;

-- Dagelijkse opruiming van ID-documenten ouder dan 30 dagen (03:00 UTC).
select cron.schedule(
  'cleanup-id-documents',
  '0 3 * * *',
  $$
  select net.http_post(
    url := 'https://pfvxgzosntzzhydzzkaj.supabase.co/functions/v1/cleanup-id-documents',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmdnhnem9zbnR6emh5ZHp6a2FqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxODg4NjYsImV4cCI6MjEwMDc2NDg2Nn0.5Ysv9ecPa5FhAotGogpBdmqsXJc1WRfNXIB-ietD78w'
    ),
    body := '{}'::jsonb
  );
  $$
);
