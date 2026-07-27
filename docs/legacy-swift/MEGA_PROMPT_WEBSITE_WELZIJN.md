# MEGA-PROMPT — Werk de Thuisverzorgd-website bij naar het vrijwilligers-welzijnsmodel

> **Voor:** een AI-coding-agent (Claude) die in de **website-repo** werkt (Next.js 16 / React 19 /
> TypeScript / Tailwind v4, NL, deploy op Vercel). Deze prompt is **zelfstandig**: alle benodigde
> visie staat hieronder. Verwijs niet naar externe documenten.
> **Doel:** de hele site herpositioneren van een **betaalde lichte-zorg-marktplaats** naar een
> **laagdrempelig vrijwilligers-welzijnsplatform**. Werk in kleine stappen, houd de site builds groen
> (`npm run build`), en behoud merk, techniek en huisstijl. Vraag niet om bevestiging — de keuzes staan vast.

---

## 0. Begin met een audit van je eigen repo

Lees eerst de hele website-repo: alle routes/pagina's, componenten, de data-bestanden (FAQ's, locaties),
de globale stijl en de afbeeldingen. Maak een korte inventarisatie van **waar het oude model (geld, zorg,
niveaus, vergoeding) in tekst, data en beeld voorkomt**. Geef dat overzicht terug vóór je wijzigt. Het kan
zijn dat sommige dingen al kloppen — bevestig dat dan en ga door.

---

## 1. De nieuwe visie (dit is nu Thuisverzorgd)

**Thuisverzorgd is een vrijwilligers-welzijnsplatform.** Het koppelt ouderen (en hun mantelzorgers) aan
vrijwillige **buddies** in de buurt voor **welzijn en gezelschap** — nadrukkelijk **géén zorg en géén geld**.
Denk aan: samen koffie, een wandeling, een praatje, boodschappen, samen koken, digitale hulp, gezelschap,
begeleiding naar een afspraak, het ontlasten van mantelzorgers. Tegen eenzaamheid, vóór verbinding.

**Kernprincipes (hard — niet afwijken):**
1. **Geen geldstroom.** Geen bijverdienen, uurtarief, commissie, wallet, uitbetaling, ZZP, IBAN/KvK/BTW.
   Buddies zijn **vrijwilligers**; ze doen het voor betekenisvol contact, ervaring en hun buurt — niet voor geld.
2. **Geen zorg-/medisch jargon.** Geen "lichte zorg", "behandeling", "cliënt/patiënt", "Wet BIG", medische taken.
   Vervang door welzijnstaal: welzijn, gezelschap, vrijwillig, hulpvrager, samen, verbinding.
3. **Geen niveaus/cursussen als kern.** Eén type buddy, iedereen gelijk. Geen 4 niveaus, geen verplichte
   cursussen die taken ontsluiten.
4. **Eén lichte drempel voor buddies:** aanmelden en rondkijken mag direct; je kunt pas **taken aannemen** na
   een **korte intake (~5 min)** én een **VOG** (Verklaring Omtrent Gedrag — gratis voor vrijwilligers).
5. **Toegang voor ouderen/familie via een koppelcode.** Geen Wmo/pgb/particulier betalen. Cliënten komen
   binnen via een **koppelcode** die door een **partner** (gemeente, zorgverzekeraar, werkgever,
   welzijns-/zorgorganisatie) wordt uitgegeven. Het platform is voor de eindgebruiker **kosteloos**.
6. **Merk & term behouden:** naam **Thuisverzorgd**, de rol heet **Buddy**. Tagline-richting:
   "Een vertrouwde buddy om de hoek." / "Samen tegen eenzaamheid." / "Welzijn dichtbij, voor elkaar geregeld."
7. **Toon:** warm, menselijk, optimistisch, laagdrempelig. Niet zakelijk-zorg, niet salesy-gig-economy.

**De vier rollen (mag je benoemen waar relevant):**
- **Hulpvrager / oudere** — zoekt gezelschap en lichte hulp in het dagelijks leven.
- **Buddy / vrijwilliger** — biedt zich vrijwillig aan (vaak jonge mensen/studenten, maar iederéén is welkom).
- **Familie / mantelzorger** — regelt en kijkt mee namens een oudere.
- **Partner / organisatie** — gemeente/verzekeraar/werkgever/welzijnsorganisatie die toegang (koppelcodes) regelt.

