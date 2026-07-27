# ANALYSE — legacy-inventarisatie, gap-analyse en v1-scope

> Status: opgesteld vóór de bouw (BLOK 1 van de superprompt), 27 juli 2026.
> Bronnen: `docs/design/README.md` + alle 25 screenshots (leidend), `docs/design/reference/Customer-Journey-TVZ.docx`, en een volledige inventarisatie van `docs/legacy-swift/` (~36.000 regels SwiftUI + 36 SQL-migraties + 14 edge functions).

---

## 1. Samenvatting legacy-app (SwiftUI "Buddy Care" / Thuisverzorgd)

Stack: SwiftUI (iOS 17+) + Supabase (Postgres/RLS/Realtime/Storage/Edge Functions) + APNs + Daily.co (video) + MapKit. Twee draaimodi (demo met mocks, live met Supabase). De app heeft twee grote pivots achter de rug: de **welzijn-pivot** (alle geldstromen, niveaus, cursussen en medische categorieën eruit) en de **zorgkring-pivot** (één vast team van buddies rond één hulpvrager werd het kernconcept).

### Rollen (legacy)
| Rol | Kern |
|---|---|
| `elderly` (hulpvrager) | vraagt hulp, heeft team of losse buddies, QR voor check-in, SOS |
| `buddy` (vrijwilliger) | mag pas taken aannemen na VOG **én** intake-videogesprek |
| `family` (mantelzorger) | koppelt via 6-cijferige code, dashboard + activiteiten-tijdlijn |
| `admin` | volwaardige beheerconsole: VOG's, intakes, partnercodes, organisaties, gebruikers, telefonische hulpvraag |

### Kernfeatures (legacy)
- **Zorgkring** (`care_teams`): ring-dispatch werving (5 buddies per 5 min), team-review door hulpvrager ("Liever niet"-weigering), inzetrooster met claims, vervangingsflow (ruilen/overnemen), escalatieladder voor ongevulde momenten (48u → 24u → 30 min urgent), teamchat met twee kanalen (iedereen / alleen buddies).
- **Spontane hulpvraag**: 8 min team-exclusief → pool binnen 2,5 km → 5 km → excuses-melding. Accept-RPC met race-bescherming. Statussen: open → accepted → arrived → inProgress → completed/cancelled.
- **Check-in/check-out**: selfie + QR-scan bij de hulpvrager + GPS-verificatie (≤500 m); check-out via verplichte tweede QR-scan.
- **Verificatie**: VOG (aanvragen/uploaden, admin keurt, 3 jaar geldig) + intake-videogesprek (wachtrij of zelf inplannen, Daily.co).
- **Gamification**: punten, multipliers, streaks, medailles (5 tiers), competities, teampunten met uitjes-doel.
- **Koppelcodes, drie soorten**: partnercode voor cliënten (gate staat uit), 6-cijferige familiecode, zorgkring-invitecode.
- **Meldingen**: push (APNs) + inbox met 30 klikbare meldingtypes, device tokens per gebruiker+rol.
- **Privacy**: privé-buckets met signed URLs, zichtbaarheid per profielveld, telefoonnummer alleen tijdens actieve taak, k-anonieme analytics-views (drempel ≥5), grove locatie (~1 km / PC4).
- **Toegankelijkheid**: grote letters, formeel aanspreken (u/jij), spraakinvoer, telefonische hulpvraag via admin.

De volledige scherm-, model- en servicelijst staat in het inventarisatierapport hieronder in §5.

---

## 2. Gap-analyse: legacy ↔ nieuw ontwerp

Legenda: **(a)** zit al in het nieuwe ontwerp · **(b)** ontbreekt in het nieuwe ontwerp maar is waarschijnlijk nodig · **(c)** bewust vervallen.

