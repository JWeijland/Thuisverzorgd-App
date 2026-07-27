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

### Fase 3 — Datamodel en RLS ✅ (2026-07-28)
- [x] Migraties (live op cloud-project): profiles, circles, circle_members, invitations, tasks, task_drafts, task_logs, spontaneous_requests (PostGIS), request_offers, messages, notifications, forum_posts, forum_replies, forum_reports, user_blocks, broker_chats, broker_messages, reviews, subscriptions, audit_log
- [x] RLS op álle tabellen, expliciete policies per rol; admin heeft géén tabeltoegang
- [x] RPC's: redeem_circle_code, claim_task (race-veilig), release_task, complete_task (+logboekje), publish_drafts, respond_invitation, accept/reject_offer, cancel/complete_request, get_request_address, activate_subscription_stub
- [x] Gratis limiet (2 vrijwilligers) server-side via trigger; stub-abonnement ontgrendelt
- [x] Locatievervaging ~1 km via trigger (location_rounded); exact adres alleen via RPC na acceptatie
- [x] ID: alleen `id_verified` boolean + timestamp; privé buckets avatars/id-documents (30-dagen-opruiming volgt in Fase 4 bij de upload-flow)
- [x] Views: v_map_circles, v_map_buddies, v_open_requests (zonder adres), v_buddy_cards, en admin-views (kerncijfers, groei per maand, taken per type, matchtijd) — uitsluitend geaggregeerd
- [x] Realtime aan voor tasks, messages, notifications, spontaneous_requests, request_offers, broker_messages
- [x] Bewijs: `apps/mobile/scripts/rls-smoke.mjs` — 23 checks groen tegen de echte database (niet-lid ziet niets; claim race-veilig; gratis limiet; adres pas na acceptatie; rol niet zelf te wijzigen) + pgTAP-bestand voor CI zodra Docker beschikbaar is

### Fase 4 — Auth en onboarding ✅ (2026-07-28)
- [x] Magic-link login (naam + e-mail, geen wachtwoord) + deep link `tvz://auth/callback` die de sessie zet (implicit én PKCE afgehandeld); redirect-URLs via `supabase config push`
- [x] Schermen: welkom (gradient + stuiterend logo), account, check-mail (met opnieuw versturen), rolkeuze (2 kaarten), koppelcode (hulpvrager → `redeem_circle_code`), ID + profielfoto (2 gestippelde tegels, beide verplicht, upload naar privé buckets, "De app in →")
- [x] Routebepaling `getStartRoute()` (welkom → rolkeuze → id-en-foto → app) als pure, geteste functie
- [x] i18n: `src/i18n/nl.json` + `t()` met variabelen — alle copy uit i18n, geen hardcoded strings
- [x] Tabs-skelet met de zwevende witte pill-tabbalk (5 tabs, actief = navy pill, lucide-iconen lijndikte 2.2)
- [x] Rondleiding: Caveat-wolkjes met pijltje naar de echte tabknoppen, beheerder 4 / vrijwilliger 3 / hulpvrager 2 stappen, navigeert per stap naar de juiste tab, overslaan kan altijd, één keer per gebruiker (AsyncStorage)
- [x] Basis-profielscherm met uitloggen + ouderen-modus-toggle (volledige profielsecties volgen in latere fases)
- [x] Tests: 18 groen (routebepaling, i18n, componenten); lint + typecheck groen
- **Opmerking:** tab-schermen rooster/buurt/kring/steun zijn bewust placeholders tot Fase 5/6/8; ID-opruiming na 30 dagen staat gepland bij de edge functions van Fase 7

### Fase 5 — Kring en rooster ✅ (2026-07-28)
- [x] Kring aanmaken (formulier → koppelcode in gestippelde kaart → kringpagina), gradient-header met subnav Leden/Berichten
- [x] Leden + statuspillen (Actief/Uitgenodigd/ID-check/Kijkt mee), uitnodigen op e-mail/TVZ-ID/profiel-id via `create_invitation`-RPC + "Best matches in de buurt", gratis-limiet-melding (server-side al afgedwongen sinds Fase 3)
- [x] Belastingverdeling "Wie doet wat deze maand?" (staafjes + spreid-advies), kringchat realtime met merkbubbels
- [x] Rooster beheerder: begroeting + datum, taak-van-vandaag-kaart met belknop, inline taakplanner (5 typen incl. "Anders" met vrije invoer, dag, 4 sneltijden + eigen tijd, eenmalig/elke week), weekstrip met stipjes, taaklijst, "Uit de kring"-notities
- [x] Conceptplanner (aparte pagina): periode 1w/2w/1m/2m, weekchips, gestippelde conceptkaarten (verwijderbaar), "Publiceer X taken naar de kring →" + bevestiging + "Al gepubliceerd · week N"
- [x] Rooster vrijwilliger: teller "N mensen geholpen" (gradient), aannemen (race-veilige RPC), "Jij gaat" groen, afronden met logboekje (bottom sheet, met/zonder notitie) én taak teruggeven
- [x] Rooster hulpvrager: grote weergave "X is nu bij je" met pulserende stip en grote belknop (62px), "Straks", herkenningstip
- [x] Persistente taakbanner (navy pill, blijft bij tabwissel, wegdrukbaar, tik → rooster)
- [x] Tests: 22 groen (o.a. weekstrip-stipjes, belastingverdeling, taaklabels); lint + typecheck groen
- **Nog open uit deze fase:** taak intrekken door beheerder ná claim (met nette melding) → gekoppeld aan notificaties in Fase 7; "Buddy-pool"-knop op open taken activeert zodra de buurtkaart (Fase 6) er is; wekelijkse herhaling genereert nu één taak — reeks-generatie komt bij de edge functions van Fase 7

