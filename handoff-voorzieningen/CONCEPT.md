# Thuisverzorgd — Voorzieningen-concept & mascotte Bo
Handoff voor Claude Code · augustus 2026 · bron: `TVZ App v2.dc.html` (Claude Design)

## 1. Het vernieuwde app-idee
Thuisverzorgd is een alles-in-één app voor mantelzorgers en zorgzoekenden:
1. **Geïnformeerd raken** via de Steun-pagina (kennisbank, stappenplannen, forum).
2. **Alles regelen** via Voorzieningen: commerciële diensten aan huis én gratis vrijwillige hulp (Buddy) in één marktplaats.
3. **Vastlopen? Mens erbij**: mantelzorgmakelaar uit de buurt, direct via chat of videobellen vanuit Steun.
4. Hulpkringen + rooster blijven bestaan; het "vrijwilliger op bezoek"-idee is nu één van de voorzieningen i.p.v. de kern.

**Abonnement (€4,99) is volledig verwijderd.** Geen ledenlimiet, geen upgrade-schermen, geen IAP. Verdienmodel: transactiefee op geboekte diensten.

## 2. Navigatie
Tabbalk beheerder & hulpvrager: **Steun (home) · Voorzien · Buurt · Kring · Profiel**
Tabbalk vrijwilliger: **Rooster · Buurt · Kring · Steun · Profiel** (ongewijzigd takengericht)
Na login/rolkeuze landt een beheerder/hulpvrager op Steun.

