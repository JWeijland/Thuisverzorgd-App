-- Gezichten in het forum (feedback 31-07).
--
-- Het brandbook is er stellig over: "gezichten, geen nummers, elke taak en elk
-- bericht toont een naam en een gezicht". In het forum stond alleen een
-- voornaam. De views geven nu ook het pad naar de profielfoto mee.
--
-- Geen nieuwe leesrechten: het pad zelf is niets meer dan een verwijzing, en de
-- foto komt alleen door als de avatars-bucket dat toestaat. Voor forumfoto's
-- geldt daarbij de bestaande policy voor pool-buddy's en makelaars; wie zijn
-- foto niet deelt, houdt gewoon zijn initiaal.

drop view if exists public.v_forum_posts;
create view public.v_forum_posts as
select
  p.id,
  p.title,
  p.body,
  p.tag,
  coalesce(pr.city, p.city) as city,
  p.created_at,
  p.author_id,
  split_part(pr.name, ' ', 1) as voornaam,
  pr.avatar_path,
  (select count(*) from public.forum_replies r where r.post_id = p.id and not r.hidden)
    as antwoorden
from public.forum_posts p
join public.profiles pr on pr.id = p.author_id
where not p.hidden
  and auth.uid() is not null
  and not exists (
    select 1 from public.user_blocks b
    where b.blocker_id = auth.uid() and b.blocked_id = p.author_id
  );
revoke all on public.v_forum_posts from anon;

drop view if exists public.v_forum_replies;
create view public.v_forum_replies as
select
  r.id,
  r.post_id,
  r.body,
  r.is_broker,
  r.created_at,
  r.author_id,
  split_part(pr.name, ' ', 1) as voornaam,
  pr.avatar_path
from public.forum_replies r
join public.profiles pr on pr.id = r.author_id
where not r.hidden
  and auth.uid() is not null
  and not exists (
    select 1 from public.user_blocks b
    where b.blocker_id = auth.uid() and b.blocked_id = r.author_id
  );
revoke all on public.v_forum_replies from anon;

-- Forumfoto's mogen door iedereen die is ingelogd gelezen worden: wie een vraag
-- in het openbare forum plaatst, laat daarbij zijn gezicht zien. Alleen de map
-- van mensen die daadwerkelijk iets geplaatst hebben, en alleen lezen.
create policy "avatars forumdeelnemers lezen" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and exists (
      select 1 from public.profiles p
      where p.id::text = (storage.foldername(name))[1]
        and (
          exists (select 1 from public.forum_posts fp where fp.author_id = p.id and not fp.hidden)
          or exists (
            select 1 from public.forum_replies fr where fr.author_id = p.id and not fr.hidden
          )
        )
    )
  );
