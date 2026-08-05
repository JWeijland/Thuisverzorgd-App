-- Feedback 05-08: het adres voor directe hulp hoeft maar één keer ingevuld te
-- worden. Het staat op het profiel en wordt bij een volgende aanvraag alvast
-- ingevuld. Alleen de eigenaar leest/schrijft het (bestaande profiles-RLS);
-- de kaart toont het nooit — daar gaat alleen de (vervaagde) coördinaat heen.

alter table public.profiles
  add column if not exists street_address text;
