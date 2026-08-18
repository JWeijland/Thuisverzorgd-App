-- De kring begint bij de naaste zelf, ook zonder eigen account of koppelcode
-- (wens Jelle 18-08). De beheerder geeft in de kringopbouw naam en adres op;
-- die horen bij de kring, niet bij een profiel. Koppelen met een code blijft
-- kunnen, maar is een extraatje voor als de naaste de app zelf gebruikt.
--
-- `address` en `location` bestonden al op circles (met de afrond-trigger voor
-- location_rounded); alleen wie de naaste ís, ontbrak nog.

alter table public.circles
  add column if not exists naaste_naam text,
  add column if not exists naaste_relatie text,
  add column if not exists naaste_info text;

comment on column public.circles.naaste_naam is
  'Naam van degene voor wie de kring is, uit de kringopbouw. Los van een eventueel gekoppeld hulpvrager-account.';
comment on column public.circles.naaste_relatie is
  'Relatie van de beheerder tot de naaste (moeder, buurman, ...).';
comment on column public.circles.naaste_info is
  'Goed om te weten voor de kring, in de woorden van de beheerder.';