### Fase 6 — Buurtkaart en directe hulp ✅ (2026-07-28)
- [x] Kaart (react-native-maps achter eigen `TvzMap`-wrapper, ADR-0004) met custom markers: hulpkring (witte cirkel + logo-balkjes + pootje), buddy (navy Ø26 met initiaal), directe hulp (navy + groene bliksem + pulsering), eigen locatie (groene stip)
- [x] Zoekveld "Zoek hulpkringen" met live filterende suggesties (filtert ook markers; tik = kaart pant ernaartoe)
- [x] Live teller voor de vrijwilliger ("N kringen · N directe aanvragen in beeld", telt mee bij zoomen/slepen); filterchips Hulpkringen/Buddy's voor de beheerder
- [x] Directe hulp aanvrager: type kiezen + adres → "Zet op de kaart" → aanbod met berichtje → Toestaan/Afwijzen → "X is onderweg" + belknop → afronden; annuleren met bericht (bottom sheet)
- [x] Directe hulp vrijwilliger: aanvraagkaart met afstand ("650 m van jou") → berichtje → "Ik kan helpen" (alleen met ID-check) → wachten op akkoord → adres + belknop → afronden/annuleren
- [x] Fullscreen "hulpvraag ingetrokken"-scherm met geruststellende toon + eventueel bericht van de aanvrager
- [x] Alles realtime (supabase realtime op requests + offers); contact/adres alleen via security-definer-RPC's ná acceptatie; één actieve aanvraag tegelijk (server-side)
- [x] Locatie: expo-location + permissietekst; kaartviews geven lat/lon op wijkniveau
- [x] Tests: 25 groen (haversine, afstandsformat, in-beeld-teller); lint + typecheck groen

### Fase 7 — Meldingen ✅ (2026-07-28)
- [x] Push: device_tokens-tabel (RLS), registratie bij inloggen, opruimen bij uitloggen; Edge Function `send-push` (Expo Push API, ruimt DeviceNotRegistered-tokens op), realtime aangeroepen via pg_net-trigger op elke nieuwe melding
- [x] 10 database-triggers maken meldingen aan: nieuwe taak, taak geclaimd, taak geannuleerd, aanbod, aanbod geaccepteerd/afgewezen, aanvraag ingetrokken, uitnodiging/aanvraag kring, kringbericht, forumantwoord, hulpmakelaar-antwoord — allemaal met Nederlandse teksten en deeplink-payload
- [x] Centrale `notify()`-functie respecteert voorkeuren per categorie én de vakantiemodus (geen taaksuggesties)
- [x] NotificationGateway: tap op push → navigatie naar het deeplink-doel, óók vanuit koude start (getLastNotificationResponseAsync)
- [x] Inbox-scherm op de notifications-tabel (klikbaar, lang indrukken = verwijderen, alles-gelezen) + belletje met groene ongelezen-stip op beide rooster-headers, realtime
- [x] Meldingsinstellingen per categorie (5 categorieën) op het Profiel
- [x] Lokale herinnering 1 uur vóór een aangenomen taak (geannuleerd bij afronden/teruggeven)
- [x] Restpunten Fase 5 opgelost: `cancel_task` (beheerder trekt in, aannemer krijgt melding, ✕ op de taakrij) en wekelijkse reeksen (8 voorkomens per serie + `cancel_task_series`)
- [x] Tests: 29 groen (deeplink-mapping, categorie-dekking van alle trigger-kinds); lint + typecheck groen
- **Let op:** push werkt pas echt in een development build/TestFlight (Expo Go ondersteunt geen remote push); lokale herinneringen en inbox werken overal

