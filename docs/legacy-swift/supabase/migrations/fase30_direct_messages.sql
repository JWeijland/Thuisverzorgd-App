-- ===========================================================================
-- fase30_direct_messages.sql
--
-- Punt 10 (feedback batch 2): tikken op een bericht in de inbox moet naar de
-- relevante pagina navigeren. Voor een bericht van een hulpvrager (kind
-- 'elderly_message') openen we een echt 1-op-1 gesprek tussen buddy en oudere.
--
--  1) notifications krijgt sender_id + sender_name, zodat een 'elderly_message'
--     weet met wie het gesprek geopend moet worden.
--  2) direct_messages: de berichten zelf (buddy <-> oudere), met RLS zodat alleen
--     de twee deelnemers ze zien.
--  3) send_direct_message(): bericht opslaan + de ontvanger een inbox-melding
--     geven (atomair, SECURITY DEFINER).
-- ===========================================================================

-- 1) Afzender op de inbox-melding ---------------------------------------------
alter table public.notifications
    add column if not exists sender_id   uuid references public.profiles(id) on delete set null,
    add column if not exists sender_name text;

-- 2) De berichten zelf --------------------------------------------------------
create table if not exists public.direct_messages (
    id           uuid primary key default gen_random_uuid(),
    sender_id    uuid not null references public.profiles(id) on delete cascade,
    recipient_id uuid not null references public.profiles(id) on delete cascade,
    body         text not null,
    read         boolean not null default false,
    created_at   timestamptz not null default now()
);

create index if not exists idx_dm_pair
    on public.direct_messages(sender_id, recipient_id, created_at);
create index if not exists idx_dm_recipient
    on public.direct_messages(recipient_id, created_at desc);

alter table public.direct_messages enable row level security;

-- Alleen de twee deelnemers zien het gesprek.
drop policy if exists "Eigen gesprekken zichtbaar" on public.direct_messages;
create policy "Eigen gesprekken zichtbaar" on public.direct_messages
    for select using (auth.uid() = sender_id or auth.uid() = recipient_id);

-- Je kunt alleen namens jezelf een bericht sturen.
drop policy if exists "Zelf berichten sturen" on public.direct_messages;
create policy "Zelf berichten sturen" on public.direct_messages
    for insert with check (auth.uid() = sender_id);

-- De ontvanger mag zijn eigen berichten op 'gelezen' zetten.
drop policy if exists "Ontvanger markeert gelezen" on public.direct_messages;
create policy "Ontvanger markeert gelezen" on public.direct_messages
    for update using (auth.uid() = recipient_id);

-- 3) Bericht sturen + inbox-melding voor de ontvanger (atomair) ---------------
create or replace function public.send_direct_message(p_recipient uuid, p_body text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    v_sender uuid := auth.uid();
    v_name   text;
    v_msg_id uuid;
begin
    if v_sender is null then
        raise exception 'Niet ingelogd';
    end if;
    if coalesce(btrim(p_body), '') = '' then
        raise exception 'Leeg bericht';
    end if;

    insert into public.direct_messages (sender_id, recipient_id, body)
    values (v_sender, p_recipient, btrim(p_body))
    returning id into v_msg_id;

    select first_name into v_name from public.profiles where id = v_sender;

    insert into public.notifications (user_id, kind, title, body, sender_id, sender_name)
    values (p_recipient,
            'elderly_message',
            'Nieuw bericht van ' || coalesce(v_name, 'iemand'),
            left(btrim(p_body), 120),
            v_sender,
            coalesce(v_name, 'iemand'));

    return v_msg_id;
end;
$$;

grant execute on function public.send_direct_message(uuid, text) to authenticated;
