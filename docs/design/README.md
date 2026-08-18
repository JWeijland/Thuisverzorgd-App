# Handoff: Thuisverzorgd — hulpkringen-app (pilot)

> **Let op (18-08-2026):** de kleuren in deze handoff en screenshots zijn huisstijl **v3 (navy)** en daarmee verouderd. Sinds huisstijl **v4** is Thuisrood `#E55A40` de merkkleur; zie `apps/mobile/src/theme/HUISSTIJL.md` en het Brand Guidelines v4-pdf. Flows, copy en lay-out hieronder blijven gelden.

## Overview
Thuisverzorgd is een Nederlandse app die mantelzorgers ontlast door hulp uit de buurt te organiseren.
Vier gebruikersrollen:

| Rol | In de app | Kern |
|---|---|---|
| **Beheerder** (voorheen "mantelzorger" — dat woord wordt bewust vermeden) | volledig | maakt een **hulpkring** rond een naaste, plant taken, nodigt vrijwilligers uit, betaalt het abonnement |
| **Vrijwilliger / buddy** | volledig | neemt taken aan uit het rooster, reageert op spontane hulpvragen, kan ook los bijspringen bij andere kringen |
| **Hulpvrager** | eenvoudig scherm | ziet wie er komt en wanneer, met grote letters en belknoppen |
| **Admin** | los dashboard | uitsluitend geaggregeerde, geanonimiseerde inzichten — géén beheer van gebruikers |

Drie manieren waarop hulp ontstaat:
1. **Rooster** — geplande taken binnen de eigen hulpkring (kern van de app)
2. **Directe hulp** — spontane hulpvraag op de buurtkaart, opgepakt door buddy's in de buurt
3. **Steun & advies** — forum tussen mantelzorgers onderling + live chat met hulpmakelaars

## About the Design Files
De bestanden in deze bundel zijn **design references, gemaakt in HTML** — een klikbaar prototype dat laat zien hoe de app eruitziet en zich gedraagt. Het is **geen productiecode om over te nemen**.

De opdracht is om deze schermen **opnieuw te bouwen in Expo / React Native**, met de patronen en libraries van die omgeving. Neem de HTML/CSS niet letterlijk over; neem de *waarden* over (kleuren, maten, teksten, flows) zoals hieronder gedocumenteerd.

`TVZ App.dc.html` opent gewoon in een browser. Links staat een navigatiepaneel waarmee je direct naar elk scherm springt; rechts de telefoon. Alles is klikbaar.

## Fidelity
**High-fidelity.** Kleuren, typografie, spacing, radii, copy en interacties zijn definitief en volgen het brandbook (v3.0 "Getekend", meegeleverd in `reference/`). Bouw de UI pixel-precies na. Alleen de kaart-tiles (OpenStreetMap) en placeholder-avatars (gekleurde cirkels met initiaal) zijn nog te vervangen door echte assets.

---

## Design Tokens

### Kleuren
| Token | Hex | Gebruik |
|---|---|---|
| `primaryDark` | `#112F50` | donkerste navy: gradients, videocall, directe-hulp-marker |
| `primary` | `#1A4878` | primaire knoppen, actieve tabs, koppen |
| `primaryMid` | `#2A6CB0` | accent-navy, avatars, links, gradient-eind |
| `accent` (Hulpgroen) | `#8DC93F` | primaire CTA, actief/positief, pulserende status |
| `accentDark` | `#73B02B` | hover/donkere variant hulpgroen |
| `accentHover` | `#9AD44E` | hover op groene knoppen |
| `successBg` / `successText` | `#F1F8E4` / `#4C7A16` | geslaagd-pillen en -balken |
| `warnBg` / `warnText` | `#FBF3E0` / `#9A6E0B` | "nog open", "uitgenodigd", vakantiemodus |
| `errorBg` / `error` | `#FDEDEC` / `#D9413A` | afwijzen, uitloggen, ophangen |
| `ink` | `#112640` | bodytekst |
| `inkSoft` | `#5A687A` | secundaire tekst |
| `inkFaint` | `#8F9AAA` | tertiaire tekst, placeholders |
| `line` | `#E3E8F1` | randen |
| `surfaceAlt` | `#EEF2F8` | lichte vlakken, iconentegels |
| `tintBlue` | `#EAF1F9` | blauwe pill-achtergrond |
| `bg` | `#F5F8FC` | app-achtergrond |
| `white` | `#FFFFFF` | kaarten |
| Chatbubbels | `#DEE8F4` (eigen) / `#EAF5D8` (ander) | |