### (a) Zit al in het nieuwe ontwerp (soms in andere vorm)
| Legacy | Nieuw ontwerp |
|---|---|
| Zorgkring (`care_teams`) | **Hulpkring** (`circles`) — hart van de app |
| Inzetrooster met claims | **Rooster** + taakplanner + weekstrip + "Aannemen" |
| Spontane hulpvraag + pool | **Directe hulp** op de buurtkaart |
| Ring-dispatch/best match | "Best matches in de buurt" bij uitnodigen (afstand + ervaring) |
| Team-review + acceptatie door mantelzorger | **Aanvraag beoordelen** → videokennismaking → toelaten |
| Intake-videogesprek (Daily) | **Videokennismaking** (zelfde techniek, ander doel: beheerder ↔ onbekende vrijwilliger) |
| Teamchat | **Kring · Berichten** (één kanaal) |
| Inbox met klikbare meldingen | **Inbox** (belletje, ongelezen-stip) |
| Familiecode/invitecode | **Koppelcode** `TVZ-XXXX` voor de hulpvrager |
| Beschikbaarheid + niet-beschikbaar | **Dagchips + "Even afwezig"** (vakantiemodus) |
| Grote letters | **Ouderen-modus** (alles 1,3×) |
| Buddy helpt in meerdere kringen | **Buddy-pool** toggle op profiel |
| Reviews/waardering | Waardering zichtbaar bij aanvraag beoordelen + beoordeling-modal |
| Simpel cliëntscherm | **Hulpvrager-scherm** ("Anna is nu bij je", grote belknop) |
| Admin-analytics (k-anonieme views) | **Admin-inzichten**: uitsluitend geaggregeerd/geanonimiseerd |
| ID-upload (privé bucket, signed URL) | **ID + profielfoto** bij registratie vrijwilliger (alleen boolean bewaard) |
| Telefoon alleen bij actieve taak | Belknop met nummer op de taak van vandaag |
| Adres pas na acceptatie | Adres verborgen tot toestemming (directe hulp) |
| Abonnement €4,99 (customer journey; niet in legacy-code) | **Abonnement** €4,99/maand, gratis limiet 2 vrijwilligers |

### (b) Ontbreekt in het nieuwe ontwerp, waarschijnlijk wél nodig
| Item | Waarom | Voorstel |
|---|---|---|
| **Account verwijderen** | App Store-eis (5.1.1(v)); ontbrak óók in legacy | v1: verplicht. Knop in Profiel + edge function die alles wist |
| **Gebruiker blokkeren/rapporteren buiten het forum** | App Store UGC-eis geldt ook voor kringchat en directe hulp; legacy had niets | v1: melden+blokkeren op forum (in ontwerp), kringchat en aanvragen |
| **Taak annuleren door vrijwilliger** (reopen-flow) | Legacy: taak terug naar open, anderen gealerteerd, annuleerder overgeslagen | v1: overnemen voor rooster én directe hulp |
| **Taak/aanvraag intrekken door beheerder** ná claim | Legacy had fullscreen "ingetrokken"-scherm (zit in ontwerp voor directe hulp) | v1: ook voor roostertaken met nette melding |
| **Escalatie ongevulde taken** | Legacy-beleid: 48u → 24u → 30 min; nieuw ontwerp heeft alleen "Buddy-pool"-knop | v1-light: herinnering aan beheerder + buddy-pool; ladder in v1.1 |
| **Ruilen/overdragen van taken** | Inbox-copy in het ontwerp noemt "Dienst geruild"; legacy had volledige swapflow | v1: overdragen aan ander kringlid; formeel ruilen v1.1 |
| **Herhaling: vrij interval + einddatum** | Nieuw ontwerp: alleen Eenmalig/Elke week; legacy: elke N dagen/weken + einddatum + max 366 | v1: Eenmalig/Elke week (ontwerp is leidend); einddatum bij verwijderen serie |
| **Meerdere kringen per beheerder** | Legacy family kon meerdere ouderen beheren | v1: datamodel ondersteunt het; UI-switcher alleen als jij het wil |
| **1-op-1 chat** | Legacy had direct messages; nieuw ontwerp alleen kringchat + belknop | v1: weglaten (bellen volstaat), tenzij jij anders wil |
| **SOS** | Legacy half af (knoppen waren stubs) | Beslissing nodig — zie vragen |
| **Activiteiten-tijdlijn** | Legacy voor familie; nieuw ontwerp heeft "Uit de kring"-notities | v1: "Uit de kring" volstaat; tijdlijn niet bouwen |
| **Formeel aanspreken (u/jij)** | Legacy-voorkeur; nieuw ontwerp noemt het niet | v1: niet bouwen; copy is al warm-informeel — tenzij jij het wil |
| **Sessieverlies/scenePhase-refresh, uitlog-cleanup** | Legacy-bugfixes (avatar-lekkage tussen accounts!) | v1: meenemen als technische eis |
| **Sentinel onbekende geboortedatum, race-veilige accept-RPC, telefoonnummer-scoping** | Stille legacy-lessen | v1: meenemen in datamodel/RPC-ontwerp |

