# Thuisverzorgd — twee paden, mascotte Bo & voorzieningen
Handoff voor Claude Code · augustus 2026 · bron: `TVZ App v3.dc.html` (Claude Design)

## 1. Het idee
Thuisverzorgd doet twee dingen, en de app vraagt bij het openen welke van de twee je nu nodig hebt:
1. **Ik wil het weten** — de wegwijzer met alles over mantelzorg, het forum met lotgenoten, en zorgmakelaars die met je meedenken.
2. **Ik wil hulp regelen** — buddy's uit de buurt in een hulpkring, en voorzieningen (kapper, tuinman, boodschappen…) direct in de planning.

Geen abonnement, geen IAP. Verdienmodel: transactiefee op geboekte voorzieningen.

## 2. Navigatie (nieuw)
**De tabbalk onderin is verdwenen.** In plaats daarvan:
- **Keuzescherm** als eerste scherm na inloggen: twee grote gekleurde kaarten + Bo.
- **Vaste header per pad** met: terugpijl (per stap), **Bo-knop** (altijd terug naar het keuzescherm), titel, avatar rechtsboven (profiel/instellingen), **kruimelspoor** met bolletjes (bijv. `Voorzieningen › Buddy › In de buurt`), en daaronder **schuifjes** (horizontale chips) voor de secties van dat pad.
- Info-pad schuifjes: **Wegwijzer · Forum · Zorgmakelaars**
- Hulp-pad schuifjes: **Voorzieningen · Mijn planning · Mijn kring · Berichten**
- Vrijwilliger: **In de buurt · Mijn taken · Steun** (slaat het keuzescherm over, landt direct op de kaart)

## 3. Kleuren
| | achtergrond | header |
|---|---|---|
| Info-pad | #F5F8FC | gradient #1A4878 → #2A6CB0 |
| Hulp-pad | #FFF8F8 | gradient #E85050 → #C9382F |
| Vrijwilliger | #F5F8FC | gradient #112F50 → #2A6CB0 |

Koraalrood #E85050 op zachtroze #FFF8F8 is de nieuwe hulp-kleur (uit de aangeleverde screenshots). Groen #8DC93F blijft accent voor "gratis/vrijwillig".

## 4. Info-pad
- **Wegwijzer**: makelaar-hero bovenaan (3 online, Chat nu / Videobel), kennisbank met 6 onderwerpen → artikellijst → artikel, en "Meest gelezen".
- **Stappenplannen** (WMO aanvragen, dementie eerste stappen, respijtzorg) als uitklapbare stappen, met "Hulp bij dit stappenplan" → makelaar.
- **Forum**: ongewijzigd. **Zorgmakelaars**: chat + videobellen (echt belscherm).

## 5. Hulp-pad
- **Voorzieningen**: raster van bijna-vierkante blokjes. Buddy is de uitgelichte tegel (gratis), daarnaast 9 betaalde diensten (kapper €29, boodschappen €7, maaltijden €9, schoonmaak €22/u, tuinman €35/u, massage €45, vervoer €12, hond uitlaten €10, klusjesman €30/u). Alle aanbieders zijn gelieerd aan Thuisverzorgd; betalen gebeurt in de app.
- **Dienst-detail**: lichtblauw hero-vlak, ronde aanbieder-avatar, sterren + beoordelingen, handgeschreven notitie, "wat kun je verwachten", tijdsloten als radio-lijst, zwevende prijskaart met "Boek di 10:00" → afrekenen (Apple Pay/iDEAL, pas afgeschreven na bezoek) → bevestiging met Bo → staat in de planning.
- **Buddy-flow**: Buddy-tegel → keuze *Elke week, vast moment* of *Eenmalig, nu of binnenkort* → **buurt-scan**: de app gaat automatisch naar een kaart met een laadindicator ("Bo kijkt in je buurt…") en meldt daarna "14 buddy's actief, verdeeld over 4 hulpkringen" → dan of de kringopbouw, of de hulpvraag op de kaart.
- De kaart is dus **niet meer prominent**: je komt er via de buddy-scan, of via het kleine knopje "Laat Bo een buddy in de buurt zoeken" op de kringpagina.

### Hulpkring opbouwen — 6 stappen (samen met Bo)
Elke stap: Bo-tip in een kaartje, één vraag, en de voortgang in het kruimelspoor.
1. **Voor wie** — naam + relatie
2. **Adres & thuissituatie** — met privacynotitie (buddy's zien alleen de wijk)
3. **Wat is er nodig** — taken aanvinken
4. **Voorkeuren** — dagdelen + "goed om te weten"
5. **Mensen uitnodigen** — bekenden uitnodigen + Bo laten zoeken
6. **Proefweek** — Bo's voorstel-rooster; de kring test het een week, mag taken ruilen, en bevestigt daarna (na 7 dagen vraagt Bo of het werkte)

## 6. Vrijwilliger
Landt direct op de kaart (geen keuzescherm, geen tabbalk). **Kring-rondjes rechtsonder gestapeld**: één rondje per kring waar hij lid van is, tikken opent die kring; word je lid van nog een kring, komt er een rondje bij. Vrijwilligers kunnen **geen** directe hulp aanvragen — die verlenen ze zelf — maar zien wel de hulpvragen van anderen.

## 7. Mascotte Bo
`mascot/bo.svg` (heel) en `mascot/bo-peek.svg` (kop over een rand).
- Rond wezentje met crème buik, blosjes en een blaadje-spruitje. 3D-gevoel via radiale gradients, glans linksboven en zachte slagschaduw. Warmer/"echter" palet dan de UI: #C8EC90 → #8CC64B → #619A2E, buik #FFF9EC → #F1DDBD, blosjes #F5A78F, ogen #223349.
- **Plekken**: welkomstscherm, keuzescherm, de Bo-knop in elke header (terug naar de twee paden), elke stap van de kringopbouw, de buurt-scan, de boekingsbevestiging, lege hulpkring-staat, buddy-pagina.
- **Meer ideeën**: pull-to-refresh, lege staten, push-icoon, laadscherm, foutmeldingen, sticker in de kring-chat na een afgeronde taak.
- **Regels**: max 1 Bo per scherm, nooit uitgerekt, niet op betaalschermen als afleiding.

## 8. Implementatienotities (Expo + Supabase)
- Navigatie: geen bottom tabs. Root stack = `PathChooser` → `InfoStack` / `HulpStack` / `VolunteerStack`. Header is één component dat pad-kleur, kruimelspoor (uit de routestack) en de schuifjes rendert. Bo-knop popt naar `PathChooser`.
- Tabellen: `services`, `providers`, `bookings` (slot, status, betaalstatus), `articles`/`guides`, `circles` + `circle_members` + `tasks`, `help_requests` (directe hulp), `brokers` (makelaars, online-status).
- Kringopbouw als wizard-state in één record (`circle_drafts`), stap 6 genereert voorstel-taken met `proposed = true`; na 7 dagen een bevestigingsprompt.
- Betalingen: Stripe (iDEAL + Apple Pay), capture-later, gratis annuleren tot 24 u.
- Buurt-scan: aggregaatquery (aantal buddy's + kringen binnen radius), bewust met korte laadanimatie.
- Bo-SVG's als assets bundelen.
