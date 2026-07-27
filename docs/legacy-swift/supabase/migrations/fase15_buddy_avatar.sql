
-- ============================================================================
-- Fase 15 — Profielfoto voor buddies
-- ----------------------------------------------------------------------------
-- Buddies kunnen een profielfoto uploaden die anderen zien in de competitie- en
-- team-ranglijsten. Foto's in de publieke 'avatars'-bucket; URL op het profiel.
-- Idempotent.
-- ============================================================================

-- Kolom voor de publieke avatar-URL.
alter table public.buddy_profiles
    add column if not exists avatar_url text;

-- Publieke 'avatars'-bucket aanmaken (leesbaar voor iedereen).
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Storage-policies: iedereen mag avatars lezen; een buddy mag alleen z'n eigen
-- bestand (<uid>.jpg) schrijven/wijzigen/verwijderen.
drop policy if exists "Avatars publiek leesbaar" on storage.objects;
create policy "Avatars publiek leesbaar" on storage.objects
    for select using
     (bucket_id = 'avatars');

drop policy if exists "Eigen avatar uploaden" on storage.objects;
create policy "Eigen avatar uploaden" on storage.objects
    for insert with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] is not null
        and name = (select auth.uid())::text || '.jpg'
    );

drop policy if exists "Eigen avatar wijzigen" on storage.objects;
create policy "Eigen avatar wijzigen" on storage.objects
    for update using (
        bucket_id = 'avatars' and name = (select auth.uid())::text || '.jpg'
    );

drop policy if exists "Eigen avatar verwijderen" on storage.objects;
create policy "Eigen avatar verwijderen" on storage.objects
    for delete using (
        bucket_id = 'avatars' and name = (select auth.uid())::text || '.jpg'
    );