### (c) Bewust vervallen (NIET terugbouwen)
- **VOG-checks** (hele flow: aanvragen, uploaden, admin-review, verlopen) — geschrapt; vervangen door ID-check + videokennismaking + acceptatie door de beheerder.
- **Levels, punten, multipliers, streaks, medailles, competities, teampunten/uitjes-doel** — alle gamification is geschrapt. Alleen de neutrale teller "3 mensen geholpen" blijft.
- **Check-in/check-out** (selfie + QR + GPS) — geschrapt; vervangen door "Rond af" + logboekje.
- **Het woord "mantelzorger" in de UI** — vervangen door "beheerder".
- **Familie als aparte rol** — samengevoegd: de beheerder ís het familielid/de mantelzorger. Hulpvrager kijkt mee via koppelcode.
- **Admin als beheerconsole** — admin ziet uitsluitend geaggregeerde inzichten; geen gebruikersbeheer, geen intakewachtrij, geen VOG-review, geen telefonische hulpvraag.
- **Partnercodes en partnerorganisaties** — niet in het nieuwe ontwerp (gate stond in legacy al uit). Eventueel later.
- **Wachtwoorden, SMS-OTP, Sign in with Apple** — vervangen door magic link. (Let op: Apple kan "Sign in with Apple" alsnog eisen als we ooit social login toevoegen; met alleen magic link is dat niet nodig.)
- **Spraakinvoer, live routevolgen, in-app routebeschrijving, agenda-export van intakes** — niet in het nieuwe ontwerp.
- **Demo-modus als architectuurprincipe** — vervangen door seed-data + Supabase lokaal.
- **Oude punten-teams en medische taakcategorieën** — waren in legacy al gearchiveerd/verwijderd.

---

## 3. Voorstel definitieve scope v1

**Erin (v1):**
1. Auth: magic link (naam + e-mail), deep link terug de app in; rolkeuze; ID + profielfoto (alleen vrijwilliger, eenmalig); rondleiding met Caveat-wolkjes (4/3/2 stappen, overslaan kan).
2. Hulpkring: aanmaken, koppelcode voor hulpvrager, leden + statuspillen, uitnodigen (e-mail/TVZ-ID + best matches), gratis limiet 2 vrijwilligers, belastingverdeling "Wie doet wat deze maand?", kringchat.
3. Rooster: taakplanner (5 typen incl. Anders), weekstrip, conceptplanner (1 week–2 maanden, publiceren in één keer), claimen, afronden met logboekje, "Uit de kring"-notities, taakbanner, herinnering 1 uur vooraf.
4. Buurtkaart: kringen + buddy's (alleen beheerder) + directe hulpvragen, live teller, zoeken met live filtering, wijk-niveau-privacy.
5. Directe hulp: volledige flow beide kanten (plaatsen → aanbod+berichtje → toestaan/afwijzen → onderweg → afronden; annuleren met bericht), realtime.
6. Aanvraag beoordelen + videokennismaking + toelaten/afwijzen.
7. Meldingen: push + inbox met deeplinks, categorieën aan/uit, vakantiemodus gerespecteerd.
8. Steun & advies: forum (tags, threads, hulpmakelaar-badge, melden/blokkeren) + live hulpmakelaar-chat (wachtrij, "x online").
9. Abonnement: €4,99/maand via RevenueCat + Apple IAP.
10. Profiel: buddy-pool, beschikbaarheid, vakantiemodus, ouderen-modus (1,3×), agenda-koppeling, TVZ-ID, meldingen, uitloggen, **account verwijderen**.
11. Hulpvrager-scherm (groot, simpel) + admin-dashboard (alleen aggregaten).
12. Dwarsdoorsnede: RLS op alles + pgTAP-bewijzen, i18n/nl.json, accessibility, Sentry, EAS → TestFlight.

**Eruit (v1), bewust:** VOG, gamification, check-in/out, familie-rol, partnercodes, admin-beheer, 1-op-1 chat, spraakinvoer, live routevolgen, activiteiten-tijdlijn, formeel-aanspreken-toggle, SOS (tenzij anders besloten — zie vragen), Android-release (build voorbereiden kan wel).

**v1.1-kandidaten:** volledige ruilflow, escalatieladder, meerdere kringen-UI, SOS, Android.

---

## 4. Openstaande vragen

De vragenronde is aan de opdrachtgever gesteld in de chat (27-07-2026); de antwoorden worden verwerkt in `docs/PLAN.md` en als ADR's vastgelegd.

---

## 5. Volledig inventarisatierapport legacy

<details>
<summary>Klik open voor het volledige rapport (schermen, modellen, statussen, services, edge functions, edge cases)</summary>

### Rollen en registratie
- `UserRole`: `elderly` / `buddy` / `family` / `admin`. Admin niet kiesbaar bij registratie (DB-only via `set_user_role`).
- Auth: e-mail+wachtwoord, wachtwoord-reset, SMS-OTP, Sign in with Apple, 4 demo-ingangen.
- Buddy-gate: `canAcceptTasks = vogValid && intakeCompleted`.
- Cliënt-gate partnercode bestond volledig maar stond uit (`elderlyHasLinkingCode = true`).

