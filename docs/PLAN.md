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

### Fase 9 — Abonnement (stub, ADR-0002) ✅ (2026-07-28) → **verwijderd 05-08-2026** (handoff voorzieningen, zie hieronder)
- [x] Abonnementsscherm (screen 12): €4,99-gradient-kaart met de vier voordelen, groene CTA, incasso-tekst, "Later misschien", bevestiging na activeren + pilot-notitie ("eerste maand gratis, er wordt nog niets afgeschreven")
- [x] Stub-activatie via `activate_subscription_stub` (proefmaand); gratis limiet was al server-side afgedwongen; entitlement geldt per account voor alle kringen
- [x] Profiel beheerder: abonnementsregel (Gratis · max 2 vrijwilligers / Proefmaand actief) met Upgraden/Beheren
- [x] Profiel volledig afgemaakt: buddy-pool-toggle (gradient-kaart), "Mijn beschikbaarheid" met dagchips, "Even afwezig" (vakantiemodus, amber melding), agenda-koppeling-toggle, TVZ-ID
- ~~(Vóór publieke release) RevenueCat + Apple IAP + webhook~~ — vervallen per 05-08-2026, abonnement bestaat niet meer

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
- Stripe voor boekingen (het abonnement en RevenueCat/IAP zijn per 05-08-2026 vervallen)
- Agenda-koppeling (EventKit), Maestro e2e-flows, typ-indicator makelaar-chat, echte brand-app-iconen

## Feedbackronde 29-07-2026 ✅ (12 punten, live via EAS-update)
- Taakbanner klapt uit naar detailkaart: afronden pas vanaf de afgesproken tijd (server-side afgedwongen in `complete_task`) en terugdraaien via nieuwe RPC `uncomplete_task`
- Ledenlijst zonder "gekoppeld via code"; hulpvrager met blauw randje; profielfoto's overal (ProfileAvatar + signed URLs) en instelbaar op de profielpagina
- Typebalk onderaan forum, forumthread en makelaarchat; keyboard-offset gefixt (`useKeyboardOpen`); hulpmakelaars met echte foto's (`v_makelaars` + storage-policy)
- Kringchat: vaste bubbeltint per afzender (`chatTintFor`)
- Kaart: beschikbaarheidsknop voor spontane hulp (`profiles.spontaneous_available`); teller-pil opent lijst op afstand gesorteerd
- GradientHeader ook op planning- en profielpagina; weekstrip-dagen filteren het rooster; tabbalk met korte namen; rondleiding uitgebreid (5/4/3 stappen)
- Beschikbaarheid: default alle dagen aan, per week instelbaar voor 4 weken (`availability_weeks`; het rooster-voorstel-algoritme leest die kolom nog niet, zie open punten)

## Makelaarsprofielen 29-07-2026 ✅ (live via EAS-update)
- Kaartendeck met makelaarfoto's rechts in de chat; tik = profiel-sheet (gradient-banner, bio, onderwerpen, online-status per makelaar via presence-ids)
- Gesprek gericht aan één makelaar: `broker_chats.broker_id` + `ensure_broker_chat(p_broker)`; chatkop toont met wie je praat; console labelt "Vraag aan {naam}"
- Drie demo-makelaars geseed met bio, onderwerpen en gegenereerde profielfoto's (`scripts/seed-makelaars.mjs`)

## Wegwijzer: kennisbank mantelzorgwetten 31-07-2026 ✅ (migraties gepusht)
Waar de vrijwilliger opleidingen volgt, krijgt de beheerder (en de hulpvrager) de **Wegwijzer**: de wetten en regelingen rond mantelzorg, doorzoekbaar op eigen woorden. Derde pil in de subnav van Steun; welke pil je ziet hangt af van je rol (`subnavVoor()` in `app/(tabs)/steun.tsx`).

