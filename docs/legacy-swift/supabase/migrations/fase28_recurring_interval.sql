-- Fase 28 — Periodieke hulpvraag: herhaal-interval (elke X weken)
--
-- Legt het herhaalschema van een periodieke hulpvraag vast op de tasks-tabel,
-- inclusief het gekozen weken-interval zodat ook tweewekelijks, driewekelijks
-- enzovoort kan worden opgeslagen. De kolommen zijn nullable: een gewone
-- (eenmalige) hulpvraag laat ze leeg.
--
-- recurring_frequency      : 'daily' | 'every_other_day' | 'weekly'
-- recurring_interval_weeks : alleen zinvol bij 'weekly' (1 = wekelijks, 2 = 2-wekelijks, ...)
-- recurring_end_date       : t/m wanneer de herhaling loopt

alter table public.tasks
    add column if not exists recurring_frequency      text
        check (recurring_frequency in ('daily', 'every_other_day', 'weekly')),
    add column if not exists recurring_interval_weeks integer not null default 1
        check (recurring_interval_weeks between 1 and 8),
    add column if not exists recurring_end_date       date;