### Schermen (samengevat per rol)
- **Gedeeld**: RootView-router, ConsentSheet (AVG, 2 opt-ins), splash, kaart-als-voorpagina (team-druppels, ~1 km vervaging), teamchat (2 kanalen), rol-walkthrough, intake-video (Daily), avatar-store met per-user cache.
- **Elderly** (Kaart · Hulp · Buddies · Profiel): hulpvraag-flow in 3 stappen (categorie → nu/gepland/periodiek → bevestigen), spraakinvoer, actieve-taakbanner met voortgang, live buddy-route, team-setup flow, team-review met "Liever niet", QR-sheet voor check-in, reviews, SOS-scherm (acties waren stubs), zichtbaarheid per veld, grote letters + formeel aanspreken.
- **Buddy** (Kaart · Profiel): onboarding 5 stappen (profiel → intake → VOG → klaar), kaart met open vragen + beschikbaar-toggle + "N open"-pil, taakdetail met ETA, lopende taak met stappenbalk, check-in (selfie → QR → GPS ≤500 m) en check-out (verplichte 2e QR), routepreview, inbox, 1-op-1 chat, zorgkringen (claims, swaps, teamchat), gamification-hub, intake-wachtrij/planner.
- **Family** (Kaart · Overzicht · Activiteit · Profiel): dashboard met ouderen-switcher, zorgkring starten namens oudere, bezoekenbeheer, activiteiten-tijdlijn, koppelen via 6-cijferige code.
- **Admin** (9 tabs): partnercodes, lidmaatschappen, VOG-review, intake-wachtrij + planning, telefonische hulpvraag, organisaties, gebruikers + rolwijziging, prijzenladder, instellingen.

### Status-enums
`TaskStatus`: open → accepted → arrived → inProgress → completed/cancelled · `TaskCategory`: 9 welzijnstypes · `TaskTiming`: now/today/scheduled · `HelpAudience`: pool/team · `CareTeamStatus`: forming/review/live/paused · `CareVisitStatus`: open/urgent/claimed · invites: pending/reminded/accepted/declined/expired · join-requests: pending/approved/rejected (source: search/fallback) · `VOGStatus`: 6 waarden · intake `call_status`: waiting/in_progress/completed/cancelled · `MembershipStatus`, `PartnerType`, `Gender`, `MedalTier`, `TeamChatChannel` (all/buddies), 30 inbox-typen.

### Backend
- ~34 tabellen (profiles per rol, tasks, care_teams+visits+invites+join_requests+messages, linking_codes, partner_codes, reviews, skipped_reviews, favorite_buddies, sos_events, device_tokens, intake_calls, notifications, direct_messages, analytics_events, consents, gamification-tabellen).
- k-Anonieme analytics-views (drempel ≥5), `buddy_map_pins`-view (alleen voornaam + grove locatie).
- ~42 RPC's, o.a. race-veilige `accept_task`, `redeem_linking_code`, swap-RPC's, `prevent_role_self_change`.
- 14 edge functions: pushmeldingen per gebeurtenis, `team-formation` (ring-dispatch cron), `schedule-watchdog` (escalatieladder cron), `intake-video` (Daily token), `notify-scheduled` (dagelijkse nudges).
- Storage: `avatars`, `vog-documents`, `check-in-selfies` — allemaal privé, signed URLs.
- Realtime op `tasks`; verder veel polling (5s–30s).

### Beleids-timings uit legacy (referentie)
Ring 5 buddies/5 min · 1 uur team-keuze · 8 min team-exclusief venster · escalatie 48u/24u/30min · 2u shift-herinnering · radius 2,5 km → 5 km · check-in ≤500 m · 5 min voorrang vaste buddies · reviews zichtbaar na 48u · VOG 3 jaar geldig · max 366 herhalingen.

### Edge cases om niet te vergeten
- Intrekken ná claim → fullscreen melding bij de buddy; annuleren door buddy → taak heropend, annuleerder overgeslagen bij heralertering.
- Eén actieve directe hulpvraag tegelijk per hulpvrager.
- Uitnodigingen vervallen als het team vol is; eerder geweigerde buddy mag later alsnog aansluiten.
- Uitloggen wist álle user-scoped state (avatar-cache-lekkage was een echte bug).
- Telefoonnummer buddy alleen zichtbaar tijdens actieve taak (bel-bug: ooit werd het supportnummer gebeld).
- Buddy-reviews over de cliënt zijn onzichtbaar voor de cliënt zelf.
- Sentinel-geboortedatum 1-1-1945 = "onbekend" (voorkomt nep-leeftijd).
- Eigen reisafstand van de buddy weegt zwaarder dan de systeem-fallbackradius.
- Geen account-verwijderen en geen blokkeren/rapporteren in legacy — beide zijn App Store-relevant en moeten in de nieuwe app wél.

</details>
