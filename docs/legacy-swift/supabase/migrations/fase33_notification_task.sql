-- ===========================================================================
-- fase33_notification_task.sql
--
-- Punt 1 (batch 4): een hulpvraag-melding (new_task_nearby / neighborhood_needs_you
-- / help_reminder) moet de buddy naar dat SPECIFIEKE hulpverzoek leiden, waar hij
-- 'm meteen kan aannemen. Daarvoor draagt de melding nu de bijbehorende task_id.
--
-- De push-edge-function die deze meldingen aanmaakt (fase22) kan dit veld vullen
-- met de betreffende taak; zolang dat nog niet gebeurt valt de app netjes terug op
-- de lijst met open hulpvragen (dichtstbij eerst).
-- ===========================================================================

alter table public.notifications
    add column if not exists task_id uuid references public.tasks(id) on delete cascade;

create index if not exists idx_notifications_task on public.notifications(task_id);
