-- Admin-inzichten voor een gewoon account (feedback 29-07): de opdrachtgever
-- wil het admin-dashboard op zijn eigen account, zonder zijn normale rol
-- (en daarmee de hele app) kwijt te raken. Daarom een aparte vlag naast de
-- rol; alleen instelbaar via service_role, nooit door gebruikers zelf.

alter table public.profiles
  add column if not exists platform_admin boolean not null default false;

-- Niemand zet deze vlag bij zichzelf aan: alleen service_role mag hem wijzigen.
create or replace function public.prevent_platform_admin_change()
returns trigger
language plpgsql
as $$
begin
  if new.platform_admin is distinct from old.platform_admin
     and coalesce(auth.jwt() ->> 'role', '') <> 'service_role' then
    raise exception 'platform_admin_kan_niet_wijzigen';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_platform_admin on public.profiles;
create trigger profiles_prevent_platform_admin
  before update of platform_admin on public.profiles
  for each row execute function public.prevent_platform_admin_change();

-- Het dashboard (v_admin_*-views) is zichtbaar voor de admin-rol én voor
-- accounts met de vlag; verder geeft de vlag nergens toegang toe.
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and (role = 'admin' or platform_admin)
  );
$$;