- **Inhoud:** 8 thema's, 41 onderwerpen, 166 onderdelen, 36 bronlinks. Thema's: zorgstelsel (Wmo/Wlz/Zvw/Jeugdwet, aanvraagprocedure, cliëntondersteuning, bezwaar), geld (waardering, pgb, eigen bijdrage, belastingaftrek, kostendelersnorm, dubbele kinderbijslag, erfbelasting), wonen (mantelzorgwoning, inwonen, woningaanpassing, urgentie, medehuur), werk (calamiteiten-/kortdurend/langdurend zorgverlof, Wet flexibel werken, zzp), dementie (diagnose, casemanager, gedrag, Wet zorg en dwang, Wlz-indicatie), beslissen voor een ander (wilsbekwaamheid, levenstestament, mentorschap/bewind/curatele, wilsverklaring, dossierinzage), zorg thuis (wijkverpleging, huishoudelijke hulp, dagbesteding, respijtzorg, hulpmiddelen), zorgen voor jezelf (overbelasting, mantelzorgmakelaar, steunpunt, als de zorg stopt).
- **Actualiteit:** bedragen en regels gecontroleerd in juli 2026 en met jaartal in de tekst (Wmo-abonnementstarief € 21,80 in 2026, inkomensafhankelijke bijdrage uitgesteld naar 2027, eigen risico € 385, bijstandsregels per 01-01-2026 waarbij inwonen om te zorgen niet meer kort, drempelbedrag zorgkosten 2026). Elk onderwerp heeft `bijgewerkt_op` en het scherm toont een disclaimer.
- **Zoeken** (`search_wegwijzer`): full-text op titel/synoniemen/samenvatting (gewogen tsvector) + full-text in de onderdeeltekst + "bevat" + trigram-vangnet voor typefouten, met absolute én relatieve drempel. Synoniemenlijst per onderwerp is essentieel: de Nederlandse stemmer knipt samenstellingen niet los, dus "mantelwoning" en "kangoeroewoning" staan expliciet bij de mantelzorgwoning. Getest: mantelwoning → 1 treffer, mantelzorgwoing (typefout) → 1, "kan ik vrij nemen van mijn werk" → zorgverlof, xyzzy → 0. Suggesties tijdens het typen via `wegwijzer_suggesties`.
- **Doorstroom naar een mens:** onderaan elk scherm en elk onderwerp een kaart naar de hulpmakelaar; die opent Steun op de makelaar-tab met de vraag al in het tekstvak (`?tab=makelaar&vraag=...`).
- **Extra:** bewaren en "verder lezen" per gebruiker; zoekopdrachten worden anoniem geteld in `guide_searches` (géén profile_id) zodat zichtbaar wordt waar mensen niets op vinden.
- **Gevonden en gefixt onderweg:** gegenereerde tsvector-kolommen vereisen `'dutch'::regconfig` (anders alleen STABLE) en `array_to_string` is STABLE, vandaar het eigen `tekst_uit_lijst()`. `revoke execute ... from anon` is niet genoeg op functies: PUBLIC houdt de grant, dus expliciet intrekken en aan `authenticated` geven (migratie `..._wegwijzer_rechten.sql`). RLS-rooktest: anon komt nergens bij, ingelogd leest alles, niemand kan inhoud schrijven.

## Feedbackronde 31-07-2026 ✅ (live via EAS-update)
- **Vrijwilligersmeldingen bij de verkeerde rol.** `change_role` en `redeem_circle_code` wijzigden alleen `profiles.role`; `circle_members.member_role` en aangenomen taken bleven staan. Wie van vrijwilliger naar hulpvrager ging, bleef "vrijwilliger" in de kring: hij kreeg "Nieuwe taak in je kring" en de banner "... jij gaat" van zijn oude taken. Gevonden in de database: 3 taken op naam van een hulpvrager, 2 onterechte meldingen. Nu: `sync_member_roles()` bij elke rolwissel (taken terug naar open, lidmaatschap elders wordt "kijkt mee", in je eigen kring blijf je beheerder), de meldingstrigger toetst óók de profielrol, `claim_task` weigert een hulpvrager, en de banner verschijnt niet bij een hulpvrager. Bestaande scheefstand opgeruimd.
- **Hulpstraal** (`profiles.help_radius_m`, standaard **300 m**, keuzes 300 m tot 25 km in het profiel). Bepaalt welke spontane hulpvragen en kringen een vrijwilliger ziet (`v_open_requests`, `v_map_circles`) en voor welke kringen hij als buddy in beeld komt (`buddys_voor_kring()` vervangt de ongefilterde `v_buddy_cards`-query). Rekent server-side met `location_rounded`; omdat die ~1 km vervaagd is telt een marge van 1200 m mee (`hulpstraal_marge_m()`, gespiegeld in `straal.ts`), anders mis je bij 300 m je buurvrouw door de afronding. Eigen aanvraag en eigen kringen blijven altijd zichtbaar. **Let op:** met 300 m ziet een vrijwilliger in de testdata 0 van de 3 open hulpvragen, met 25 km alle 3. Dat is de bedoeling, maar het betekent wel dat nieuwe vrijwilligers hun straal actief moeten verruimen.

