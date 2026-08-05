# Thuisverzorgd — werkafspraken

Nederlandse app die mantelzorgers ontlast door hulp uit de buurt te organiseren (hulpkringen).

## Leidende documenten
- **`docs/design/README.md` + `docs/design/screens/*.png` zijn de leidende specificatie.** Bouw schermen pixel-precies na; neem waarden (kleuren, radii, copy) letterlijk over. Bij twijfel: eerst handoff, dan brandbook (`docs/design/reference/…Brand-Guidelines…pdf`), dan vragen.
- `docs/PLAN.md` — gefaseerd plan + voortgang. Bijwerken na elke afgeronde stap.
- `docs/ANALYSE.md` — legacy-inventarisatie en scope-besluiten.
- `docs/ADR/` — één kort bestand per technische beslissing.
- `docs/legacy-swift/` — oude SwiftUI-app, alleen referentie. Geen code overnemen.

## Stack
Expo SDK 57 + expo-router (file-based), TypeScript strict. Supabase (Postgres/Auth magic link/Realtime/Storage/Edge Functions), project-ref `pfvxgzosntzzhydzzkaj`. TanStack Query (server-state) + Zustand (UI-state), react-hook-form + zod. Eigen `theme.ts` + primitives, géén UI-library. Kaart: react-native-maps achter eigen wrapper. Video: Daily.co. Tests: Jest (jest-expo) + RNTL.

## Structuur
- `apps/mobile/` — de app; routes in `src/app/`, code in `src/{theme,ui,features,lib,i18n}`
- `supabase/` — genummerde migraties + edge functions; nooit handmatig in de dashboard-UI klikken
- Absolute imports via `@/…`

## Regels
- Alle UI-copy uit `src/i18n/nl.json`, geen hardcoded strings; alleen Nederlands, geen em-dashes in gebruikerscopy.
- Het woord "mantelzorger" nooit in de UI: het heet "beheerder". Geen VOG, geen levels/gamification, geen check-in/check-out.
- Vormregel: vlakken bijna vierkant (radius 8/10/12), alles wat een actie of status is een pill (radius 999). Groen (#8DC93F) is schaars: max één groene CTA per scherm, nooit witte tekst op groen.
- Mascotte Bo (`src/ui/Bo.tsx`, eigen warm palet uit de handoff): max één Bo per scherm, nooit uitrekken, nooit op betaal- of juridische schermen.
- Tapdoelen ≥44pt, body ≥17pt, ouderen-modus schaalt 1,3×.
- RLS op elke tabel; kringdata alleen voor leden; exacte locatie pas na toestemming (daarvoor ~1 km vervaagd); nooit ID-documenten in de database.
- Commits in het Nederlands, klein en per subtaak. Na elke fase: lint + typecheck + test.
- `.env`-bestanden nooit committen. Secrets alleen server-side (Edge Functions).

## Commando's
In `apps/mobile/`: `npm run lint` · `npm run typecheck` · `npm test` · `npm run format`. Supabase: `supabase db push` (migraties naar cloud; Docker ontbreekt lokaal, dus geen `supabase start`).

## Werkwijze met de opdrachtgever
Aan het einde van elke fase: samenvatten wat werkt, PLAN.md bijwerken, en expliciet vragen of we door mogen naar de volgende fase (enter = ja).
