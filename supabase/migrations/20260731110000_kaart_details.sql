-- Kaartdruppels aantikbaar met echte informatie (feedback 31-07).
--
-- De kringdruppel toonde alleen het aantal open taken. Wie erop tikt wil ook
-- weten hoe groot de kring is, dus komt het aantal actieve leden erbij.
-- De hulpstraal-filter uit 20260731100100 blijft staan.

drop view if exists public.v_map_circles;
create view public.v_map_circles as
select
  c.id,
  c.name,
  st_y(c.location_rounded::geometry) as lat,
  st_x(c.location_rounded::geometry) as lon,
  (select count(*)::int from public.tasks t
     where t.circle_id = c.id and t.status = 'open' and t.date >= current_date) as plekken_vrij,
  -- iedereen die actief in de kring zit: beheerder plus de buddy's
  (select count(*)::int from public.circle_members cm
     where cm.circle_id = c.id and cm.status = 'actief') as leden
from public.circles c
where c.location_rounded is not null
  and (
    c.owner_id = auth.uid()
    or exists (
      select 1 from public.circle_members cm
      where cm.circle_id = c.id and cm.profile_id = auth.uid()
    )
    or public.binnen_hulpstraal(auth.uid(), c.location_rounded)
  );
revoke all on public.v_map_circles from anon;
