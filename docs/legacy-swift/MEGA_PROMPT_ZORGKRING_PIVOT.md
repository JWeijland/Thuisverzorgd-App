# MEGA PROMPT — ZORGKRING-PIVOT

> **Kern:** de app draait voortaan om de **zorgkring**: één vast team van buddies rond elke
> hulpvrager. Zodra een hulpvrager haar onboarding afrondt, wordt ze actief "aangeboden"
> aan buddies in de buurt met de pushmelding **"Riet zoekt een team aan buddies, doe jij mee?"**.
> Het team vult via het schema alle hulpmomenten. Alleen bij gaten (spontane vraag of
> ongevuld schemamoment) valt de app terug op willekeurige buddies in de buurt.
>
> Er komt **één teambegrip**: de zorgkring vervangt zowel het huidige `CareTeam` als de losse
> gamification-teams. Competities, punten en prijzen hangen voortaan aan de zorgkring.

Bron: Q&A met Jelle d.d. 19-07-2026 (25 vragen beantwoord). Werkt met **echte data**
(TestFlight/Supabase). Claude schrijft SQL-migraties + deployt edge functions; **Jelle draait
de SQL** in Supabase.

---

## 1. De teamvormings-flow (nieuwe hulpvrager)

### 1.1 Trigger
- Teamvorming start **pas nadat de hulpvrager haar (begeleide) onboarding volledig heeft
  afgerond** — niet direct bij registratie.
- In de onboarding kiest de hulpvrager (of het gekoppelde familielid — beiden kunnen dit):
  - **Modus:** `team` (standaard, aanbevolen) of `random_only` (alleen losse buddies, zie §6).
  - **Gewenste teamgrootte:** minimum én maximum aantal buddies (door haarzelf in te stellen).
- De hulpvrager gaat pas **"live"** (zichtbaar/actief voor hulpvragen) zodra het **minimum**
  aantal teamleden is bereikt én zij het team heeft gereviewd (§1.4).

### 1.2 Ring-dispatch (uitnodigingen versturen)
- Kandidaten = buddies wier **eigen ingestelde straal** (`max_distance_km`) de afstand tot de
  hulpvrager dekt. De straal van de búddy is leidend; we nodigen nooit iemand uit buiten
  zijn/haar eigen voorkeur.
- Volgorde: **dichtstbijzijnde eerst**, in ringen:
  - t=0: ring 1 (de N dichtstbijzijnde kandidaten),
  - t=+5 min: ring 2 (volgende N),
  - t=+5 min: ring 3, enzovoort — **elke 5 minuten een volgende ring** tot het gewenste
    (maximum)aantal toezeggingen binnen is of de kandidaten op zijn.
  - Default ringgrootte N = 5 (constante, makkelijk aanpasbaar).
- Pushmelding aan buddy: **"«Voornaam» zoekt een team aan buddies, doe jij mee?"** met
  in-app uitnodigingskaart.
- **Privacy vóór toetreding:** buddy ziet alleen voornaam, wijk/plaats (geen adres), soort
  hulp en gewenste frequentie. Volledig adres en details pas ná toetreding én acceptatie.
- Zodra het **maximum** aantal toezeggingen binnen is: openstaande uitnodigingen vervallen
  automatisch ("het team van Riet zit vol").

### 1.3 Team niet vol na 1 uur
- Na **1 uur** zonder vol team krijgt de hulpvrager (en familie) een melding met de keuze:
  1. **Doorgaan met het huidige team + gaten opvullen met willekeurige buddies**, of
  2. **Voorlopig alleen met de huidige teamleden** verder.
- Tegelijk krijgen buddies in de buurt die de uitnodiging **afwezen of negeerden** éénmalig
  een herinnerings-push: "Het team van Riet is nog niet vol — wil je toch meedoen?"
- Daarna stopt actieve werving; het team blijft **open voor join-verzoeken** (§7.2).

### 1.4 Review & acceptatie door de hulpvrager
- Zodra het minimum is bereikt (of de hulpvrager kiest bij §1.3 om door te gaan) toont de app
  de hulpvrager/familie een **korte review van het team**: per buddy foto, voornaam, bio,
  rating.
- De hulpvrager kan individuele buddies **weigeren** → die worden uit het team verwijderd
  (nette melding aan de buddy, geen reden verplicht). Weigeren kan het team onder het
  minimum brengen → werving loopt dan door.
- Na acceptatie is het team **live**: teamleden zien nu volledige gegevens en het schema.

---

## 2. Eén teambegrip (datamodel-unificatie)

- De **zorgkring** (`care_teams`) wordt hét team. De losse gamification-teams (`teams`,
  aangemaakt door buddies zelf) verdwijnen als apart concept.
- **Gamification verhuist naar de zorgkring:** competities, punten, uitjes-doelen en prijzen
  hangen voortaan aan de zorgkring waar de buddy in zit. Een buddy in meerdere zorgkringen
  doet met elke kring mee.