Standaard-gradient (headers, welkom, videocall):
`linear-gradient(115deg, #112F50, #2A6CB0)` → in RN: `expo-linear-gradient`, `start={{x:0,y:0}} end={{x:1,y:1}}`.

### Typografie
- **Koppen, knoppen, labels, pillen:** Baloo 2 (600 / 700 / 800)
- **Bodytekst:** Comic Neue (400 / 700, italic voor citaten)
- **Handgeschreven accent:** Caveat (500 / 600) — alleen voor de rondleiding-wolkjes en losse notities

Beide zijn Google Fonts; laad ze met `expo-font` / `@expo-google-fonts/baloo-2`, `.../comic-neue`, `.../caveat`.

Schaal (px): scherm-titel 25–29 · sectiekop 16–19 · kaarttitel 16–18 · body 14.5–17 · secundair 13–14 · pill/meta 11.5–13. Regelhoogte body 1.5–1.6. Minimale tikdoelen 44px; hulpvrager-scherm gebruikt 17–29px tekst en 62px knoppen.

### Vorm & schaduw (brandbook v3 "Getekend")
- **Vlakken zijn bijna vierkant:** kaarten `radius 12`, kleine rijen `10`, invoervelden `8`, iconentegels `15–17`.
- **Alles wat een actie is, is een pill:** knoppen, chips, tabs, statuspillen → `radius 999`.
- Chatbubbels: `18 18 6 18` (eigen) / `18 18 18 6` (ander).
- Schaduwen: kaart `0 6–8px 18–24px rgba(17,47,80,.06–.08)`, zwevend element `0 12–16px 32–40px rgba(17,47,80,.18–.22)`, groene CTA `0 8px 20px rgba(115,176,43,.3)`.
- Gestippelde rand `1.5–2px dashed #2A6CB0` = concept / nog te doen (koppelcode, conceptplanning, foto-upload).

### Spacing
Schermpadding 20–24. Verticale gap tussen kaarten 10. Kaartpadding 16–22. Chip-gap 8. Sectiekop-marge 20–26 boven, 10–12 onder. Onderste tabbalk: 5 tabs × 64px + 6px padding, `bottom: 16`, `radius 999`, wit, schaduw `0 12px 32px rgba(17,47,80,.18)`.

### Animaties
| Naam | Effect | Waar |
|---|---|---|
| `tvzBounce` | 2.6s, translateY 0 → −7 → 0 | de twee logo-balkjes, typ-indicator |
| `tvzIn` | 0.25–0.3s, opacity 0→1 + translateY 14→0 | kaarten die verschijnen |
| `tvzPulse` | 1.8s, groeiende groene box-shadow ring | live status: directe hulp, "is nu bij je", makelaars online |

In RN: `react-native-reanimated` (`withRepeat` + `withTiming`).

---

## Schermen

### Onboarding
1. **Welkom** — navy gradient, logo (twee liggende balkjes + staande balk), tagline "Hulp dichtbij, geregeld door de buurt", groene knop "Account aanmaken" + outline "Inloggen".
2. **Account** — naam + e-mail, **geen wachtwoord**. Knop "Stuur mij een inloglink".
3. **Kijk in je mail** — magic-link bevestiging.
4. **Rolkeuze** — twee grote kaarten: "Ik regel hulp voor iemand" (navy balkje) / "Ik wil helpen in de buurt" (groen balkje).
5. **ID + profielfoto** (alleen vrijwilliger, **alleen hier, één keer**) — twee gestippelde tegels naast elkaar: ID-foto en profielfoto. Beide vereist voordat "De app in →" actief wordt. Tekst: alleen de bevestiging wordt bewaard, niet het document.
6. **Rondleiding** — start automatisch na rolkeuze. Wolkjes in Caveat mét pijltje die naar echte knoppen wijzen, bladeren door de tabs. Beheerder 4 stappen, vrijwilliger 3, hulpvrager 2. Overslaan kan altijd.

### Tabbalk (5 tabs)
`Rooster · Buurt · Kring · Steun · Profiel` — actief = navy pill met witte tekst; inactief = transparant, `#5A687A`.

