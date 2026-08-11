-- Nog een ronde meten: losse kernwoorden werkten, maar algemene werkwoorden
-- uit vragen ("vraag", "regel", "krijg") gedragen zich als kernwoord en kapen
-- het onderwerp. "hoe vraag ik wmo aan" kwam zo uit bij zorgverlof, terwijl
-- het losse woord "wmo" precies goed zit.
--
-- Die werkwoorden gaan daarom mee in de lijst met vulwoorden. "zorg" blijft er
-- bewust buiten: dat is in deze kennisbank juist een kernwoord.

create or replace function public.wegwijzer_kernwoorden(p_vraag text)
returns text
language sql
immutable
set search_path = public
as $$
  select nullif(
    trim(regexp_replace(
      regexp_replace(
        lower(coalesce(p_vraag, '')),
        '\m(' ||
          -- vraagwoorden en voornaamwoorden
          'hoe|wat|wie|waar|waarom|wanneer|welke|welk|' ||
          'ik|je|jij|jou|jouw|mijn|mij|me|we|wij|ons|onze|hij|zij|ze|hun|' ||
          -- lidwoorden, voegwoorden, voorzetsels
          'het|de|een|en|of|als|dan|nog|ook|wel|niet|maar|dat|die|er|' ||
          'aan|van|voor|met|bij|op|in|te|om|naar|uit|over|tot|door|' ||
          -- hulpwerkwoorden en algemene werkwoorden die in bijna elke vraag
          -- staan en dus niets onderscheiden
          'is|zijn|ben|was|word|wordt|worden|heb|heeft|hebben|had|' ||
          'kan|kun|kunt|kunnen|mag|magen|moet|moeten|wil|wilt|willen|' ||
          'doe|doet|doen|ga|gaat|gaan|kom|komt|komen|' ||
          'vraag|vragen|aanvraag|regel|regelt|regelen|krijg|krijgt|krijgen|' ||
          'maak|maakt|maken|weet|weten|zoek|zoekt|zoeken' ||
        ')\M',
        ' ', 'g'
      ),
      '\s+', ' ', 'g'
    )),
    ''
  );
$$;

revoke all on function public.wegwijzer_kernwoorden(text) from public, anon;
grant execute on function public.wegwijzer_kernwoorden(text) to authenticated;
