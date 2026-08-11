-- Handoff, scherm 06: taak inplannen kent nu drie herhalingen, eenmalig,
-- elke week en elke twee weken. Een enum-waarde toevoegen staat in een eigen
-- migratie omdat je hem niet mag gebruiken in dezelfde transactie waarin je
-- hem aanmaakt; de reeks-trigger die hem gebruikt staat hieronder los.
alter type public.task_recurrence add value if not exists 'tweewekelijks';