## 3. Steun (home)
Header: blauwe gradient (#112F50→#2A6CB0), subnav-chips: Kennisbank · Stappenplannen · Forum · Makelaar. Bo (mascotte) piept over de rechterrand van de header.
- **Vandaag-strip** bovenaan (alleen zorg-rollen): "Vandaag: Tim komt om 10:00" → link naar rooster.
- **Makelaar-hero** (gradientkaart): "Kom je er even niet uit?", avatars van 3 online makelaars, knoppen **Chat nu** en **Videobel** (opent callscherm, callRole `mk`).
- **Kennisbank**: 6 onderwerpen (WMO & regelingen, Dementie, Respijtzorg, Geldzaken, Wonen & veiligheid, Zorg voor jezelf) → artikellijst → leesbaar artikel ("gecheckt door een hulpmakelaar"). Onder het artikel: chat-CTA.
- **Meest gelezen**: 3 directe artikel-links met onderwerp-tag.
- **Stappenplannen**: uitklapbare kaarten met genummerde stappen (WMO aanvragen · 5 stappen, Dementie eerste stappen · 4, Respijtzorg regelen · 3) + "Hulp bij dit stappenplan" → makelaar-chat.
- Forum en makelaar-chat: zoals bestaand.

## 4. Voorzieningen (marktplaats)
Zelfde blauwe header ("Hulp aan huis, in een paar tikken geregeld." + zoekbalk + Bo-peek). Grid van bijna-vierkante blokjes, 2 kolommen:
- **Buddy** — uitgelichte gradient-tegel, GRATIS/vrijwillig. Flow: uitleg → "Vraag via je hulpkring" (→ Kring) of "Zet een oproep op de buurtkaart" (→ kaart, directe-hulp compose).
- Betaald: Kapper aan huis (€29, Samira), Boodschappen (€7, Buurtsuper Daan), Maaltijden (€9, Keuken van Truus), Schoonmaak (€22/u, Helder Thuis), Tuinman (€35/u, Groenwerk Ali), Massage & fysio (€45, Fysio de Pijp), Vervoer (€12, Rijd mee met Rob), Hond uitlaten (€10, Waf & Wandel), Klusjesman (€30/u, Klussen met Kees).
Alle aanbieders zijn **gelieerd aan Thuisverzorgd** (gescreend, vaste gezichten). Betalen gebeurt altijd in de app.

### Dienst-detail (redesign, zie prototype)
Geen blokjes/pillen maar een zachte, persoonlijke pagina:
- Lichtblauw hero-vlak (#E9F1FA, ronde onderhoeken 28px): grote ronde aanbieder-avatar met witte rand, dienstnaam, "met Samira · 1,2 km", sterren + rating + aantal beoordelingen, handgeschreven notitie (Caveat) over de aanbieder.
- Sectie "Wat kun je verwachten": korte omschrijving + regel "± 45 min · bij jou thuis · gelieerd aan Thuisverzorgd".
- "Wanneer komt Samira?": tijdsloten als radio-lijst met hairlines (eerste slot label "snelst"), géén chips.
- Zwevende prijskaart onderaan: prijs groot, "Betaal na het bezoek · gratis annuleren tot 24 u", knop **"Boek di 10:00"** (label volgt gekozen slot).

### Boeken & betalen
Detail → Afrekenen (overzicht dienst/moment/aanbieder/totaal; Apple Pay + iDEAL; bedrag pas afgeschreven ná bezoek; gratis annuleren tot 24 u) → Bevestiging met Bo + groen vinkje: afspraak komt in het rooster, aanbieder krijgt bericht. Geboekte diensten verschijnen in het rooster naast kringtaken.

## 5. Mascotte Bo
Bestanden: `mascot/bo.svg` (heel, zwaaiend) en `mascot/bo-peek.svg` (kop + handjes over een rand).
- **Wie**: Bo, een vriendelijk rond wezentje (à la bol.com-mascotte) met crème buik, blosjes, groot ogenpaar en een blaadje-spruitje op het hoofd (groei/zorg).
- **Look**: 3D-gevoel door radiale gradients, glans-highlight linksboven en zachte slagschaduw. Kleuren zijn bewust "echter"/warmer dan de UI-palette: groen #C8EC90→#8CC64B→#619A2E, buik #FFF9EC→#F1DDBD, blosjes #F5A78F, ogen #223349. UI-kleuren blijven de brandkleuren; alleen Bo gebruikt dit warmere palet.
- **Plekken in het prototype** (uitbreidbaar): welkomstscherm (groot, zachtjes deinend), rondleiding-wolkje (Bo zit bovenop de tooltip), header van Steun én Voorzieningen (peek), boekingsbevestiging (Bo + vinkje-badge), lege hulpkring-staat, Buddy-pagina (hero).
- **Meer ideeën voor de build**: pull-to-refresh-animatie, lege staten (geen berichten/taken), push-notificatie-icoon, laadscherm, foutmeldingen ("Bo vindt de verbinding niet"), onboarding-slides, sticker in kring-chat na afgeronde taak.
- **Regels**: Bo wijst en moedigt aan, maar staat nooit op betaal-/juridische schermen als afleiding; max. 1 Bo per scherm; nooit uitgerekt; altijd de SVG-bestanden gebruiken.

## 6. Verwijderd
- Abonnementscherm, "Upgraden"-kaart in Profiel, panel-chip Abonnement, "Gratis tot 2 vrijwilligers"-limiet (uitnodigen is onbeperkt), `startSubscribed`-prop, IAP.

## 7. Implementatienotities (Expo + Supabase)
- Tabellen: `services` (naam, prijs, eenheid, aanbieder, rating, omschrijving, duur), `bookings` (user, service, slot, status: geboekt/afgerond/geannuleerd, betaalstatus), `providers` (gelieerd, verificatie), `articles`/`guides` (kennisbank + stappenplannen, met onderwerp-taxonomie), bestaande kring/rooster-tabellen blijven.
- Betalingen: Stripe (iDEAL + Apple Pay), charge pas na afronding bezoek (capture-later), gratis annuleren tot 24 u.
- Boekingen voeden het bestaande rooster; notificatie naar aanbieder en kring.
- Videobellen makelaar: bestaande call-infra hergebruiken (callRole `mk`).
- Tabbalk per rol renderen; Steun als initial route voor zorg-rollen.
- Bo-SVG's als assets bundelen; peek-variant absoluut gepositioneerd t.o.v. headers.
