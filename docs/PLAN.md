# PLAN — Thuisverzorgd (Expo / Supabase)

> Gedeelde voortgangsstatus. Wordt bijgewerkt na elke afgeronde stap.
> Leidende specificatie: `docs/design/README.md` + `docs/design/screens/`. Analyse en scope: `docs/ANALYSE.md`.

## Besluiten uit de vragenronde (27-07-2026)

| # | Onderwerp | Besluit |
|---|---|---|
| 1 | Supabase | Nieuw project **"Thuisverzorgd App"** (`pfvxgzosntzzhydzzkaj`, eu-central-1, Pro-org). Eén omgeving voor de pilot; dev lokaal zodra Docker beschikbaar is. |
| 2 | Bundle ID | `nl.thuisverzorgd.app`, appnaam "Thuisverzorgd". Apple team-ID volgt (developer.apple.com → Membership). |
| 3 | EAS | Account `jelleweijlands-team`, project `thuisverzorgd`, ID `fe37e87d-93d5-47bf-8414-2709177f8a0b`. |
| 4 | Deep links | `tvz://` scheme + universal links via `https://thuisverzorgd-website.vercel.app` (voorlopig). |
| 5 | Betalingen | **Uitgesteld.** Abonnementsschermen + gratis-limiet (2 vrijwilligers) wél bouwen; entitlement via `subscriptions`-tabel; echte IAP/RevenueCat later. ADR-0002. |
| 6 | Proefperiode | 1 maand gratis (t.z.t. bij IAP-implementatie). |
| 7 | Abonnement-scope | Per account, geldt voor alle kringen van de beheerder. |
| 8 | Video | Daily.co (ADR-0003). |
| 9 | Kaart | Apple Maps via `react-native-maps`; kaartlaag abstraheren zodat custom style later kan (ADR-0004). |
| 10 | Locatieprivacy | ~1 km vervaging vóór toestemming (afronden op 2 decimalen + jitter), zoals legacy. |
| 11 | Hulpmakelaars | Echte mensen; simpele webconsole (Expo web-route, rol `makelaar`). |
| 12 | Moderatie | Meldingen → e-mail naar moderatie-adres + verwijder-actie in de console. |
| 13 | SOS | Niet in v1. |
| 14 | Hulpvrager | Eigen account (magic link) + koppelcode activeert "kijkt mee". |
| 15 | Taken | Beheerder kan intrekken (met melding); vrijwilliger kan teruggeven (taak weer open). Ruilen v1.1. |
| 16 | Herhaling | Alleen Eenmalig / Elke week (ontwerp is leidend). |
| 17 | ID-check | Pilot: geüpload = geverifieerd. Verificatie-interface pluggable voor latere dienst (ADR-0005). ID-foto's: privé bucket, auto-delete na 30 dagen. |
| 18 | Juridisch | Ik genereer concept-privacybeleid + voorwaarden als startpunt; jurist checkt later. |
| 19 | Taal | NL nu, alles via `i18n/nl.json`; Engels later mogelijk. |
| 20 | Platform | iOS én Android releasen; TestFlight voor eigen gebruik. Min iOS 15+. |
| 21 | Testdata | Seed-data met fictieve namen. |
| 22 | Monitoring | Sentry (gratis tier). |

## Fasering

### Fase 1 — Fundament ✅ (2026-07-27)
- [x] Monorepo-structuur (`apps/mobile`, `supabase/`, `docs/`)
- [x] Expo-app (SDK 57, TypeScript strict, expo-router, src-layout)
- [x] ESLint (eslint-config-expo + prettier) + Prettier + absolute imports (`@/…`)
- [x] Jest (jest-expo) + eerste test draait (datumhelpers rooster)
- [x] EAS-config (development / preview / production) gekoppeld aan EAS-project `fe37e87d`
- [x] `.env` (EXPO_PUBLIC_SUPABASE_URL/ANON_KEY); `.env.example` in git
- [x] Supabase-project aangemaakt én gekoppeld (`supabase link`, ref `pfvxgzosntzzhydzzkaj`); migraties volgen in Fase 3
- [x] CI (GitHub Actions): lint + typecheck + test
- [x] `CLAUDE.md` in de repo-root

### Fase 2 — Designsysteem ✅ (2026-07-28)
- [x] `src/theme/`: theme.ts (kleuren, radii, spacing, gradient), typography.ts, shadows.ts — exact de tokens uit de handoff
- [x] Tekstschaal-provider voor de ouderen-modus (1,3×), door alle primitives gebruikt
- [x] Fonts Baloo 2 (600/700/800), Comic Neue (400/700/italic), Caveat (500/600) via @expo-google-fonts, geladen in root-layout
- [x] Primitives in `src/ui/`: TvzText, Button (primary/cta/outline/outlineOnDark/danger), Pill, Chip, StatusPill, Card (incl. dashed), SectionHeader, Avatar, Toggle, EmptyState, BottomSheet, Coachmark
- [x] `/dev/ui`-scherm met alle primitives (incl. gradient-header, chatbubbels, live ouderen-modus-toggle)
- [x] Animatie-helpers: tvzIn (FadeInDown 280ms), TvzBounce (2.6s-lus), PulseDot (1.8s pulse)
- [x] Componenttests (Button, StatusPill, TvzText) — 11 tests groen

