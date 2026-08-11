# Thuisverzorgd — herstructurering (voor Claude Code)

Dit document beschrijft **wat er in de app-structuur is veranderd** ten opzichte van de eerdere versie met een tabbalk onderaan. Het gaat over opbouw, navigatie, knoppen en flows — **niet** over kleuren, typografie of styling; die staan al vast in de designrichtlijnen (o.a. de groene ringel-streep boven pagina's, Baloo 2 + Comic Neue, mascotte Bo).

Referentie-ontwerp: `TVZ App v3.dc.html`. Screenshots in `screens/`.

---

## 1. Kern van de herstructurering

**De tabbalk onderaan is volledig verdwenen.** In plaats daarvan:

1. Na inloggen kies je een **rol** (`09-rolkeuze.png`): "Ik regel hulp voor iemand" (mantelzorger/beheerder) of "Ik wil helpen in de buurt" (vrijwilliger).
2. Mantelzorgers en hulpvragers komen daarna op een **keuzescherm met twee paden** (`01-keuzescherm.png`):
   - **"Ik wil het weten"** — het informatiepad: wegwijzer, forum, zorgmakelaars.
   - **"Ik wil hulp regelen"** — het hulppad: voorzieningen, planning, kring.
   - Onderaan een derde, kleinere knop: "Mijn gegevens en instellingen".
   - Bo (mascotte) staat naast de kop.
3. **Binnen een pad navigeer je met schuifjes bovenin** (horizontale pillen in de header), niet met tabs onderaan.
4. **Vrijwilligers slaan het keuzescherm over** en landen direct op de kaart met hulpvragen (`08-vrijwilliger-kaart.png`).

### De header (belangrijkste nieuwe component)
Elke pagina binnen een pad heeft dezelfde header, opgebouwd uit drie rijen:

| Rij | Inhoud |
|---|---|
| 1 | Terugpijl (alleen als je dieper dan niveau 1 zit) · **Bo-knop** (brengt je altijd terug naar het keuzescherm) · titel + subtitel van het pad · avatar rechtsboven (→ profiel) |
| 2 | **Kruimelspoor met bolletjes**: bijv. `Voorzieningen — Kapper aan huis`, of `Mijn planning — Taak inplannen`. Laatste bolletje is actief. |
| 3 | **Schuifjes** (pillen) van het huidige pad. Actief schuifje is gevuld. |

Schuifjes per pad:
- Informatiepad: **Wegwijzer · Forum · Zorgmakelaars**
- Hulppad: **Voorzieningen · Mijn planning · Mijn kring**
- Vrijwilliger: **In de buurt · Mijn taken · Steun**

Uitzonderingen:
- Op de **inplan-pagina** worden de schuifjes verborgen (je zit in een taak-flow, niet in navigatie).
- Op de **vrijwilligerskaart** heeft de header **geen gekleurde balk en geen zoekbalk**: alleen de drie schuifjes zweven als losse witte pillen over de kaart.

---

## 2. Informatiepad ("Ik wil het weten") — `02-info-wegwijzer.png`

Dit pad staat nu op de voorgrond: het is het eerste van de twee paden en de reden dat mensen de app openen.

**Wegwijzer** (startpagina van het pad), van boven naar onder:
1. Smalle strip "Vandaag: Tim komt om 10:00 voor boodschappen" met knop `Rooster →` (alleen als er een kring is).
2. **Hulpmakelaar-blok**: "Kom je er even niet uit?", avatars van online makelaars, twee knoppen: **Chat nu** en **Videobel** (videobellen opent hetzelfde belscherm als de kennismaking).
3. **Kennisbank**: raster van 6 onderwerpen (WMO & regelingen, Dementie, Respijtzorg, Geldzaken, Wonen & veiligheid, Zorg voor jezelf) met aantal artikelen. Tik → artikellijst → artikel. Onder elk artikel een knop naar de makelaar-chat.
4. **Meest gelezen**: 3 directe artikellinks met onderwerp-label.
5. **Stappenplannen** zijn opgenomen ín de wegwijzer (niet meer een eigen schuifje): uitklapbare kaarten met genummerde stappen (WMO aanvragen, dementie eerste stappen, respijtzorg regelen) + knop "Hulp bij dit stappenplan".

**Forum** en **Zorgmakelaars** zijn de andere twee schuifjes; inhoud ongewijzigd (forumlijst → thread → reageren; makelaarslijst → chat/videobellen).

---

## 3. Hulppad ("Ik wil hulp regelen")

### 3a. Voorzieningen — `03-voorzieningen.png`
Raster van bijna-vierkante blokjes, 2 kolommen. Eerste blokje is **Buddy** (uitgelicht, gratis/vrijwillig), daarna de betaalde diensten: kapper aan huis, boodschappen, maaltijden, schoonmaak, tuinman, massage & fysio, vervoer, hond uitlaten, klusjesman. Onderaan de regel dat alle aanbieders aan Thuisverzorgd gelieerd zijn en dat je in de app betaalt.

**Dienst-detail** (`04-dienst-detail.png`) — één pagina, geen blokjes/pillen:
- Hero met ronde aanbieder-avatar, dienstnaam, "met Samira · 1,2 km", sterren + rating + aantal beoordelingen, handgeschreven citaat over de aanbieder.
- "Wat kun je verwachten": korte omschrijving + regel `± 45 min · bij jou thuis · gelieerd aan Thuisverzorgd`.
- "Wanneer komt Samira?": tijdsloten als **radiolijst** met hairlines; eerste slot heeft label "snelst".
- Zwevende prijsbalk onderaan: prijs groot, "Betaal na het bezoek · gratis annuleren tot 24 u", knop **"Boek di 10:00"** (label volgt het gekozen slot).
- Daarna: afrekenen (Apple Pay / iDEAL, bedrag pas na het bezoek) → bevestiging met Bo → afspraak staat in de planning.

### 3b. Buddy-flow (belangrijk gewijzigd)
De kaart is **niet meer prominent**. Buddy zit als blokje in Voorzieningen en werkt zo:
1. Buddy-blokje → pagina met twee keuzes: **"Elke week, vast moment"** of **"Eenmalig, nu of binnenkort"**.
2. Bij beide keuzes gaat de app **zelf naar een kaartweergave met een laadindicator** ("Bo kijkt in je buurt…"), puur om te laten voelen hoeveel hulp er in de buurt is.
3. Daarna een kaartje: "In jouw buurt zijn 14 buddy's actief, verdeeld over 4 hulpkringen" met knop **"Bouw mijn hulpkring op"** (bij wekelijks) of **"Zet mijn hulpvraag op de kaart"** (bij eenmalig).
4. De volledige kaart is verder alleen te bereiken via **één klein knopje op de kringpagina**: "Laat Bo een buddy in de buurt zoeken".

### 3c. Mijn planning — `05-planning.png`
- Kop met begroeting + datum van vandaag; belletje rechtsboven voor de inbox.
- Kaart met wie er vandaag komt (naam, rol, tijd, taak, duur) + **Bel-knop**.
- **Dagbalk over de volle breedte** (7 dagen, met stipjes voor taken); weekpijltjes `‹ ›` staan in de kopregel erboven, 44px.
- Agenda opent standaard op **vandaag**.
- Onderaan de lijst met taken per dag: taak, tijd, duur, wie (of "Nog niemand — open voor de kring") met knop "Zoek buddy".
- Knop **"Taak inplannen"**.

### 3d. Taak inplannen — `06-taak-inplannen.png`
Één doorlopende pagina (geen stappen-wizard meer), van boven naar onder:
1. Regel "Voor de kring van Riet" met sluitkruis.
2. **Wat is er nodig**: raster met Boodschappen, Wandelen, Vervoer, Koken of eten, Gezelschap, Iets anders (vrij invulveld).
3. **Wanneer**: dagbalk van de week met weekpijltjes.
4. **Hoe laat**: rollende tijdpicker (uren/minuten) met selectieband in het midden; scrollt automatisch naar de gekozen tijd. Snelkeuzes ("Ochtend 09:00", "Middag 14:00", "Avond 19:00") zetten de picker mee.
5. **Herhaling**: eenmalig / elke week / elke twee weken.
6. **Wie**: "Wie kan" (open voor de kring) of een specifiek kringlid.
7. Vaste balk onderaan met samenvatting ("Wandelen · za 25 jul · 19:45") en knop **"In het rooster"**.
8. Na opslaan: terug naar de planning, **de agenda springt naar de ingeplande dag** en er verschijnt een groene bevestiging "Wandelen staat in het rooster." met sluitkruis.

### 3e. Mijn kring — `07-mijn-kring.png`
- Kringkop met naam en "Jij bent beheerder", plus twee tabjes: **Leden** en **Berichten** (Berichten is géén apart schuifje meer — het zit onder Mijn kring).
- Ledenlijst met rol en status.
- "Wie doet wat deze maand?" — staafjes per lid met aantal taken.
- Knoppen: **+ Vrijwilliger uitnodigen** en **Laat Bo een buddy in de buurt zoeken** (dit is het kleine knopje naar de kaart).
- **Kring opbouwen** is een begeleide sequentie van **6 stappen** met Bo (tip-regel bovenaan, "Stap x van 6", Vorige/Volgende onderaan):
  1. Voor wie regel je hulp? (naam + relatie)
  2. Adres & thuissituatie (met uitleg dat buddy's alleen de wijk zien)
  3. Wat is er nodig? (taken aanvinken)
  4. Voorkeuren (dagdelen + vrij veld "goed om te weten")
  5. Mensen uitnodigen (+ knop om Bo in de buurt te laten zoeken)
  6. **Proefweek**: Bo toont een voorstel-rooster; de kring probeert het een week en bevestigt daarna. Knop: "Start de proefweek".

---

## 4. Vrijwilliger — `08-vrijwilliger-kaart.png`
- Landt na registratie **direct op de kaart** (geen keuzescherm).
- **Geen gekleurde headerbalk en geen zoekbalk** op de kaart; alleen drie zwevende pillen: In de buurt · Mijn taken · Steun.
- Op de kaart: hulpkringen en losse hulpvragen als markers.
- **Kringen waar de vrijwilliger lid van is, staan als ronde knoppen rechtsonder opgestapeld** met labeltje "mijn kringen"; elke extra kring = een extra rondje. Tik → kringdetail.
- Vrijwilligers kunnen **géén directe hulp aanvragen** (dat verlenen zij juist), maar zien wel de hulpvragen van anderen.
- "Mijn taken" = eigen rooster met geclaimde en openstaande taken; "Steun" = dezelfde wegwijzer/forum voor de vrijwilliger zelf.

---

## 5. Wat is verwijderd
- Tabbalk onderaan (alle rollen).
- Abonnement (€4,99), upgrade-schermen, ledenlimiet, IAP.
- Losse "Berichten"-tab (nu onder Mijn kring).
- Stappenplannen als eigen tab (nu in de wegwijzer).
- Prominente buurtkaart als hoofdnavigatie voor mantelzorgers.
- De oude 3-staps-wizard voor taken inplannen (nu één pagina).

---

## 6. Vragen die je (Claude Code) moet stellen voordat je bouwt
Stel deze vragen expliciet aan Jelle; ga niet zelf aannames doen:

1. **Rol vs. pad**: moet de rolkeuze (mantelzorger/vrijwilliger/hulpvrager) éénmalig bij registratie vast staan, of moet iemand later kunnen wisselen? En blijft het pad-keuzescherm zichtbaar bij elke app-start, of alleen zolang er geen kring is?
2. **Hulpvrager (de oudere zelf)**: krijgt die exact dezelfde twee paden en dezelfde schuifjes, of een vereenvoudigde versie (grotere knoppen, minder opties)?
3. **Betalingen**: welke provider (Stripe met iDEAL + Apple Pay?), en moet het bedrag echt pas ná het bezoek worden afgeschreven (capture-later) met gratis annuleren tot 24 uur?
4. **Aanbieders**: komen die uit een handmatig beheerde lijst per wijk, of moet er een aanbieder-portaal/aanmeldproces zijn? Wie bepaalt de tijdsloten die je in de app ziet?
5. **Kring-proefweek**: wat gebeurt er na 7 dagen precies — een pushbericht met "werkte dit?" en dan bevestigen, of automatisch doorlopen?
6. **Zorgmakelaars**: zijn dat vrijwilligers met een profiel en online/offline-status? Videobellen: welke techniek, en moet er een wachtrij of directe verbinding zijn?
7. **Kennisbank-inhoud**: wie levert en beheert de artikelen en stappenplannen (CMS nodig?), en moeten ze offline leesbaar zijn?
8. **Kaart-privacy**: kringen worden op wijkniveau getoond en adressen pas na toestemming — moet dat ook gelden voor eenmalige hulpvragen?
9. **Notificaties**: welke gebeurtenissen sturen een pushbericht (nieuwe taak, buddy meldt zich, boeking bevestigd, proefweek-terugblik)?
10. **Vrijwilligerscheck**: bij registratie wordt nu een foto/ID-stap gedaan — moet dat blijven, en wordt dat ergens geverifieerd of alleen vastgelegd?