---

## 2. Herpositionering per onderdeel (oud → nieuw)

Pas dit toe op de bestaande structuur (homepage-secties, de aparte pagina's, componenten, data en beeld).

### Homepage
- **Hero:** vervang "Uber Eats voor lichte zorg / Zorg dichtbij" door een **welzijns-boodschap**
  ("Welzijn dichtbij, voor elkaar geregeld" / "Een vertrouwde buddy om de hoek"). Knoppen **"Word buddy"**
  en **"Ik zoek gezelschap/hulp"** blijven. **Verwijder de prijs** uit het zwevende taak-kaartje
  (bijv. "Gezelschap & wandeling · 1,2 km" — **zonder €-bedrag**). Sociale proof mag blijven, maar herijk
  cijfers naar vrijwilligers-taal ("1.200+ vrijwilligers", "samen X momenten van contact").
- **Trust bar:** herschrijf statistieken naar welzijn (bv. aantal vrijwilligers, geholpen ouderen, gemiddelde
  waardering, snelle match) — **geen** "verdiend" of geldbedragen.
- **Hoe het werkt (3 stappen):** herschrijf stap 3 van "helpen & verdienen" naar **"samen tijd doorbrengen"**
  / "helpen & betekenis". Geen verdien-frame.
- **Vergoeding-sectie (Wmo/pgb/particulier):** **vervang volledig** door **"Voor wie & hoe kom je binnen"**:
  het platform is kosteloos; ouderen/familie krijgen toegang via een **koppelcode** van een partner. Leg dit
  vriendelijk uit (geen administratief/financieel jargon).
- **Voor buddies (voordelen):** vervang "bijverdienen" door vrijwilligers-voordelen: **betekenisvol contact /
  iets terugdoen**, **flexibel (jij kiest wanneer)**, **waardevolle ervaring (mooi op je cv / voor (zorg)studie)**,
  **dichtbij in je eigen buurt**, **nieuwe mensen leren kennen**.
- **Kwaliteit & vertrouwen (4 BIG-niveaus):** **verwijder de niveaus.** Vervang door: **één type buddy**,
  **VOG-screening**, **korte persoonlijke intake**, **reviews/waarderingen**, en het feit dat je pas taken
  aanneemt ná VOG + intake. Frame als veiligheid & vertrouwen, niet als zorgbevoegdheid.
- **Coverage-kaart:** behouden (interactieve kaart met steden). Herlabel waar nodig naar "vrijwilligers in de
  buurt" i.p.v. betaalde dekking. Mock-data mag blijven.
- **Testimonials:** behouden, maar herschrijf de quotes naar **welzijn/gezelschap** (niet "lekker bijverdiend"
  → wel "zinvol", "gezellig", "fijn contact", "minder eenzaam").
- **App-download / showcase:** behouden (binnenkort iOS/Android). **Vervang de app-screenshot "cursussen"**
  door een passende welzijns-screen (bv. kaart, taak, of onboarding) — geen cursussysteem tonen.
- **FAQ + Final CTA:** herschrijf naar het vrijwilligersmodel (zie FAQ hieronder).

### Pagina /word-buddy
- Herschrijf voordelen en het aanmeldproces naar **vrijwilliger worden**: aanmelden kan direct; daarna
  **korte intake (~5 min)** + **VOG aanvragen (gratis)**; daarna kun je taken aannemen. **Geen** ZZP-,
  bank-, tarief- of niveaustappen. Benadruk laagdrempeligheid en betekenis. App-impressie mag blijven.

### Pagina /hulp-aanvragen
- Herschrijf naar **gezelschap/welzijn aanvragen**. Vervang de **Wmo-vergoeding-sectie** door uitleg over de
  **koppelcode** (hoe je die krijgt via je gemeente/verzekeraar/werkgever/welzijnsorganisatie; platform is
  kosteloos). Takenlijst herijken naar welzijnstaken (gezelschap, wandelen, boodschappen, samen koken,
  digitale hulp, begeleiding afspraak, klusjes, voorlezen, spelletjes) — **geen** medische taken.
  Veiligheid/screening (VOG + intake + reviews) behouden en als geruststelling presenteren.

### Pagina /over-ons
- Missie aanscherpen: **eenzaamheid en groeiende zorgvraag** vs. **kracht van vrijwillige verbinding tussen
  generaties**. Kernwaarden herijken naar welzijn/menselijkheid/laagdrempeligheid. Quote en CTA behouden,
  maar zonder geld-/zorgframe.

### Pagina /zorgorganisaties → hernoem naar /partners (of /voor-organisaties)
- Herpositioneer het B2B-spoor naar **partners die toegang mogelijk maken**: gemeenten, zorgverzekeraars,
  werkgevers, welzijns- en zorgorganisaties die **koppelcodes** uitgeven aan hun doelgroep en zo eenzaamheid
  helpen verminderen / mantelzorgers ontlasten. Voordelen herschrijven (bereik, welzijnsimpact, ontlasten van
  professionals, rapportage op geaggregeerd niveau). Behoud een kennismaking-CTA (e-mailadres mag blijven;
  pas de tekst aan naar partnerschap i.p.v. inkoop van zorg). Werk interne links/redirects bij als je de route
  hernoemt.

### Pagina's /contact, /veelgestelde-vragen, /privacy, /voorwaarden, /cookies
- **Contact:** behouden; tekst checken op zorg-/geldtermen.
- **FAQ (data-bestand):** herschrijf alle buddy- én cliënt-vragen naar het vrijwilligersmodel. Verwijder
  vragen over verdienen/uitbetaling/tarieven/niveaus/Wmo; voeg toe: "Kost het geld?" (nee, kosteloos via
  partner-koppelcode), "Krijg ik betaald als buddy?" (nee, het is vrijwilligerswerk; wel betekenisvol +
  ervaring), "Wat is een koppelcode en hoe kom ik eraan?", "Heb ik een VOG nodig?", "Wat houdt de intake in?".
- **Juridisch:** privacy/voorwaarden/cookies controleren en aanpassen aan vrijwilligers-/welzijnscontext
  (geen betaaldienst/marktplaats-bepalingen; wel vrijwilligers, koppelcodes, gegevensverwerking).

---

## 3. Data, beeld en stijl

- **Locatiedata:** mag blijven; herlabel betekenis naar "vrijwilligers in de buurt".
- **Afbeeldingen:** behoud de warme sfeerfoto's. Vermijd beelden die de cursussen/niveaus of betaling
  suggereren. Vervang/verberg de "cursussen"-appscreen.
- **Iconen & componenten (knoppen, secties, hero, kaart, FAQ, store-badges):** hergebruiken; alleen inhoud
  en labels wijzigen. **Introduceer geen nieuwe visuele taal.**
- **Huisstijl:** behoud navy (#1a4878-richting) + fris groen (#8dc93f-richting), afgeronde hoeken, zachte
  schaduwen, Montserrat (koppen) + Open Sans (tekst).
- **Taal:** alles Nederlands; consistent welzijns-vocabulaire. Verwijder elk overgebleven woord uit het
  oude model (verdienen, tarief, €, Wmo/pgb, niveau, BIG, lichte zorg, cliënt/patiënt).

---

## 4. Werkwijze & oplevering

1. **Eerst de audit** (sectie 0) teruggeven: waar zit het oude model in tekst/data/beeld?
2. Werk daarna pagina voor pagina (begin met de homepage, dan /word-buddy en /hulp-aanvragen, dan de rest).
3. Houd de build groen na elke pagina; los TypeScript-/lint-fouten direct op.
4. Werk interne links, navigatie (header/footer), metadata/SEO-teksten en de 404 bij waar termen wijzigen.
5. **Formulieren:** deze zijn nog niet aan een backend gekoppeld — laat de werking ongemoeid, maar pas wel de
   **velden/teksten** aan het vrijwilligersmodel aan (bv. buddy-aanmelding vraagt geen bankgegevens/ZZP;
   hulp-aanvraag noemt de koppelcode). Markeer de backend-koppeling als logische volgende stap.
6. Lever een korte changelog per pagina (wat gewijzigd, welke termen verwijderd/toegevoegd).

**Definition of done:** de hele site communiceert consistent het **vrijwilligers-welzijnsmodel** — geen geld,
geen zorgjargon, geen niveaus, geen Wmo/pgb. Buddies = vrijwilligers (intake + VOG vóór taken); ouderen/familie
komen kosteloos binnen via een partner-koppelcode; partners maken toegang mogelijk. Merk, techniek en huisstijl
zijn behouden; alle teksten zijn Nederlands; de site bouwt en is deploy-klaar op Vercel.
