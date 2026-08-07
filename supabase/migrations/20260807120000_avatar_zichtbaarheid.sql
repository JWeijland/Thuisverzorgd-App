-- Fix 07-08: de leespolicies voor profielfoto's (pool-buddy's, makelaars,
-- forumdeelnemers) deden een subquery op profiles, maar die tabel heeft zelf
-- RLS (jezelf + kringgenoten). Voor iedereen buiten de kring matchte de policy
-- dus nooit: de kaart toonde alleen initiaal-cirkels, geen foto's.
-- Oplossing: één security definer-helper die zonder RLS bepaalt of een
-- profielfoto publiek (voor ingelogden) zichtbaar hoort te zijn.

create or replace function public.avatar_publiek_zichtbaar(p_eigenaar text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles pr
    where pr.id::text = p_eigenaar
      and (
        -- zichtbaar op de kaart: pool aan, niet met vakantie
        (pr.role = 'vrijwilliger' and pr.pool_opt_in and not pr.vacation_mode)
        -- hulpmakelaars laten hun gezicht zien
        or pr.role = 'makelaar'
        -- wie iets in het openbare forum plaatst, laat zijn gezicht zien
        or exists (select 1 from forum_posts fp where fp.author_id = pr.id and not fp.hidden)
        or exists (select 1 from forum_replies fr where fr.author_id = pr.id and not fr.hidden)
      )
  );
$$;
revoke all on function public.avatar_publiek_zichtbaar(text) from public;
grant execute on function public.avatar_publiek_zichtbaar(text) to authenticated;

drop policy if exists "avatars pool-buddys lezen" on storage.objects;
drop policy if exists "avatars makelaars lezen" on storage.objects;
drop policy if exists "avatars forumdeelnemers lezen" on storage.objects;

create policy "avatars zichtbare gezichten lezen" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and public.avatar_publiek_zichtbaar((storage.foldername(name))[1])
  );
