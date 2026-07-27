# Self-review Fase 11 (BLOK 4)

Datum: 28 juli 2026. Uitgevoerd na afronding van fase 1 t/m 10.

## 1. RLS-controle
Het uitvoerbare bewijs is `apps/mobile/scripts/rls-smoke.mjs`, laatst groen gedraaid tegen het live project (23 checks): niet-lid ziet geen kringen/taken/chat/leden/conceptplanning, kan niets claimen en ziet profielen van vreemden niet; adres van directe hulp pas na acceptatie; gratis limiet server-side; eigen rol niet te wijzigen; claim race-veilig. Aanvullend handmatig nagelopen: nieuwe views uit fase 8/11 (`v_forum_*`, `v_broker_chat_overview`, `v_report_overview`, `v_invitation_detail`) hebben allemaal een auth-filter in de WHERE-clausule; `v_buddy_cards`/`v_map_*` tonen uitsluitend voornaam + wijkniveau. Admin-rol heeft nergens tabel-policies.

**Bevinding (laag risico):** de smoke-test dekt de fase 8/11-views nog niet; toegevoegd aan de checklist hieronder.

## 2. Schermen versus docs/design/screens
| Screen | Status | Afwijkingen |
|---|---|---|
| 01–03 welkom/account/rolkeuze | ✅ | — |
| 04 rondleiding | ✅ | wolkje staat onderaan boven de tabbalk (ontwerp toont hem bovenin bij stap 1); pijl wijst correct naar de tab |
| 05–06 rooster + taakplanner | ✅ | tijdkiezer is chips + vrij veld i.p.v. native picker |
| 07 weekplanning | ✅ | — |
| 08–09 buurtkaart + directe hulp beheerder | ✅ | compose-kaart heeft extra adresveld (nodig omdat het adres anders nergens vandaan komt) |
| 10–11 kring berichten/leden | ✅ | — |
| 12 abonnement | ✅ | extra pilot-notitie ("er wordt nog niets afgeschreven") — bewust, eerlijkheid |
| 13–14 forum + makelaar-chat | ✅ | typ-indicator (stuiterende bolletjes) niet gebouwd; presence-teller is wél echt |
| 15 inbox | ✅ | — |
| 16 aanvraag beoordelen | ⚠️ | gebouwd, maar "Start videokennismaking" is in de pilot een afvink-knop; echte call vereist Daily.co-account (open punt) |
| 17 profiel beheerder | ✅ | — |
| 18 id-en-foto | ✅ | — |
| 19–21 rooster/kaart/directe hulp vrijwilliger | ✅ | — |
| 22 videokennismaking | ❌ | niet gebouwd — wacht op Daily.co API-key (zie Open punten in PLAN.md) |
| 23 profiel vrijwilliger | ✅ | — |
| 24 hulpvrager vandaag | ✅ | — |
| 25 admin | ✅ | — |

## 3. Dode code, any-types, fouten
- `grep ": any"` → 0 treffers buiten tests; `console.log` → 0; `TODO/FIXME` → 0.
- Typecheck, ESLint en alle 29 tests groen; CI draait bij elke push.
- `src/app/dev/ui.tsx` bevat bewust hardcoded strings (dev-only showcase, geen productie-flow).
- Ongebruikte template-assets (expo icon-set) staan nog in `assets/` — bewust, tot de echte app-iconen uit het brandbook zijn aangeleverd.

## 4. i18n-controle
Alle productie-copy komt uit `src/i18n/nl.json` (geldige JSON, ~190 sleutels). Steekproef op Engelse teksten: geen treffers in productie-schermen. Meldingsteksten leven bewust in de database-triggers (Nederlands); bij een latere tweede taal moeten die mee.

## 5. Blokkerend en opgelost in deze fase
- **Screen 16 ontbrak** → gebouwd (`/aanvraag/[id]`), inclusief deeplink vanuit de uitnodigings-notificatie en waardering/ervaring uit `v_invitation_detail`.
- **Account verwijderen ontbrak (App Store 5.1.1(v))** → edge function `delete-account` + bevestigingssheet op het profiel; wist ook opslag.
- **ID-bewaartermijn** → dagelijkse `cleanup-id-documents` (pg_cron, 03:00) verwijdert documenten ouder dan 30 dagen.

## 6. Bewust open (voor de volgende iteratie)
1. **Videokennismaking (Daily.co)** — vereist een Daily-account/API-key; edge function + UI zoals gepland in ADR-0003.
2. **RevenueCat + Apple IAP** (ADR-0002) — vóór publieke release met betaald abonnement.
3. **Sentry** — toevoegen tijdens de build-sessie (vereist DSN + auth-token voor sourcemaps).
4. **Agenda-koppeling** — voorkeur wordt opgeslagen; echte EventKit-sync nog te bouwen.
5. **Maestro e2e-flows** — de twee flows uit de superprompt staan nog open; unit/integratielaag is gedekt.
6. **Typ-indicator** in de makelaar-chat; **formeel ruilen** van taken (v1.1); RLS-smoke uitbreiden met fase 8/11-views.
7. **App-iconen/splash** vervangen door de echte brand-assets (SVG's uit het brandbook).
