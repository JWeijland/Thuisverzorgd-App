-- ===========================================================================
-- fase31_field_visibility.sql
--
-- Punt 13 (feedback batch 2): per persoonlijk gegeven regelen of het zichtbaar is
-- voor anderen / op je openbare profiel. Postcode/buurt wil niet iedereen delen,
-- dus die staat standaard privé.
--
-- Buddy (buddy_profiles):  shows_bio, shows_neighborhood, shows_birthdate
-- Oudere (elderly_profiles): shows_phone, shows_address, shows_birthdate
--
-- Puur voorkeurskolommen (geen RLS-wijziging): de app respecteert ze bij het
-- tonen van profielgegevens aan anderen.
-- ===========================================================================

alter table public.buddy_profiles
    add column if not exists shows_bio          boolean not null default true,
    add column if not exists shows_neighborhood boolean not null default false,
    add column if not exists shows_birthdate    boolean not null default true;

alter table public.elderly_profiles
    add column if not exists shows_phone     boolean not null default false,
    add column if not exists shows_address   boolean not null default false,
    add column if not exists shows_birthdate boolean not null default true;
