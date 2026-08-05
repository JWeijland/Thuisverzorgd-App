-- Handoff voorzieningen (aug 2026): het abonnement verdwijnt volledig.
-- Geen ledenlimiet meer, geen upgrade-schermen, geen IAP; het verdienmodel
-- wordt een transactiefee op geboekte diensten (zie migratie voorzieningen).

drop trigger if exists circle_members_free_limit on public.circle_members;
drop function if exists public.enforce_free_limit();
drop function if exists public.activate_subscription_stub();
drop function if exists public.has_active_subscription(uuid);

-- Nieuw account → alleen nog een profiel; de subscriptions-regel vervalt.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_intern boolean := new.email like '%@tvz.invalid';
begin
  insert into public.profiles (id, email, username, name)
  values (
    new.id,
    case when v_intern then null else new.email end,
    case when v_intern then split_part(new.email, '@', 1) else null end,
    coalesce(new.raw_user_meta_data ->> 'name', '')
  );
  return new;
end;
$$;

drop table if exists public.subscriptions;
drop type if exists public.subscription_status;
