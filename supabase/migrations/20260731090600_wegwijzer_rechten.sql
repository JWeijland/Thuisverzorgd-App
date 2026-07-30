-- Uitvoerrechten op de Wegwijzer-functies dichtzetten.
--
-- Postgres geeft nieuwe functies standaard EXECUTE aan PUBLIC. `revoke ... from
-- anon` haalt die grant niet weg, want anon erft hem via PUBLIC. Daarom eerst
-- PUBLIC intrekken en daarna gericht toekennen aan ingelogde gebruikers.
--
-- De zoekfunctie draait als aanroeper, dus RLS gaf anon sowieso al nul rijen.
-- De schrijvende functies draaien als definer en controleren zelf op auth.uid(),
-- maar ook die zetten we op slot: verdediging in de diepte.

revoke execute on function public.search_wegwijzer(text, integer) from public, anon;
revoke execute on function public.wegwijzer_suggesties(text, integer) from public, anon;
revoke execute on function public.wegwijzer_tsquery(text) from public, anon;
revoke execute on function public.toggle_guide_bookmark(uuid) from public, anon;
revoke execute on function public.mark_guide_read(uuid) from public, anon;
revoke execute on function public.log_guide_search(text, integer) from public, anon;

grant execute on function public.search_wegwijzer(text, integer) to authenticated;
grant execute on function public.wegwijzer_suggesties(text, integer) to authenticated;
grant execute on function public.wegwijzer_tsquery(text) to authenticated;
grant execute on function public.toggle_guide_bookmark(uuid) to authenticated;
grant execute on function public.mark_guide_read(uuid) to authenticated;
grant execute on function public.log_guide_search(text, integer) to authenticated;
