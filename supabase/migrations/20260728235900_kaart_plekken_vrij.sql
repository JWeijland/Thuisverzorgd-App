-- Kaartmarkers tonen per kring hoeveel taken open staan ("+N plekken vrij").
drop view if exists public.v_map_circles;
create view public.v_map_circles as
select
  c.id,
  c.name,
  st_y(c.location_rounded::geometry) as lat,
  st_x(c.location_rounded::geometry) as lon,
  (select count(*)::int from public.tasks t
     where t.circle_id = c.id and t.status = 'open' and t.date >= current_date) as plekken_vrij
from public.circles c
where c.location_rounded is not null;
revoke all on public.v_map_circles from anon;
