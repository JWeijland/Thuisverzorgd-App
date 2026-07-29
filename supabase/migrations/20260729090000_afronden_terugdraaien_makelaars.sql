-- Drie dingen uit de feedbackronde van 29-07:
-- 1. Afronden kan pas vanaf de afgesproken tijd (Nederlandse tijd, server-side afgedwongen).
-- 2. Een afgeronde taak is terug te draaien zolang je hem zelf had aangenomen.
-- 3. Hulpmakelaars zijn met naam + profielfoto zichtbaar voor iedereen (voor de chat).

-- 1. complete_task: weiger afronden vóór de afgesproken datum + tijd.
create or replace function public.complete_task(p_task uuid, p_note text default null)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_circle uuid;
  v_start timestamp;
begin
  select circle_id, (date + time) into v_circle, v_start from tasks
  where id = p_task and claimed_by = auth.uid() and status = 'ingepland';
  if v_circle is null then
    return false;
  end if;
  if v_start > (now() at time zone 'Europe/Amsterdam') then
    raise exception 'nog_niet_begonnen';
  end if;
  update tasks set status = 'gedaan' where id = p_task;
  if p_note is not null and length(trim(p_note)) > 0 then
    insert into task_logs (task_id, circle_id, author_id, note)
    values (p_task, v_circle, auth.uid(), trim(p_note));
  end if;
  update profiles set helped_count = helped_count + 1 where id = auth.uid();
  return true;
end;
$$;

-- 2. Terugdraaien: "gedaan" wordt weer "ingepland"; logboeknotitie en teller gaan mee terug.
create or replace function public.uncomplete_task(p_task uuid)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  update tasks set status = 'ingepland'
  where id = p_task and claimed_by = auth.uid() and status = 'gedaan';
  if not found then
    return false;
  end if;
  delete from task_logs where task_id = p_task and author_id = auth.uid();
  update profiles set helped_count = greatest(helped_count - 1, 0) where id = auth.uid();
  return true;
end;
$$;

-- 3a. Hulpmakelaars zichtbaar voor ingelogde gebruikers (alleen voornaam + foto-pad).
create view public.v_makelaars as
select
  pr.id,
  split_part(pr.name, ' ', 1) as voornaam,
  pr.avatar_path
from public.profiles pr
where pr.role = 'makelaar';
revoke all on public.v_makelaars from anon;

-- 3b. Hun profielfoto's mogen door iedereen (ingelogd) gelezen worden.
create policy "avatars makelaars lezen" on storage.objects
  for select
  using (
    bucket_id = 'avatars'
    and exists (
      select 1 from public.profiles pr
      where pr.id::text = (storage.foldername(name))[1] and pr.role = 'makelaar'
    )
  );