### Rooster (hoofdscherm)
**Beheerder:** begroeting + datum → eventueel buddy-pool-matchmelding (groene kaart) → taak van vandaag met buddy-avatar en **belknop met telefoonnummer** (géén bevestigingsstap) → "Rooster · week 31" met groene knop **"+ Taak inplannen"**. Die opent een inline planner: *Wat is er nodig?* (Boodschappen / Wandelen / Vervoer / Gezelschap / **Anders** → vrij tekstveld) · *Welke dag?* (Ma–Zo) · *Hoe laat?* (4 sneltijden + exacte tijdkiezer) · *Herhalen?* (Eenmalig / Elke week) → "Zet in het rooster" + link "Hele week plannen →". Daaronder een **weekstrip** (Ma–Zo met stipjes per taak; oranje = open, groen = ingepland) en de gesorteerde taaklijst. Open taken hebben een knop "Buddy-pool". Onderaan **"Uit de kring"**: notities die vrijwilligers achterlaten na een taak.

**Vrijwilliger:** persoonlijke teller ("3 mensen geholpen") → uitnodiging / wachten-op-kennismaking → weekstrip + rooster van de kring. Open taken: knop **"Aannemen"**; eigen taken groen met "Jij gaat" en knop **"Rond af"** → logboekje (notitie) → taak wordt "Gedaan ✓" en de notitie verschijnt bij de beheerder onder "Uit de kring".

**Hulpvrager:** grote weergave — "Anna is nu bij je" met pulserende stip en grote belknop, daaronder "Straks: Tim komt om 16:00", plus herkenningstip.

### Weekplanning (conceptplanner)
Aparte pagina. Periode kiezen (1 week / 2 weken / 1 maand / 2 maanden) → bij meer weken verschijnen weekchips (Wk 31, 32 …). Taken komen in een **conceptlijst** (gestippelde kaartjes, verwijderbaar) — de kring ziet nog niets. Grote knop **"Publiceer X taken naar de kring →"** zet alles in één keer live, met bevestiging. Daaronder "Al gepubliceerd · week 31".

