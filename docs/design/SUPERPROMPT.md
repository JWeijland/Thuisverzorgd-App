# SUPERPROMPT — Thuisverzorgd bouwen in Claude Code

> **Hoe te gebruiken**
> 1. Maak een lege map, open die in VS Code, start Claude Code (`claude`).
> 2. Zet deze hele handoff-map erin als `docs/design/` en je oude Swift-app als `docs/legacy-swift/`.
> 3. Plak **BLOK 1** hieronder als eerste bericht. Claude stelt dan vragen — beantwoord ze.
> 4. Plak daarna **BLOK 2** om te laten bouwen. Blok 3 en 4 zijn losse vervolgprompts.
> Gebruik Claude Code met `--permission-mode acceptEdits` of sta edits toe; dit is een lange sessie.

---

## BLOK 1 — Kick-off en vragenronde (eerste bericht)

```
Je bent een senior full-stack engineer en tech lead. Je gaat voor mij een productieklare
mobiele app bouwen: "Thuisverzorgd" — een Nederlandse app die mantelzorgers ontlast door
hulp uit de buurt te organiseren. Ik ben Apple Developer; de app moet met Expo/React Native
naar TestFlight kunnen. De backend draait op Supabase.

Dit is een opdracht die vele uren mag duren. Kwaliteit en structuur gaan boven snelheid.
Werk als een extreem gestructureerde, professionele software engineer: eerst begrijpen,
dan plannen, dan bouwen in kleine, geteste stappen.

## Wat er in deze repo staat
- `docs/design/README.md` — de complete design-handoff: alle schermen, kleuren, typografie,
  radii, copy, flows en state. Dit is de LEIDENDE specificatie voor de nieuwe app.
- `docs/design/TVZ App.dc.html` — het klikbare HTML-prototype van de nieuwe workflow.
  Open dit in een browser om het gedrag te zien. Het is een DESIGN REFERENCE, geen code om
  over te nemen: niets uit dit bestand gaat één-op-één de app in. Neem er alleen de waarden,
  teksten, flows en interacties uit over.
- `docs/design/screens/*.png` — screenshots van elk scherm, genummerd en benoemd.
- `docs/design/reference/Thuisverzorgd-Brand-Guidelines-v3-Getekend.pdf` — het brandbook.
  Leidend voor kleur, typografie, vorm en tone of voice.
- `docs/design/reference/Customer-Journey-TVZ.docx` — de oorspronkelijke customer journey.
- `docs/legacy-swift/` — een OUDE, andere versie van de app in SwiftUI. Die is functioneel
  vrij compleet en dient als inspiratie/checklist: welke schermen, edge cases, statussen en
  rollen zijn daar al bedacht? We bouwen NIET verder op die code (andere taal, andere
  architectuur, andere workflow), maar we willen er geen functionaliteit uit vergeten.

## Wat ik van je wil in DEZE eerste stap (nog niet bouwen!)
1. Lees `docs/design/README.md` volledig. Bekijk daarna alle screenshots in
   `docs/design/screens/`. Lees waar nodig het prototype-bestand om gedrag te begrijpen.
2. Inventariseer `docs/legacy-swift/`: maak een lijst van alle schermen, rollen, statussen
   en features die daarin zitten. Markeer per item: (a) zit al in het nieuwe ontwerp,
   (b) ontbreekt in het nieuwe ontwerp maar is waarschijnlijk nodig, (c) bewust vervallen.
   Let specifiek op: rollen (buddy/elderly/family/admin), koppelcodes, intakes, VOG,
   partnerorganisaties, prijzen, SOS, activiteiten-tijdlijn.
   Let op: VOG-checks en levels/gamification zijn BEWUST geschrapt in het nieuwe ontwerp —
   voeg ze niet terug toe.
3. Schrijf het resultaat naar `docs/ANALYSE.md`: legacy-inventarisatie + gap-analyse +
   jouw voorstel voor de definitieve scope van v1.
4. Stel mij daarna ALLE vragen die je nodig hebt voordat je begint. Ik verwacht minstens
   15 scherpe vragen. Denk in elk geval aan:
   - hosting/omgevingen (dev/staging/prod), bestaand Supabase-project of nieuw?
   - bundle identifier, app-naam, teamsetup Apple Developer, EAS-account
   - betalingen: Apple In-App Purchase (verplicht voor digitale abonnementen) via RevenueCat,
     of iets anders? Prijs €4,99/maand — proefperiode? Wie betaalt bij meerdere kringen?
   - video: Daily.co, LiveKit of Twilio? Budget?
   - kaart: Apple Maps (react-native-maps) of Mapbox? Hoe nauwkeurig mag een locatie zichtbaar
     zijn vóór toestemming (nu: alleen wijkniveau)?
   - moderatie: wie beheert het forum, en hoe regelen we de App Store-eis rond
     user-generated content (melden/blokkeren)?
   - hulpmakelaars: is dat een echt team met een eigen (web)console, of eerst een mailbox?
   - AVG: bewaartermijn ID-checks, verwerkersovereenkomst, DPIA nodig?
   - taal: alleen Nederlands of ook i18n-structuur voorbereiden?
   - offline gebruik, accessibility-eisen (de ouderen-modus), minimale iOS-versie, Android ook?
   - testdata: mag ik seed-data met fictieve namen genereren?
5. Stel geen enkele regel code op papier voordat ik je vragen heb beantwoord.

Begin nu met stap 1 t/m 4.
```

---

## BLOK 2 — De bouwopdracht (na de vragenronde)

```
Dank voor de antwoorden. Ga nu bouwen. Houd je strikt aan onderstaande werkwijze.

# 0. Werkwijze (geldt de hele opdracht)
- Maak eerst `docs/PLAN.md` met een gefaseerd plan, per fase een checklist met vinkjes.
  Werk dat bestand bij na elke voltooide stap; het is onze gedeelde voortgangsstatus.
- Werk in kleine commits met duidelijke Nederlandse of Engelse commit messages (kies één taal
  en houd die aan). Commit na elke afgeronde subtaak.
- Na elke fase: draai lint + typecheck + tests, en vat kort samen wat werkt en wat nog niet.
- Vraag het mij als een keuze het product raakt. Technische keuzes maak je zelf, maar leg ze
  vast in `docs/ADR/` (één kort bestand per beslissing: context, keuze, alternatieven, gevolg).
- Geen TODO's of placeholder-schermen achterlaten zonder ze in PLAN.md te noteren.

# 1. Stack (tenzij we in de vragenronde iets anders hebben afgesproken)
- Expo SDK (laatste stabiele), TypeScript strict, **expo-router** (file-based routing)
- Supabase: Postgres + Auth (magic link) + Realtime + Storage + Edge Functions (Deno)
- State/data: TanStack Query voor server-state, Zustand voor lokale UI-state.
  Geen Redux. Geen globale god-store.
- Formulieren: react-hook-form + zod. Zod-schema's zijn de single source of truth voor
  validatie én types, gedeeld tussen app en Edge Functions.
- Styling: één eigen `theme.ts` met de tokens uit de handoff + eigen primitives.
  (Als je een library wilt gebruiken, motiveer dat in een ADR — maar de huisstijl is leidend,
  niet de library.)
- Animaties: react-native-reanimated. Kaart: react-native-maps. Notificaties:
  expo-notifications. Betalen: RevenueCat. Video: zoals afgesproken.
- Tests: Jest + React Native Testing Library voor logica en componenten, Detox of Maestro
  voor twee e2e-flows (registratie→kring aanmaken→taak plannen, en taak claimen→afronden).

# 2. Projectstructuur (houd je hieraan)
apps/mobile/
  app/                       expo-router routes
    (auth)/                  welkom, e-mail, magic-link-callback, rolkeuze, id-en-foto
    (tabs)/                  rooster, buurt, kring, steun, profiel
    modals/                  taakplanner, weekplanning, videocall, directe-hulp, beoordeling
    _layout.tsx
  src/
    theme/                   theme.ts (tokens), typography.ts, shadows.ts
    ui/                      primitives: Button, Pill, Card, Chip, StatusPill, SectionHeader,
                             Avatar, Toggle, EmptyState, BottomSheet, Coachmark
    features/<domein>/       components, hooks, api, types  (circles, tasks, spontaneous,
                             forum, broker, subscription, notifications, onboarding)
    lib/                     supabase client, queryClient, dates, permissions, analytics
    i18n/                    nl.json (alle copy uit de handoff, geen hardcoded strings)
supabase/
  migrations/                genummerde SQL-migraties
  functions/                 Edge Functions
  seed.sql                   fictieve testdata
docs/                        PLAN.md, ANALYSE.md, ADR/, design/ (bestaand)

# 3. Fasering
**Fase 1 — Fundament**
Repo, Expo-app, TypeScript strict, ESLint+Prettier, absolute imports, EAS-config
(dev/preview/production profiles), `.env` via expo-constants, Supabase-project lokaal
(`supabase init/start`), CI die lint+typecheck+test draait.

**Fase 2 — Designsysteem**
`theme.ts` met exact de tokens uit `docs/design/README.md` (kleuren, radii, schaduwen,
typografie, spacing). Fonts Baloo 2 / Comic Neue / Caveat via @expo-google-fonts.
Bouw alle primitives + een Storybook-achtig `/dev/ui`-scherm waarop ze allemaal staan,
zodat ik ze in één blik kan controleren. Regels uit het brandbook:
vlakken bijna vierkant (radius 8/10/12), alles wat een actie is is een pill (radius 999).

**Fase 3 — Datamodel en RLS**
Schrijf de migraties voor: profiles, circles, circle_members(rol, status), invitations,
tasks(+herhaalregel, claimed_by, status), task_drafts (conceptplanning), task_logs,
spontaneous_requests(+PostGIS locatie), request_offers, messages, notifications,
forum_posts, forum_replies, forum_reports, broker_chats, broker_messages,
subscriptions, audit_log.
Row Level Security op ALLES, met expliciete policies per rol. Harde eisen:
- kringdata alleen zichtbaar voor leden van die kring
- exacte adressen/locaties pas zichtbaar na expliciete toestemming; daarvóór alleen
  wijkniveau (afgeronde coördinaten)
- ID-documenten nooit in de database: alleen een boolean "geverifieerd" + timestamp;
  het bestand gaat naar een private bucket met korte bewaartermijn
- admin ziet uitsluitend geaggregeerde, geanonimiseerde views (maak daar aparte SQL-views
  voor; geen directe tabeltoegang)
Schrijf pgTAP- of SQL-tests die bewijzen dat een niet-lid géén kringdata kan lezen.

**Fase 4 — Auth en onboarding**
Magic-link login (geen wachtwoorden), deep link terug in de app, rolkeuze,
ID + profielfoto (alleen vrijwilliger, alleen bij registratie, beide verplicht),
de in-app rondleiding met coachmarks (Caveat-wolkjes met pijltje naar echte knoppen;
beheerder 4 stappen, vrijwilliger 3, hulpvrager 2, overslaan altijd mogelijk).

**Fase 5 — Kring en rooster (het hart)**
Kring aanmaken, koppelcode voor de hulpvrager, leden, uitnodigingen, gratis limiet van 2
vrijwilligers, belastingverdeling ("wie doet wat deze maand"), kringchat.
Rooster met weekstrip, taakplanner (type incl. "Anders" met vrije invoer, dag, exacte tijd,
herhaling), conceptplanner voor 1 week t/m 2 maanden die pas bij "Publiceren" live gaat,
taken claimen, afronden met logboekje dat als notitie bij de beheerder verschijnt.

**Fase 6 — Buurtkaart en directe hulp**
Kaart met hulpkringen en spontane hulpvragen, live teller van wat er in beeld is,
zoeken met live filtering. Volledige flow: aanvraag plaatsen → aanbod met berichtje →
toestaan/afwijzen → onderweg → afronden; annuleren met bericht aan beide kanten.
Alles realtime via Supabase Realtime.

**Fase 7 — Meldingen (belangrijk, niet als bijzaak behandelen)**
- Push via expo-notifications + Supabase Edge Function met de Expo Push API;
  device-tokens per gebruiker, netjes opruimen bij uitloggen.
- Elke notificatie draagt een `deeplink`-payload (bijv. `tvz://task/<id>`,
  `tvz://request/<id>`, `tvz://circle/<id>/members`). Bij tappen opent expo-router
  exact dat scherm, ook vanuit koude start.
- In-app notificatiecentrum (de Inbox) leest dezelfde `notifications`-tabel; ongelezen
  badge op het belletje; tappen navigeert naar hetzelfde deeplink-doel.
- Lokale notificatie als herinnering vóór een taak; plus de persistente taakbanner bovenin
  die blijft staan bij tabwissel, wegdrukbaar is en terugkomt bij heropenen of als het
  tijdstip nadert.
- Triggers minimaal: nieuwe taak gepubliceerd, taak geclaimd, taak geannuleerd,
  aanbod op directe hulp, aanbod geaccepteerd/afgewezen, uitnodiging, nieuw kringbericht,
  antwoord op je forumvraag, hulpmakelaar antwoordt, herinnering 1 uur vooraf.
- Instellingen per categorie aan/uit, en respecteer de vakantiemodus (geen taaksuggesties).

**Fase 8 — Steun & advies**
Forum met tags, threads, antwoorden, hulpmakelaar-badge, melden/blokkeren (App Store-eis).
Live chat met hulpmakelaars (realtime, met wachtrij en "x online"-status).

**Fase 9 — Abonnement**
€4,99/maand via RevenueCat + Apple IAP, entitlement ontgrendelt onbeperkt vrijwilligers en
de extra functies voor de hele kring. Webhook naar Supabase houdt `subscriptions` bij.

**Fase 10 — Admin-inzichten**
Alleen geaggregeerde cijfers en grafieken uit de anonieme views. Bouw dit als apart,
eenvoudig webdashboard (Next.js of een Expo-web route achter een admin-rol).

**Fase 11 — Kwaliteit en release**
Accessibility (dynamic type, VoiceOver-labels, contrast, tikdoelen ≥44px, ouderen-modus die
alles 1,3× vergroot), foutafhandeling en lege staten overal, Sentry, EAS build + submit naar
TestFlight, App Store-teksten en privacylabels, en een `README.md` waarmee een nieuwe
ontwikkelaar binnen 15 minuten draait.

# 4. Definition of done per scherm
Een scherm is pas af als: het visueel overeenkomt met de screenshot en de tokens uit de
handoff; laad-, lege-, fout- en offline-staat bestaan; alle copy uit `i18n/nl.json` komt;
het toetsenbord de invoervelden niet afdekt; het met VoiceOver bruikbaar is; en er minstens
één test op zit.

Begin met Fase 1 en werk door. Zet PLAN.md meteen klaar en houd hem bij.
```

---

## BLOK 3 — Vervolgprompt per fase (steeds opnieuw bruikbaar)

```
Ga verder met Fase <N> uit docs/PLAN.md.
Vergelijk elk scherm dat je bouwt met de bijbehorende screenshot in docs/design/screens/
en met de betreffende sectie van docs/design/README.md; noem expliciet welke waarden je
hebt overgenomen (kleuren, radii, tekstgroottes) en wijk er niet vanaf.
Als iets in de handoff ontbreekt of tegenstrijdig is: stop en vraag het mij.
Werk PLAN.md bij en commit per subtaak.
```

## BLOK 4 — Reviewprompt (aan het eind van een fase)

```
Doe nu een kritische self-review van wat je in deze fase hebt gebouwd:
1. Loop alle RLS-policies na en probeer met een testgebruiker data te lezen die niet van hem is.
2. Controleer elk scherm tegen docs/design/screens/ en noem elke afwijking.
3. Zoek dode code, ongebruikte dependencies, `any`-types en niet-afgevangen fouten.
4. Controleer of alle copy uit i18n komt en of er geen Engelse UI-teksten zijn blijven staan.
5. Schrijf je bevindingen in docs/REVIEW-fase-<N>.md en los daarna zelf op wat blokkerend is.
```

---

## Extra tips
- **Laat Claude eerst plannen.** De vragenronde in Blok 1 is niet optioneel; die bepaalt of het
  in één keer goed gaat.
- **Bewaak de context.** Werk per fase in een verse sessie en laat `docs/PLAN.md` +
  `docs/ANALYSE.md` het geheugen zijn. Voeg `CLAUDE.md` toe in de repo-root met: de stack,
  de mapstructuur, de codeerregels en "de handoff in docs/design is leidend".
- **Supabase lokaal**: `supabase start` geeft je een lokale stack; migraties in git, nooit
  handmatig in de dashboard-UI klikken.
- **Apple IAP**: begin daar vroeg mee (sandbox-tester aanmaken), het is altijd meer werk dan
  je denkt.
- **Wat bewust NIET in de app zit** (en dus ook niet terug moet komen): VOG-badges, levels en
  gamification, check-in/check-out bij taken, en het woord "mantelzorger" in de UI — daar staat
  "beheerder".
