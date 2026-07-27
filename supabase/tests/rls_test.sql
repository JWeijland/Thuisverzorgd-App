-- pgTAP-tests voor RLS. Draaien met `supabase test db` (vereist Docker).
-- Het uitvoerbare bewijs draait nu al via apps/mobile/scripts/rls-smoke.mjs
-- tegen het gekoppelde project; dit bestand is de CI-variant voor later.
begin;
select plan(6);

-- RLS staat aan op alle kerntabellen
select ok((select relrowsecurity from pg_class where oid = 'public.circles'::regclass), 'RLS aan op circles');
select ok((select relrowsecurity from pg_class where oid = 'public.tasks'::regclass), 'RLS aan op tasks');
select ok((select relrowsecurity from pg_class where oid = 'public.messages'::regclass), 'RLS aan op messages');
select ok((select relrowsecurity from pg_class where oid = 'public.task_drafts'::regclass), 'RLS aan op task_drafts');
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass), 'RLS aan op profiles');

-- Anon (uitgelogd) ziet niets in circles
set local role anon;
select is((select count(*) from public.circles), 0::bigint, 'anon ziet geen kringen');

select * from finish();
rollback;