## Voorzieningen & mascotte Bo 05-08-2026 ✅ (migraties gepusht, alles lokaal groen)
Bron: `handoff-voorzieningen/CONCEPT.md` + de Bo-SVG's. Afgesproken met Jelle: Steun, Rooster en Wegwijzer blijven zoals ze waren; Voorzieningen komt er als extra tab bij; het abonnement gaat er wél uit; betalen is nog zonder echte afschrijving (Stripe volgt).

- **Abonnement volledig verwijderd**: scherm, Upgraden-kaart in Profiel, gratis-limiet-melding, `useSubscription`. Database (migratie `20260805100000`): trigger `circle_members_free_limit`, `enforce_free_limit`, `has_active_subscription`, `activate_subscription_stub`, tabel `subscriptions` en het enum weg; `handle_new_user` opnieuw zonder subscriptions-insert. Uitnodigen is onbeperkt. Verdienmodel wordt transactiefee op boekingen.
- **Voorzien-tab** (marktplaats, alleen zorg-rollen): beheerder `rooster · voorzien · buurt · steun · profiel`, hulpvrager `rooster · voorzien · kring`; vrijwilliger ongewijzigd. Grid met uitgelichte gratis Buddy-gradient-tegel + 9 betaalde diensten uit de database, zoekbalk filtert live.
- **Datamodel** (migratie `20260805100100`): `providers` (voornaam, bedrijf, Caveat-notitie, demoafstand), `services` (prijs in centen, eenheid bezoek/uur, rating), `bookings` (prijs vastgelegd op boekmoment, `payment_status` 'na_bezoek' = capture-later). RLS: catalogus alleen ingelogd, boekingen alleen je eigen; schrijven uitsluitend via RPC's `create_booking` (maakt ook een 'boeking'-melding via `notify()`) en `cancel_booking` (weigert binnen 24 u, `annuleren_te_laat`). Grants expliciet ingetrokken van PUBLIC/anon (les uit de Wegwijzer).
- **Dienst-detail** volgens het redesign: lichtblauw hero-vlak (`colors.heroBlue`, onderhoeken 28), grote avatar met witte rand, "met Samira · 1,2 km", sterren + beoordelingen, handgeschreven notitie (Caveat), "Wat kun je verwachten", tijdsloten als radio-lijst met hairlines (eerste = "snelst", géén chips), zwevende prijskaart met "Boek di 10:00" (label volgt het gekozen slot).
- **Boeken**: afrekenen (overzicht, Apple Pay/iDEAL als keuze-UI, "bedrag pas afgeschreven ná bezoek") → `create_booking` → bevestiging met Bo + groen vinkje. Er wordt bewust nog níéts afgeschreven; echte Stripe-koppeling (iDEAL + Apple Pay, capture-later) staat bij de open punten.
- **Rooster-koppeling**: `GeboekteDiensten` toont komende boekingen naast de kringtaken (beheerder + hulpvrager) met annuleren via bottom sheet; binnen 24 u legt de app netjes uit dat het niet meer kan.
- **Buddy-flow**: uitlegpagina met Bo-hero → "Vraag via je hulpkring" (beheerder → planning-tab, hulpvrager → kring-tab) of "Zet een oproep op de buurtkaart" (→ kaart).
- **Mascotte Bo** (`src/ui/Bo.tsx`, uit de SVG's van de handoff): welkomstscherm (deinend), peek over de headerrand van Steun én Voorzien (`GradientHeader bo`-prop, vóór de golf getekend zodat hij er echt achter zit), boekingsbevestiging met vinkje-badge, lege staten (kring + "nog geen kring" op het rooster, `EmptyState bo`-prop). Regels: max één Bo per scherm, nooit op betaal-/juridische schermen, nooit uitrekken.
- **Meldingen**: nieuwe kind 'boeking' onder de categorie Taken.
- **Bewijs**: rls-smoke uitgebreid (28 checks groen tegen de echte database: geen limiet meer, anon ziet de catalogus niet, boekingen privé, prijs vastgelegd, annuleren werkt); 61 Jest-tests groen (nieuw: tijdsloten, "snelst", euro-notatie); lint + typecheck groen.
- **Nog te doen bij deze feature**: echte Stripe-betalingen; aanbieder-portretfoto's (nu initiaal-avatar); prototype `TVZ App v2.dc.html` naast de build leggen zodra Jelle het aanlevert; eventueel een rondleiding-stap voor de nieuwe tab.

## Feedbackronde 05-08-2026 ✅ (acht punten, migratie gepusht)
- **Uitloggen betrouwbaar**: nieuwe helper `logUit()` (onboarding/uitloggen.ts) voor alle rollen: pushtoken opruimen is best effort met 2,5 s-limiet, en als de server-signOut faalt (geen bereik, verlopen sessie) volgt lokaal uitloggen als vangnet — je blijft nooit meer hangen. Gebruikt door UitlogKnop, Profiel en account verwijderen.
- **Kaartmarkers beter aantikbaar**: druppels van 34×43 naar 40×50 met een onzichtbare tikrand van 12 pt eromheen (`HIT_PAD` in TvzMap; het tikbare vlak van een custom marker is precies de view). Buddy-cirkel 34→42 met grotere foto.
- **Kaart van de hulpvrager toont alléén buddy's** (met profielfoto, die stonden er al via signed URLs): geen kringen, geen aanvragen van anderen, geen zoekbalk of filterchips. Directe hulp aanvragen kan gewoon. Bij een aangetikte buddy: "Vraag de beheerder van je kring om deze buddy uit te nodigen."
- **Kaart-tab voor de hulpvrager**: tabbalk is nu rooster · voorzien · buurt · kring; eerder kwam ze alleen via de Buddy-flow op de kaart terecht zonder te weten waar ze was.
- **Steun-subnav gelijkgetrokken**: beheerder én vrijwilliger zien alle vier de pillen (Forum · Makelaar · Wegwijzer · Opleidingen); alleen de hulpvrager blijft compacter (zonder opleidingen). Subnav wrapt en laat rechts ruimte voor Bo.
- **Adres directe hulp**: eenmalig invullen — bewaard in `profiles.street_address` (migratie `20260805150000`), vooringevuld bij de volgende oproep. En de oproep staat nu op het ingevulde adres op de kaart (geocoding via `Location.geocodeAsync`), niet meer op de huidige GPS-locatie; eigen locatie is alleen nog het vangnet.
- **Rondleiding gerepareerd**: de beheerder-stap over de kring wees naar een kring-tab die hij niet heeft (pijl viel terug op tab 1 en de route opende het verkeerde scherm) — hoort nu bij het rooster. Nieuwe stappen: Voorzien (beheerder + hulpvrager) en Kaart (hulpvrager); beheerder 6, vrijwilliger 4, hulpvrager 4 stappen. Abonnement-zin uit de profielstap.
- **Bo overal even zichtbaar**: Bo zit nu bovenop elk rondleiding-wolkje (Coachmark `bo`-prop, handoff) en op de lege roosterstaten van vrijwilliger én hulpvrager; samen met welkom, headers en bevestiging ziet elke rol Bo nu op meerdere plekken.

## Actuele stand (overdracht, 28-07-2026 einde dag)
- App staat op TestFlight en werkt op het toestel van de opdrachtgever; login via 6-cijferige code uit de mail (magic link werkt ook). JS-fixes gaan via `eas update --channel production --environment production --platform ios`; native wijzigingen vergen een nieuwe build.
- Productie-crashes opgelost: env vars in EAS (build + update-environments), robuuste magic-link callback, React Compiler UIT (evalueerde `x!.id` in handlers tijdens render), realtime-kanalen uniek per component, presence als singleton, storage-policies voor ID-upsert.
- Reproduceren/testen kan lokaal: `npx expo start --ios --go` + dev-autologin via `EXPO_PUBLIC_DEV_ACCESS_TOKEN`/`REFRESH` in `.env` (zie useAuth.tsx, alleen __DEV__). Lokale `expo run:ios` faalt op spaties in het pad — Expo Go gebruiken.
- **Direct te doen:** gebruiker test de realtime-fix; daarna verse iOS-build + submit (echte app-icoon + NL-camerateksten zitten dan ingebakken), daarna Android-build, Sentry, App Store-teksten.

## Voortgangslog
- 2026-08-17 (2): **Hulp-pagina als startpunt, info achter het vergrootglas, makelaar bij de voorzieningen** (wens Jelle 17-08). Beheerder en hulpvrager landen nu standaard op `/regelen/voorzieningen`; het keuzescherm blijft bereikbaar via de Bo-knop.
  - **Vergrootglas rechtsboven** in de hulp-header opent de zoek-popup `/regelen/zoek` (modale route, geen RN-Modal, zodat artikelen er gewoon bovenop openen): korte uitleg ("zoekfunctie op basis van officiële documenten, met verwijzingen"), de bestaande AI-zoekfunctie (`WegwijzerLijst`: vraag → Claude-antwoord uitsluitend uit de eigen kennisbank, bronnen + doorlezen in relevante onderwerpen, thema's om te bladeren) en een "Liever een mens?"-kaart naar de makelaar.
  - **De mantelzorgmakelaar is een voorziening**: nieuwe tegel op de marktplaats (gezichten van de makelaars, wie online is eerst, gratis-pil) → `/regelen/makelaar` met de bestaande BrokerChat (meerdere makelaars, profielen, onderwerpen, chat + videobel-vraag). Alle makelaar-links (wegwijzer-hero, MakelaarKaart, push-deeplink `hulpmakelaar`) wijzen nu daarheen; het schuifje Zorgmakelaars is uit het weet-pad (route blijft bestaan voor oude links).
  - **Bewijs**: lint, typecheck en 89 tests groen (startRoute-test aangepast). Geen databasewijzigingen. Nog te doen: EAS-update publiceren (geldt ook nog voor de aanbieder-agenda van vandaag).
- 2026-08-17: **Aanbieder-agenda: echte beschikbaarheid en geen dubbelboekingen** (wens Jelle 17-08). Aanbieders (kapper, tuinman, ...) hebben nu een eigen rol `aanbieder` met een eigen ingang: geen knop in de app — Thuisverzorgd maakt het account (gebruikersnaam + wachtwoord, zelfde `@tvz.invalid`-constructie als gewone gebruikersnaam-accounts) aan op het admin-scherm (sectie Aanbieders → edge function `aanbieder-account`, alleen admin/platform_admin) en geeft de gegevens door; wie ermee inlogt landt direct in **Mijn agenda** (amber `PadHeader`, schuifjes Beschikbaarheid · Mijn afspraken, geen keuzescherm).
  - **Beschikbaarheid** (`/aanbieder/beschikbaarheid`): werkritme per weekdag (toggle open/dicht, tijden via de rollende TijdPicker, één blok per dag in `provider_hours`) en "Ik ben er even niet"-periodes (`provider_absences`, datumstepper van/tot). RLS: alleen de aanbieder zelf.
  - **Mijn afspraken** (`/aanbieder/afspraken`): komende boekingen per dag via RPC `aanbieder_afspraken()` — tijd t/m eindtijd (duur van de dienst), dienst, klantnaam en adres (adres alleen hier: een boeking is de toestemming om langs te komen). Nieuwe boeking en annulering sturen de aanbieder een melding (kind `boeking_aanbieder`).
  - **Slots zijn echt** (migratie `20260817090000_aanbieder_agenda`): `maakSlots` (vier nepmomenten) is weg; de dienstpagina toont dagschuifjes + tijden uit RPC `beschikbare_slots` = werkritme − afwezigheid − (boekingen van die aanbieder over ál zijn diensten + reistijdbuffer `providers.buffer_min`), raster 30 min, horizon 14 dagen, minimaal 2 uur vooruit, Europe/Amsterdam. `create_booking` valideert het gekozen moment tegen dezelfde berekening onder een advisory lock per aanbieder → tegelijk boeken kan niet meer (fout `moment_niet_beschikbaar`, nette melding + slots verversen in afrekenen). Demo-aanbieders gezaaid met ma-vr 09:00-17:00.
  - **Bewijs**: lint, typecheck en 89 Jest-tests groen (nieuw: `agenda.test.ts`, herschreven `slots.test.ts`); live tegen de cloud-DB geverifieerd in een teruggedraaide transactie (12 checks): slots volgen het ritme, boeken blokkeert het slot én het overlappende halfuur, dubbelboeken en buiten-ritme-boeken geweigerd, afwezigheid haalt de dag weg, agenda-RPC toont de afspraak, RLS houdt klanten uit het werkritme. Migratie gepusht, edge function gedeployed.
  - **Nog te doen**: EAS-update publiceren; wachtwoordherstel voor aanbieders loopt via de admin (geen mailbox op `@tvz.invalid`).
- 2026-08-11: **Herstructurering: tabbalk eruit, twee paden erin** (nieuwe handoff `handoff-voorzieningen/HERSTRUCTURERING.md` + CONCEPT.md, screenshots 01 t/m 09). Vervangt de tabstructuur van Ontwerp 4.0; afgestemd met Jelle: volledig ombouwen, hulp-pad in hulpgroen (zoals de screenshots, niet het koraalrood uit CONCEPT.md), hulpvrager een eigen vereenvoudigde versie mét toegang tot betaalde diensten, opleidingen/Leren en directe hulp op de kaart blijven, de weekstrip-rode draad en /vul-de-week vervallen.
  - **Navigatie**: geen bottom tabs meer. `/pad` is het keuzescherm (twee gekleurde kaarten + Bo + "Mijn gegevens en instellingen"). Routes verhuisd naar `/weten/*` (wegwijzer · forum · zorgmakelaars), `/regelen/*` (voorzieningen · planning · kring) en `/vrijwilliger/*` (buurt · taken · steun). `PadHeader` is de vaste kop: terugpijl, Bo-knop terug naar de keuze, titel, avatar, kruimelspoor met bolletjes en de schuifjes. `paden.ts` houdt de definitie (kleuren, schuifjes, rolvarianten).
  - **Vrijwilliger** landt direct op de kaart: geen gekleurde balk en geen zoekbalk, alleen drie zwevende witte pillen, en zijn kringen als ronde knoppen rechtsonder (`KringRondjes`).
  - **Wegwijzer** is de startpagina van het weet-pad: vandaag-strip, hulpmakelaar-blok (Chat nu / Videobel) en daaronder de kennisbank. Zodra je zoekt verdwijnt die kop.
  - **Kringpagina** op scherm 07: kringkop met Leden/Berichten als tabjes (Berichten is geen eigen schuifje meer) en het kleine knopje "Laat Bo een buddy in de buurt zoeken" — sinds nu de enige weg naar de volledige kaart voor een beheerder.
  - **Buddy-flow**: de tegel vraagt niet meer "kring of kaart" maar "elke week of eenmalig"; daarna de buurt-scan (`useBuurtScan`) die buddy's en kringen binnen 5 km telt en dat met een korte laadstap laat voelen.
  - **Kring opbouwen** in zes stappen met Bo, concept in `circle_drafts` zodat je kunt stoppen en later verder kunt. Stap 6 is de proefweek: `voorstelRooster()` zet een week klaar, "Start de proefweek" maakt de taken en zet `circles.trial_started_at`; na zeven dagen vraagt `ProefweekTerugblik` of het werkte (RPC `bevestig_proefweek`).
  - **Taak inplannen** is één doorlopende pagina (scherm 06): raster van zes taaksoorten, dagbalk met weekpijltjes, rollende tijdpicker met snelkeuzes, herhaling eenmalig/wekelijks/tweewekelijks, "Wie" (open voor de kring of een vast kringlid) en een vaste samenvattingsbalk. Na opslaan springt de planning naar die dag met een groene bevestiging.
  - **Rondleiding** wijst nu omhoog naar de schuifjes; de header meet zelf op waar ze staan, dus het pijltje klopt ook bij langere labels. Rondleiding en taakbanner hangen nu in de root-layout (die zaten in de tabbalk-layout).
  - **Migraties** (gepusht en live geverifieerd): `20260811095000_taaksoort_koken`, `20260811100000_kringopbouw_en_proefweek` (circle_drafts met RLS, trial-kolommen, `bevestig_proefweek`), `20260811110000_herhaling_tweewekelijks`, `20260811110100_reeks_tweewekelijks`.
  - **Bewijs**: lint, typecheck en 72 Jest-tests groen (nieuw: `voorstelRooster`, aangepaste deeplink- en startroute-tests). Oude push-deeplinks (`tvz://rooster` en zo) blijven werken via een vertaaltabel in `push.ts`.
  - **Nog te doen**: EAS-update publiceren zodat het op de telefoon komt; echte videobelfunctie (de Videobel-knop zet nu de vraag in de makelaar-chat); zoekbalk op Voorzieningen is vervallen omdat scherm 03 er geen toont.
- 2026-08-07 (3): **Eigen minimalistische kaart** (wens Jelle, MyWheels-stijl). Eerst snelle opknapper: Apple Maps gedempt (mutedStandard, geen gebouwen/3D) via EAS-update. Daarna volledige overstap: react-native-maps eruit, MapLibre (`@maplibre/maplibre-react-native` 11.3.6) + OpenFreeMap erin — gratis, geen account/creditcard (Mapbox afgewezen: kaart verplicht, geen bestedingslimiet of waarschuwingen mogelijk). Merkstijl `src/features/map/tvz-stijl.json` (OpenFreeMap Positron omgekleurd: bg #F5F8FC, parken groentint, water zacht kringblauw, navy labels). TvzMap-wrapper houdt de oude buitenkant (Region, animateToRegion, Marker met coordinate/vrij anker via center+offset-vertaling), dus buurt.tsx bleef vrijwel ongemoeid. Versie 0.2.0 (runtime-bump: native wijziging, policy appVersion). iOS-build 6 met auto-submit naar TestFlight gestart.
- 2026-08-07 (2): **Profielfoto's op de kaart gerepareerd** (migratie `20260807120000_avatar_zichtbaarheid`): de storage-policies voor pool-buddy's, makelaars en forumdeelnemers subquery'den op `profiles`, maar die tabel heeft zelf RLS (jezelf + kringgenoten) — buiten de eigen kring matchte de policy nooit en toonde de kaart alleen initiaal-cirkels. Nu bepaalt één security definer-helper (`avatar_publiek_zichtbaar`) zonder RLS of een foto zichtbaar hoort te zijn. Live geverifieerd (5 kaart-buddy's + 3 makelaars → 200), rls-smoke en workflow-smoke groen. Serverside fix, geen EAS-update nodig.
- 2026-08-07: **Workflow-test met nepaccounts + trilschema + marktplaatsfoto's.** Nieuw script `scripts/workflow-smoke.mjs`: zes nepaccounts (beheerder, 3 buddy's, hulpvrager, makelaar) doorlopen alle rolcommunicatie live tegen Supabase — uitnodigen/aanvragen, taken (publiceren/claimen/annuleren/weekreeks), kringchat, directe hulp (aanbod/accepteren/afwijzen/intrekken), forum, makelaar-chat, meldingsvoorkeuren/vakantiemodus en de pushpijplijn incl. tokenopruiming; 44 checks groen. Gevonden gat gerepareerd (migratie `20260807090000_uitnodiging_antwoord`): wie een uitnodiging of aanvraag beantwoordt stuurt nu een melding terug (nieuw kind `uitnodiging_antwoord`) mét optioneel persoonlijk berichtje; het beoordeel-scherm kreeg daarvoor een tekstveld. Verder: app-breed trilschema via `src/lib/haptics.ts` (tik/selectie/stevig/succes/voltooid/waarschuwing/fout) — elke Button trilt passend bij zijn variant, chips/toggles/tabs geven een selectieklikje, en de lange "voltooid"-tril zit op boeking betalen, taak claimen/afronden, aanbod accepteren en lid worden van een kring. Marktplaats (Voorzien): warme Pexels-foto's op alle negen diensttegels (assets/images/diensten, bronnen in BRONNEN.md; AI-generatie kon niet: Higgsfield-credits op). Lint, typecheck en 66 tests groen. Nog te doen: EAS-update publiceren.
- 2026-08-06 (2): **Fase 12 · Ontwerp 4.0** gebouwd, zie `docs/ONTWERP4-PLAN.md` en het klikbare prototype (artifact). Drie lagen als vaste volgorde (1 Steun · 2 Kring en Buurt · 3 Voorzien), rolkleuren uit het logo (navy beheerder, groen buddy, kringblauw hulpvrager; Bo kleurt mee), de week als rode draad (één WeekStrip met vaste stipkleuren bij alle rollen, geboekte diensten als blauwe stipjes) en één functie per pagina. Tabbalk per rol met eigen labels en startschermen (beheerder start op Steun). Nieuwe pagina's: /verhaal, /kringuitleg, /wegwijzer-lijst, /hulpmakelaar, /forum, /taak-plannen, /vul-de-week, /diensten, /buddy-vragen. Nieuwe migratie `vraag_buddy` (hulpvrager zet zelf een open taak in de kring) gepusht en live geverifieerd. Lint, typecheck en 66 tests groen. Nog open: stappenplannen als aparte inhoudslaag (content), profiel-kringlink, buurt/directe-hulp als losse pagina (bewust gelaten: de flow op de kaart is al één functie).
- 2026-08-06: Wegwijzer volledig nagelopen en uitgebreid. Alle 33 links gecontroleerd (4 kapotte vervangen: DementieLijn i.p.v. Alzheimer Telefoon, rechtspraak.nl, SVB, rijksoverheid-pgb), feiten geverifieerd tegen officiële bronnen (eigen risico €385 in 2026 bevestigd; bijstandsregels 1-1-2026 bevestigd; SVB-kwartaalbedrag verwijderd omdat het niet meer op svb.nl staat). 13 nieuwe onderwerpen (o.a. palliatieve zorg, ziekenhuisontslag, medicijnen, GGZ-naasten, 18 worden, toeslagen, rijbewijs en dementie, financieel misbruik, jonge mantelzorgers): nu 54 onderwerpen, 206 secties, 175 bronlinks incl. wetteksten op wetten.overheid.nl. Nieuw: vragen typen in de zoekbalk geeft een direct antwoord uit de kennisbank met bronnen erbij (`wegwijzer_antwoord` RPC, extractief met vangnet; AntwoordKaart in de app). Migraties 160000 t/m 190000 gepusht en live getest. Nog te doen: EAS-update publiceren zodat de nieuwe UI op telefoons komt.
- 2026-07-27: Repo + GitHub opgezet, ANALYSE.md af, vragenronde beantwoord, Supabase-project aangemaakt (`pfvxgzosntzzhydzzkaj`). Fase 1 gestart.

## Open punten / niet vergeten
- Apple team-ID: 5QFB2FHYYQ (Individual) — staat in eas.json.
- Docker installeren voor lokale Supabase-stack (`supabase start`) — tot die tijd migraties via `supabase db push` naar cloud.
- Stripe-koppeling voor boekingen (iDEAL + Apple Pay, capture-later) — het abonnement en daarmee RevenueCat/IAP zijn per 05-08-2026 vervallen.
- Universal links definitief domein (nu vercel-URL).
- Moderatie-e-mailadres bepalen.
- `availability_weeks` meenemen in taakvoorstellen/notificaties (nu alleen UI + opslag).
