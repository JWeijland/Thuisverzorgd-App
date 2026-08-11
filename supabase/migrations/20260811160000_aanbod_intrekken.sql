-- Een vrijwilliger kon zijn aanbod niet meer intrekken (feedback Jelle
-- 11-08). Dat hoort wel te kunnen: je biedt aan, er verandert iets, en dan
-- moet je je woord kunnen terugnemen zolang de aanvrager je nog niet heeft
-- gekozen. Is het aanbod al geaccepteerd, dan annuleer je de afspraak
-- (cancel_request), want dan zit er iemand op je te wachten.

create or replace function public.trek_aanbod_in(p_offer uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request uuid;
begin
  delete from request_offers
  where id = p_offer
    and volunteer_id = auth.uid()
    and status = 'aangeboden'
  returning request_id into v_request;

  if v_request is null then
    return false;
  end if;

  -- Was dit het laatste openstaande aanbod? Dan staat de vraag weer gewoon
  -- open, zodat een andere buddy hem nog ziet.
  update spontaneous_requests r
  set status = 'open'
  where r.id = v_request
    and r.status = 'aanbod'
    and not exists (
      select 1 from request_offers o
      where o.request_id = r.id and o.status = 'aangeboden'
    );

  return true;
end;
$$;

revoke all on function public.trek_aanbod_in(uuid) from public;
grant execute on function public.trek_aanbod_in(uuid) to authenticated;

comment on function public.trek_aanbod_in(uuid) is
  'Vrijwilliger trekt zijn eigen, nog niet geaccepteerde aanbod in; de hulpvraag komt weer open te staan.';
