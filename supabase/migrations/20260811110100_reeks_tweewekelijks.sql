-- De reeks-trigger kende alleen "wekelijks". Nu plant hij ook een reeks van
-- acht keer bij "elke twee weken", met veertien dagen ertussen. Verder
-- ongewijzigd: de eerste taak is de reeks-kop, de zeven volgende hangen
-- eraan zodat je ze in één keer kunt intrekken.
create or replace function public.trg_task_series()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  i integer;
  v_dagen integer;
begin
  if new.recurrence in ('wekelijks', 'tweewekelijks') and new.series_id is null then
    v_dagen := case when new.recurrence = 'tweewekelijks' then 14 else 7 end;
    update tasks set series_id = new.id where id = new.id;
    for i in 1..7 loop
      insert into tasks (circle_id, type, custom_label, date, time, recurrence, series_id, created_by)
      values (new.circle_id, new.type, new.custom_label, new.date + (i * v_dagen), new.time,
              new.recurrence, new.id, new.created_by);
    end loop;
  end if;
  return new;
end;
$$;