- Regels:
  - Eén hulpvrager heeft **precies één team**.
  - Eén buddy kan in **meerdere zorgkringen** zitten (mag, graag zelfs — geen maximum).
  - Buddies kunnen teams **zoeken en een join-verzoek doen**, maar **niet zelf een team
    aanmaken** (teams ontstaan alleen rond een hulpvrager).
  - Een buddy die ooit een uitnodiging afwees kan **later alsnog een join-verzoek** doen;
    de hulpvrager/familie keurt goed of af.
- Migratie bestaande data: bestaande `care_teams` krijgen de nieuwe velden met veilige
  defaults en worden `live`; bestaande gamification-teams worden uitgefaseerd (leden krijgen
  een inbox-bericht; competitiestanden bevroren/gearchiveerd).

---

## 3. Schema & claims (het hart van de zorgkring)

### 3.1 Aanmaken en wijzigen
- De **hulpvrager (of familie) maakt het schema**: terugkerend weekritme én losse afspraken,
  beide mogelijk. Een hulpvrager die alleen sporadisch hulp vraagt hoeft géén schema.
- Bij een **nieuw schema of nieuwe momenten**: pushmelding aan alle teamleden — "Er staan
  nog momenten open voor Riet, claim jouw plekken."
- Bij **wijziging** van het schema: melding aan alle teamleden (en aan de buddy die een
  gewijzigd/vervallen moment had geclaimd).
- Teamleden **claimen** momenten (bestaande `claimCareVisit`-mechaniek blijft de basis).

### 3.2 Ongevuld moment — escalatieladder
| Moment | Actie |
|---|---|
| **48 uur** vóór het moment, nog niet geclaimd | 1e herinnering aan alle teamleden |
| **24 uur** vóór het moment, nog niet geclaimd | 2e herinnering aan alle teamleden |
| **30 minuten** vóór het moment, nog niet geclaimd | **Urgente broadcast** ("zsm") aan alle beschikbare buddies in de buurt (fallback-pool, §4) |

- De bestaande fase32-regels (claim_deadline/release) worden vervangen door deze ladder.

---

## 4. Spontane hulpvragen & fallback

- **Spontane hulpvraag** van een hulpvrager mét team:
  1. Eerst **exclusief naar de teamleden** (push + in-app).
  2. Na **8 minuten** zonder acceptatie door een teamlid → melding naar **alle beschikbare
     buddies in de buurt** (fallback-pool).
- **Fallback-pool** = buddies wier eigen straal de afstand dekt, dichtstbijzijnde eerst; het
  zoekgebied groeit **tot maximaal 5 km**.
- **Niemand gevonden** (ook niet binnen 5 km): hulpvrager krijgt een nette melding met
  **excuses** dat er geen buddy in de buurt gevonden is, en — als ze nog geen (vol) team
  heeft — het **advies om een team te bouwen** (met directe knop naar teamvorming).
- **Open-hulpvragenlijst / open-pil:** toont voortaan **alleen fallback-vragen**
  (team-exclusieve vragen zijn niet openbaar zichtbaar).

### 4.1 Invaller → teamlid
- Helpt een fallback-buddy een hulpvrager met team, dan stelt de app na afloop voor om
  **vast teamlid te worden**. De buddy kan een join-verzoek sturen; de **hulpvrager moet
  accepteren** voordat de buddy in het team komt.

---

## 5. Zorgvrager- en familiekant

- De hulpvrager ziet: **haar team** (gezichten, namen), **wie er wanneer komt** (schema met
  claims) en de wervingsstatus ("we zoeken nog 2 buddies voor je").
- **Familie kan het team volledig meebeheren**: teamgrootte instellen, buddies
  accepteren/weigeren, schema opgeven en wijzigen.
- De hulpvrager (en familie) kan een teamlid op elk moment **verwijderen** uit de kring.

---

## 6. Random-only modus & vaste buddies

- Kiest de hulpvrager bij onboarding **"geen team, alleen losse buddies"**, dan werkt alles
  via de fallback-pool (§4) en:
  - kan zij **vaste buddies** aanstellen (bestaande hart/favorieten-functie, fase34) —
    vaste buddies krijgen bij haar hulpvragen als eerste een melding;
  - **de vaste-buddy-functie bestaat alléén in deze modus**; binnen een team vervangt het
    team dat concept.
- **Latere conversie naar team:** wil ze alsnog een team, dan worden **eerst haar vaste
  buddies uitgenodigd**, met een speciale push: "Je bent al vaste buddy van Riet — zij bouwt
  nu een team, doe je mee?" Pas daarna start de normale ring-dispatch voor de resterende
  plekken.

---

## 7. Buddy-kant UI

### 7.1 Home rond zorgkringen
- De buddy-home wordt herontworpen met **"jouw zorgkringen" als centrale ingang**: per kring
  de hulpvrager, openstaande momenten om te claimen, teamactiviteit en competitie/punten.
- Open-pil/kaart toont alleen nog fallback-vragen (§4).

