-- Fase 8 · Steun & advies: forum-views (voornamen zonder profielen open te zetten),
-- makelaar-badge, moderatie-meldingen en de hulpmakelaar-chat.

-- Vraagkaarten: voornaam + plaats + aantal antwoorden; verbergt hidden en geblokkeerden.
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

create view public.v_forum_replies as
select
  r.id,
  r.post_id,
  r.body,
  r.is_broker,
  r.created_at,
  r.author_id,
  split_part(pr.name, ' ', 1) as voornaam
from public.forum_replies r
join public.profiles pr on pr.id = r.author_id
where not r.hidden
  and auth.uid() is not null
  and not exists (
    select 1 from public.user_blocks b
    where b.blocker_id = auth.uid() and b.blocked_id = r.author_id
  );
revoke all on public.v_forum_replies from anon;

-- Antwoorden van hulpmakelaars krijgen automatisch de badge.
create or replace function public.trg_reply_broker_badge()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.is_broker = exists (select 1 from profiles where id = new.author_id and role = 'makelaar');
  return new;
end;
$$;
create trigger forum_replies_broker_badge before insert on public.forum_replies
  for each row execute function public.trg_reply_broker_badge();

-- Melding van gebruikers → alle hulpmakelaars (moderatie binnen 24 uur, App Store-eis).
create or replace function public.trg_report_created()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  broker record;
begin
  for broker in select id from profiles where role = 'makelaar' loop
    perform public.notify(
      broker.id, 'moderatie', 'Nieuwe melding',
      'Een gebruiker heeft inhoud gemeld (' || new.target_kind || '). Bekijk het in de console.',
      'tvz://makelaar'
    );
  end loop;
  return new;
end;
$$;
create trigger forum_reports_notify after insert on public.forum_reports
  for each row execute function public.trg_report_created();

-- Eigen hulpmakelaar-chat ophalen of aanmaken.
create or replace function public.ensure_broker_chat()
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  select id into v_id from broker_chats
  where profile_id = auth.uid() and status = 'open'
  order by created_at desc limit 1;
  if v_id is null then
    insert into broker_chats (profile_id) values (auth.uid()) returning id into v_id;
  end if;
  return v_id;
end;
$$;

-- Overzicht voor de makelaar-console: chats met voornaam en laatste bericht.
create view public.v_broker_chat_overview as
select
  c.id,
  c.status,
  c.created_at,
  split_part(pr.name, ' ', 1) as voornaam,
  (select body from public.broker_messages m
     where m.chat_id = c.id order by m.created_at desc limit 1) as laatste_bericht,
  (select max(m.created_at) from public.broker_messages m where m.chat_id = c.id)
    as laatste_activiteit
from public.broker_chats c
join public.profiles pr on pr.id = c.profile_id
where public.is_makelaar();
revoke all on public.v_broker_chat_overview from anon;

-- Meldingenoverzicht voor de console, met een leesbare samenvatting van het doelwit.
create view public.v_report_overview as
select
  fr.id,
  fr.target_kind,
  fr.target_id,
  fr.reason,
  fr.status,
  fr.created_at,
  case fr.target_kind
    when 'post' then (select left(title, 80) from public.forum_posts where id = fr.target_id)
    when 'reply' then (select left(body, 80) from public.forum_replies where id = fr.target_id)
    else null
  end as samenvatting
from public.forum_reports fr
where public.is_makelaar();
revoke all on public.v_report_overview from anon;

-- Makelaars kunnen gemelde inhoud verbergen (hidden); afhandelen van de melding.
create or replace function public.resolve_report(p_report uuid, p_hide boolean)
returns void
language plpgsql security definer set search_path = public as $$
declare
  r record;
begin
  if not public.is_makelaar() then
    raise exception 'alleen_makelaar';
  end if;
  select * into r from forum_reports where id = p_report;
  if r is null then return; end if;
  if p_hide then
    if r.target_kind = 'post' then
      update forum_posts set hidden = true where id = r.target_id;
    elsif r.target_kind = 'reply' then
      update forum_replies set hidden = true where id = r.target_id;
    end if;
  end if;
  update forum_reports set status = 'afgehandeld' where id = p_report;
end;
$$;