### Buurt (kaart)
Leaflet/OSM-kaart van Amsterdam. Bovenin een zoekveld **"Zoek hulpkringen"** met live filterende suggesties (filtert ook de markers; tik = kaart pant ernaartoe).
- **Beheerder:** filterchips Hulpkringen / Buddy's, plus CTA **"Directe hulp vragen"** → taaktype kiezen → "Zet op de kaart" (pulserende marker) → aanbod van een buddy mét berichtje → Toestaan / Afwijzen → "Tim is onderweg" + belknop → afronden. Adres blijft verborgen tot toestemming.
- **Vrijwilliger:** ziet **alleen** hulpkringen en directe hulpvragen (geen buddy's), met een teller linksboven: "4 kringen · 1 directe aanvraag in beeld" die live meetelt bij zoomen/slepen. Directe-hulpkaart: taak → berichtje typen → "Ik kan helpen" → wachten op akkoord → adres wordt zichtbaar → afronden of annuleren met bericht.

Marker-stijlen: hulpkring = witte cirkel Ø42 met navy rand en het logo-balkjespaar, met pootje; buddy = navy cirkel Ø26 met initiaal; directe hulp = navy cirkel Ø40–44 met groen bliksem-icoon en pulsering; eigen locatie = groene stip met witte rand.

### Kring
Gradient-header met kringnaam en subnav **Leden / Berichten**.
- **Leden:** ledenlijst met statuspillen; kaart **"Wie doet wat deze maand?"** (staafjes per persoon, met spreid-advies); knop "+ Vrijwilliger uitnodigen"; melding over de gratis limiet van 2 vrijwilligers.
- **Uitnodigen:** e-mail/TVZ-ID invoeren + "Best matches in de buurt" (afstand en ervaring, géén VOG of levels). Bij de derde vrijwilliger zonder abonnement → abonnementsscherm.
- **Berichten:** groepschat van de kring met automatisch antwoord in de demo.
- **Vrijwilliger:** kringoverzicht met waardering en ledenlijst, of een lege staat met "Bekijk de kaart".
- **Kring aanmaken** (lege staat → formulier → **koppelcode** `TVZ-4Q7B` in gestippelde kaart voor de hulpvrager → kringpagina).

### Steun & advies
Gradient-header, subnav **Forum / Hulpmakelaar**.
- **Forum:** "Stel een vraag aan de community" (inline composer), filterchips (Alles / Wonen / Werk / Financiën / Dementie), vraagkaarten met auteur, plaats, tijd, tag en aantal antwoorden. Thread-detail toont de vraag en antwoorden; antwoorden van hulpmakelaars hebben een **groene rand + badge "Hulpmakelaar"**. Zelf reageren kan.
- **Hulpmakelaar:** live chat. Header met drie overlappende avatars, "3 hulpmakelaars online · meestal antwoord binnen 2 minuten" en pulserende stip. Vertrouwelijkheidsnotitie, startvragen als chips ("Kan ik mijn ouders in huis nemen?", "Welke vergoeding kan ik krijgen?", "Ik ben overbelast, wat nu?"), typ-indicator (drie stuiterende bolletjes) en inhoudelijke antwoorden die doorverwijzen (Wmo, mantelzorgcompliment, respijtzorg).

### Profiel
Avatar met initiaal, naam, rolpill. **Geen VOG-badges en geen levels — die zijn bewust verwijderd; gebruik ze nergens.**
- **Vrijwilliger:** kaart "Ook helpen buiten je kring?" met buddy-pool-toggle (los bijspringen óf je vast aansluiten bij een andere kring), en "Mijn beschikbaarheid" met dagchips + toggle "Even afwezig" (vakantiemodus, amber melding).
- **Beheerder:** abonnementsregel (Gratis / €4,99 actief) met knop Upgraden of Beheren.
- **Beide:** instellingenlijst — Grotere letters (ouderen-modus), Agenda-koppeling, Meldingen, TVZ-ID, Uitloggen (rood).

### Overige schermen
- **Inbox** (belknop rechtsboven op Rooster, met groene ongelezen-stip): beheerder ziet aanvragen, ruilingen en herinneringen; vrijwilliger ziet ingetrokken hulpvragen, uitnodigingen en nieuwe taken.
- **Aanvraag beoordelen:** profiel van een onbekende vrijwilliger (afstand, ervaring in andere kringen, waardering) + zijn voorstelbericht → **"Start videokennismaking"** → pas ná de call verschijnt "Toelaten tot de kring". Afwijzen kan altijd.
- **Videokennismaking:** fullscreen navy gradient, grote avatar, live timer, zelfbeeld rechtsboven, drie ronde knoppen (mute / rood ophangen / camera).
- **Hulpvraag ingetrokken:** fullscreen melding voor de buddy, met geruststellende toon.
- **Abonnement:** €4,99 p/m in gradient-kaart met vier voordelen, groene CTA, daarna bevestigingsscherm.
- **Admin-dashboard** (los van de app): vier kerncijfers (42 hulpkringen, 128 buddy's, 92% taken vervuld, 12 taken vandaag), staafgrafiek groei per maand, taken per type, "2,1 uur gemiddelde tijd tot match". **Uitsluitend geaggregeerd en geanonimiseerd op wijkniveau** — geen intakes, codes, aanvragen of persoonsgegevens.

---

## Interacties & gedrag
- **Taakbanner:** nadat een vrijwilliger een taak claimt verschijnt bovenin een dunne navy pill ("Do 09:15 · Vervoer naar huisarts · jij gaat") die **blijft staan bij wisselen van tab**, wegdrukbaar is met ✕, en bij aantikken naar het rooster gaat. Bedoeling in productie: opnieuw tonen bij heropenen van de app en als het tijdstip nadert (lokale notificatie).
- Alle asynchrone stappen in het prototype zijn getimede simulaties (aanbod na 3s, akkoord na 2,5s, makelaar antwoordt na 1,8s) — in productie realtime events.
- Toetsenbord: focus op invoervelden schuift het scherm; op de Steun-tab verbergt de tabbalk zich zolang het toetsenbord open is.

## State (kern)
`role` · `screen/tab` · `hasKring` + `kringView` · `leden[]` (naam, type, status: Actief / Uitgenodigd / ID-check / Kijkt mee) · `rooster[]` (dag, datum, taak, tijd, wie, status: open/ingepland/gedaan, herhaal) · `draft[]` (conceptplanning) · `subscribed` · `spontMz` (none→compose→open→offer→active→done) · `spontVStage` (ask→sent→approved→done) · `vStatus` (invited→wacht→lid) · `poolOptIn` · `beschikbaar{}` · `vakantie` · `calSync` · `kringNotes[]` · `forumPosts[]` · `mkChat[]` · `walkthrough{role,step}`.

---

## Zo zou ik het bouwen (Expo + backend)

**Stack**
- **Expo (SDK 51+) met expo-router** — file-based routing sluit één-op-één aan op de schermstructuur: `app/(tabs)/rooster|buurt|kring|steun|profiel`, plus `app/(auth)/*` en modals voor videocall en directe hulp.
- **Supabase** als backend: Postgres + Auth (**magic link**, precies de wachtwoordloze flow uit het ontwerp) + Realtime (chat, directe hulp, roosterwijzigingen) + Storage (ID- en profielfoto's, private buckets) + Edge Functions (matching, notificaties, Stripe-webhooks). Row Level Security is hier cruciaal: gegevens van een kring mogen alleen zichtbaar zijn voor leden van die kring, en adressen pas na toestemming.
- **Kaart:** `react-native-maps` (Apple Maps op iOS) met custom markers; PostGIS in Supabase voor "wat is er in beeld"-queries.
- **Betalen:** RevenueCat of Stripe. Let op: een abonnement dat digitale functies in de app ontgrendelt, moet via **Apple In-App Purchase** (15–30% commissie) — reken daar in je businesscase op.
- **Video:** Daily.co of LiveKit (beide hebben een React Native SDK) voor de kennismaking; de UI bouw je zelf zoals in het ontwerp.
- **Notificaties:** `expo-notifications` + Expo Push, met lokale notificatie voor de taakherinnering.

**Datamodel (grofweg)**
`profiles` · `circles` · `circle_members` (rol: beheerder/buddy/hulpvrager, status) · `tasks` (circle_id, type, datum, tijd, herhaalregel, claimed_by, status) · `task_logs` (notitie na afronding) · `spontaneous_requests` (locatie, type, status) + `request_offers` (bericht, status) · `messages` (kringchat) · `forum_posts` + `forum_replies` · `broker_chats` · `invitations` · `subscriptions`.

**Volgorde**
1. Auth + rolkeuze + ID/profielfoto → 2. kring aanmaken en leden → 3. rooster + conceptplanner (het hart van de app) → 4. kaart met kringen → 5. directe hulp met realtime → 6. abonnement → 7. Steun & advies → 8. videokennismaking → 9. admin-dashboard (kan een simpele webpagina zijn).

**Werken met Claude Code**
Zet deze hele map in de repo, bijvoorbeeld als `docs/design/`. Open `TVZ App.dc.html` in je browser terwijl je bouwt en verwijs per scherm expliciet: *"Bouw het Rooster-scherm van de beheerder volgens docs/design/README.md, sectie Rooster; neem de tokens uit Design Tokens over in `theme.ts`."* Maak eerst `theme.ts` (kleuren, radii, typografie) en een setje basiscomponenten (Pill, Card, PrimaryButton, StatusPill, Chip, SectionHeader) — daarna gaat elk scherm snel.

**Juridisch/praktisch niet vergeten:** AVG en verwerkersovereenkomst (gezondheidsgerelateerde gegevens), bewaartermijn van ID-checks, aansprakelijkheid en verzekering rond vrijwilligerswerk, en een meld-/blokkeerfunctie (App Store-eis voor apps met user-generated content — nu nog niet in het ontwerp).

---

## Assets
- Logo: puur CSS/RN-vormen — twee liggende afgeronde balkjes (`#2A6CB0`, `#8DC93F`) boven een staande balk (`#1A4878` of wit). Lever als SVG mee vanuit het brandbook.
- Icoontjes: inline SVG in lijnstijl, `stroke-width 2.2`, ronde uiteinden → in RN: `lucide-react-native` of `react-native-svg` (stijl komt overeen).
- Avatars: nu gekleurde cirkels met initiaal — vervangen door de profielfoto uit registratie.
- Kaart-tiles: OpenStreetMap in het prototype; in de app Apple/Google Maps.
- Fonts: Baloo 2, Comic Neue, Caveat (Google Fonts, SIL Open Font License).

## Files
- `SUPERPROMPT.md` — kant-en-klare prompts voor Claude Code (kick-off met vragenronde, bouwopdracht, vervolg- en reviewprompts)
- `TVZ App.dc.html` — het volledige klikbare prototype (open in een browser; navigatiepaneel links)
- `screens/01-…25-….png` — screenshot van elk scherm, in de volgorde van de flow
- `reference/Thuisverzorgd-Brand-Guidelines-v3-Getekend.pdf` — het brandbook (leidend voor kleur, type, vorm en toon)
- `reference/Customer-Journey-TVZ.docx` — de oorspronkelijke customer journey
- `reference/ios-frame.jsx` — alleen het telefoonframe van het prototype; niet nodig in de app