### 7.2 Teams zoeken
- Nieuw scherm **"Teams in de buurt"**: zorgkringen binnen de eigen straal die nog niet vol
  zitten (voornaam + wijk + soort hulp; privacyregels van §1.2 gelden).
- Buddy kan een **join-verzoek** sturen; hulpvrager/familie keurt goed of af. Ook mogelijk
  voor teams die de buddy eerder afwees.
- **Zelf een team aanmaken kan niet meer.**

---

## 8. Technische invulling

### 8.1 SQL-migratie `fase35_zorgkring.sql` (Jelle draait deze)
- `care_teams` uitbreiden: `min_size int`, `max_size int`, `status text`
  (`forming` / `review` / `live` / `paused`), `mode` op de hulpvrager
  (`elderly_profiles.team_mode text: 'team' | 'random_only'`).
- Nieuw: `care_team_invites` (team, buddy, `ring int`, `status: pending/accepted/declined/
  expired/reminded`, `sent_at`, `responded_at`) — logt de ring-dispatch en maakt de
  1-uur-herinnering en "later alsnog joinen" mogelijk.
- Nieuw: `care_team_join_requests` (buddy → team, status, beslist door hulpvrager/familie).
- `care_team_visits`: escalatievelden (`reminder_48_sent`, `reminder_24_sent`,
  `broadcast_sent`) i.p.v. de oude `claim_deadline`/`released`.
- `tasks`: veld `team_exclusive_until timestamptz` (8-minutenvenster) en `is_fallback bool`
  (bepaalt zichtbaarheid in de open lijst).
- RLS: teamleden + hulpvrager + gekoppelde familie zien teamdata; invites alleen voor de
  betrokken buddy; open lijst filtert op `is_fallback`.
- RPC's: `accept_team_invite`, `decline_team_invite`, `review_team_member`
  (accepteren/weigeren), `request_join_team`, `respond_join_request`, `claim_visit`,
  `remove_team_member`.
- Migratie gamification → zorgkring (competitie-koppeling omhangen, oude teams archiveren).

### 8.2 Edge functions (Claude deployt)
- **`team-formation`** (cron, elke minuut): verstuurt ringen (elke 5 min de volgende),
  vult tot max, laat invites vervallen bij vol team, triggert na 1 uur de keuzemelding aan
  de hulpvrager + de éénmalige herinnering aan weigeraars.
- **`schedule-watchdog`** (cron): de 48u/24u/30min-ladder uit §3.2 + de 8-minuten-fallback
  uit §4 (zet `is_fallback`, stuurt broadcast). Fallback-escalatie tot 5 km; daarna de
  excuses-melding met team-advies.
- Bestaande `notify-*` functies hergebruiken voor de pushkanalen; nieuwe notificatietypes:
  `team_invite`, `team_invite_reminder`, `team_review_ready`, `team_choice_needed`,
  `slot_reminder_48`, `slot_reminder_24`, `slot_urgent`, `schedule_changed`,
  `join_request`, `invite_as_member`, `no_buddy_found`.

### 8.3 App (Swift)
- Onboarding hulpvrager uitbreiden (begeleid): teamwens, min/max, uitleg.
- Nieuwe schermen: uitnodigingskaart (buddy), team-review (hulpvrager/familie),
  wervingsstatus, "Teams in de buurt", herontworpen buddy-home rond zorgkringen.
- `AppState+CareTeams` / `AppStateLive+Teams` samenvoegen tot één teamlaag;
  gamification-modellen omhangen naar de zorgkring.
- Inbox-deep-links voor alle nieuwe notificatietypes (patroon van commit 7340fa2 volgen).

### 8.4 Volgorde van bouwen
1. **Fase 35A** — datamodel + RLS + RPC's (SQL) en modellaag in de app.
2. **Fase 35B** — onboarding hulpvrager + teamvormings-engine (`team-formation`) +
   uitnodigings-/review-UI.
3. **Fase 35C** — schema-meldingen + `schedule-watchdog` (48/24/30-ladder, 8-min-fallback,
   5 km-escalatie, excuses-flow).
4. **Fase 35D** — buddy-home herontwerp, "Teams in de buurt", join-verzoeken,
   invaller-naar-teamlid.
5. **Fase 35E** — random-only modus + vaste-buddy-conversie; gamification-merge afronden.

---

## 9. Vastgelegde defaults (door Claude gekozen, aanpasbaar)

1. **Ringgrootte = 5 buddies** per ring van 5 minuten.
2. **Fallback-straal** start dichtstbijzijnde-eerst en groeit tot **max 5 km**, maar altijd
   binnen de eigen straalvoorkeur van de buddy (antwoord 6 weegt zwaarder dan de 5 km).
3. Bij het vervallen van gamification-teams worden competitiestanden **bevroren en
   gearchiveerd**, niet verwijderd.
4. Ringen op basis van **afstand-volgorde** (batches), niet vaste km-schillen.
5. Vraag 16 (laatste-kans-herinnering) is ingevuld door de 48u/24u-ladder van antwoord 15.