### Fase 3 — Datamodel en RLS
- [ ] Migraties: profiles, circles, circle_members, invitations, tasks, task_drafts, task_logs, spontaneous_requests (PostGIS), request_offers, messages, notifications, forum_posts, forum_replies, forum_reports, broker_chats, broker_messages, subscriptions, audit_log
- [ ] RLS op alles, expliciete policies per rol
- [ ] Locatievervaging (~1 km) vóór toestemming; exact adres pas na akkoord
- [ ] ID: alleen boolean + timestamp in DB; privé bucket met 30-dagen-opruiming
- [ ] Admin: uitsluitend geaggregeerde, geanonimiseerde views
- [ ] SQL-tests die bewijzen dat een niet-lid géén kringdata kan lezen

### Fase 4 — Auth en onboarding
- [ ] Magic-link login + deep link terug in de app
- [ ] Rolkeuze, ID + profielfoto (vrijwilliger, eenmalig, beide verplicht)
- [ ] Rondleiding met Caveat-wolkjes (beheerder 4 / vrijwilliger 3 / hulpvrager 2 stappen)

### Fase 5 — Kring en rooster
- [ ] Kring aanmaken + koppelcode, leden, uitnodigingen, gratis limiet 2
- [ ] Belastingverdeling "Wie doet wat deze maand?", kringchat
- [ ] Rooster: weekstrip, taakplanner (incl. "Anders"), herhaling, conceptplanner + publiceren
- [ ] Claimen, afronden met logboekje, "Uit de kring"
- [ ] Intrekken (beheerder) en teruggeven (vrijwilliger)

### Fase 6 — Buurtkaart en directe hulp
- [ ] Kaart met kringen/buddy's/aanvragen, live teller, zoeken met live filtering
- [ ] Directe hulp: volledige flow beide kanten, realtime, annuleren met bericht

### Fase 7 — Meldingen
- [ ] Push (expo-notifications + Edge Function + Expo Push API), tokens per gebruiker, opruimen bij uitloggen
- [ ] Deeplink-payloads (`tvz://task/<id>` etc.), ook vanuit koude start
- [ ] Inbox op `notifications`-tabel + ongelezen badge
- [ ] Lokale herinnering 1 uur vooraf + persistente taakbanner
- [ ] Alle triggers uit de superprompt; instellingen per categorie; vakantiemodus gerespecteerd

### Fase 8 — Steun & advies
- [ ] Forum: tags, threads, antwoorden, makelaar-badge, melden/blokkeren
- [ ] Live chat met hulpmakelaars + wachtrij + "x online"; makelaar-webconsole

### Fase 9 — Abonnement (aangepast: zonder echte betaling)
- [ ] Abonnementsscherm + entitlement-logica via `subscriptions`-tabel
- [ ] Gratis limiet afdwingen (server-side); upgrade-flow als stub
- [ ] (Later) RevenueCat + Apple IAP + webhook

### Fase 10 — Admin-inzichten
- [ ] Geaggregeerde views + eenvoudig dashboard (Expo web-route, admin-rol)

### Fase 11 — Kwaliteit en release
- [ ] Accessibility: dynamic type, VoiceOver, contrast, tikdoelen ≥44px, ouderen-modus 1,3×
- [ ] Fout- en lege staten overal; account verwijderen; melden/blokkeren
- [ ] Sentry, seed-data, concept-juridische teksten
- [ ] EAS build + submit: TestFlight én Android (interne track)
- [ ] README voor nieuwe ontwikkelaars (< 15 min draaien)

## Voortgangslog
- 2026-07-27: Repo + GitHub opgezet, ANALYSE.md af, vragenronde beantwoord, Supabase-project aangemaakt (`pfvxgzosntzzhydzzkaj`). Fase 1 gestart.

## Open punten / niet vergeten
- Apple team-ID invullen zodra bekend (developer.apple.com → Membership → Team ID).
- Docker installeren voor lokale Supabase-stack (`supabase start`) — tot die tijd migraties via `supabase db push` naar cloud.
- RevenueCat/IAP-implementatie (besluit #5) — vóór publieke release met betaald abonnement.
- Universal links definitief domein (nu vercel-URL).
- Moderatie-e-mailadres bepalen.