### Fase 8 — Steun & advies ✅ (2026-07-28)
- [x] Forum: composer ("Stel een vraag aan de community" → sheet met titel/tekst/tag), filterchips (Alles/Wonen/Werk/Financiën/Dementie), vraagkaarten met voornaam · plaats · tijd · tag · aantal antwoorden
- [x] Thread-detail: vraag + antwoorden; makelaar-antwoorden met groene rand + badge "Hulpmakelaar" (automatisch via trigger); zelf reageren
- [x] Melden + blokkeren (App Store-eis): ⋯-menu op elke post/reactie → melding (naar alle makelaars als notificatie) of gebruiker blokkeren; geblokkeerde auteurs verdwijnen overal (views filteren op user_blocks)
- [x] Hulpmakelaar-chat: overlappende avatars, "x hulpmakelaars online · meestal antwoord binnen 2 minuten" via Supabase Presence (echt geteld), pulserende stip, vertrouwelijkheidsnotitie, startvraag-chips, realtime berichten
- [x] Makelaar-console (route /makelaar, rol-guard): gesprekken beantwoorden + open meldingen afhandelen (inhoud verbergen of alleen afhandelen) — de console zet ook de online-status
- [x] Veilige views (v_forum_posts/replies, v_broker_chat_overview, v_report_overview): voornamen zichtbaar zonder profielen open te zetten
- [x] Tests 29 groen; lint + typecheck groen
- **Open punt:** moderatie-e-mail (besluit #12) loopt nu via pushmeldingen naar makelaars; een e-mailkanaal kan er later bij (Resend) zodra er een moderatie-adres is

### Fase 9 — Abonnement (stub, ADR-0002) ✅ (2026-07-28)
- [x] Abonnementsscherm (screen 12): €4,99-gradient-kaart met de vier voordelen, groene CTA, incasso-tekst, "Later misschien", bevestiging na activeren + pilot-notitie ("eerste maand gratis, er wordt nog niets afgeschreven")
- [x] Stub-activatie via `activate_subscription_stub` (proefmaand); gratis limiet was al server-side afgedwongen; entitlement geldt per account voor alle kringen
- [x] Profiel beheerder: abonnementsregel (Gratis · max 2 vrijwilligers / Proefmaand actief) met Upgraden/Beheren
- [x] Profiel volledig afgemaakt: buddy-pool-toggle (gradient-kaart), "Mijn beschikbaarheid" met dagchips, "Even afwezig" (vakantiemodus, amber melding), agenda-koppeling-toggle, TVZ-ID
- [ ] (Vóór publieke release) RevenueCat + Apple IAP + webhook — zie Open punten

### Fase 10 — Admin-inzichten ✅ (2026-07-28)
- [x] Dashboard op route `/admin` (rol-guard, werkt ook als web-route): vier kerncijfer-tegels, staafgrafiek groei per maand, taken per type met percentages, gemiddelde tijd tot match — uitsluitend uit de geaggregeerde `v_admin_*`-views (admin heeft geen tabeltoegang)
- **Opmerking:** agenda-koppeling slaat nu de voorkeur op; echte EventKit-integratie staat op de Fase 11-lijst

### Fase 11 — Kwaliteit en release 🔶 (grotendeels af, 2026-07-28)
- [x] Accessibility: rollen/labels overal, tikdoelen ≥44 (CTA's 56–62), ouderen-modus 1,3× door alle schermen, contrast volgens brandbook
- [x] Fout- en lege staten in alle flows; melden/blokkeren (fase 8); **account verwijderen** (edge function + bevestiging, App Store 5.1.1(v))
- [x] Screen 16 "Aanvraag beoordelen" toegevoegd (was de laatste ontbrekende); ID-opruiming na 30 dagen via pg_cron
- [x] Seed-script met fictieve demo-data (Anna de Wit, Tim Bakker, mevrouw Jansen, forum + makelaar) — gedraaid op het project
- [x] Concept-privacybeleid + gebruiksvoorwaarden in docs/legal/ (jurist toetst later)
- [x] Self-review BLOK 4 → docs/REVIEW-fase-11.md (RLS nagelopen, alle 25 screens vergeleken, geen any-types/dode code, i18n gecontroleerd)
- [x] README: nieuwe ontwikkelaar draait in <15 min
- [ ] **Samen te doen:** EAS development build → TestFlight-build + submit (vereist `eas login` + Apple team-ID) en de Android interne track; Sentry-DSN aanmaken; App Store-teksten + privacylabels invullen

## Open punten voor ná de pilot-build
- Videokennismaking via Daily.co (API-key nodig) — screen 22
- RevenueCat + Apple IAP (ADR-0002)
- Agenda-koppeling (EventKit), Maestro e2e-flows, typ-indicator makelaar-chat, echte brand-app-iconen

## Voortgangslog
- 2026-07-27: Repo + GitHub opgezet, ANALYSE.md af, vragenronde beantwoord, Supabase-project aangemaakt (`pfvxgzosntzzhydzzkaj`). Fase 1 gestart.

## Open punten / niet vergeten
- Apple team-ID invullen zodra bekend (developer.apple.com → Membership → Team ID).
- Docker installeren voor lokale Supabase-stack (`supabase start`) — tot die tijd migraties via `supabase db push` naar cloud.
- RevenueCat/IAP-implementatie (besluit #5) — vóór publieke release met betaald abonnement.
- Universal links definitief domein (nu vercel-URL).
- Moderatie-e-mailadres bepalen.
