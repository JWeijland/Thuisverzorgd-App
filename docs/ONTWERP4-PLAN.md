# Ontwerp 4.0 — megaplan herstructurering

> Bron: klikbaar prototype (artifact "Thuisverzorgd · ontwerp 4.0", sessie 06-08-2026) plus Jelles principe-tekst.
> Status bijhouden in dit bestand; korte verwijzing staat in `docs/PLAN.md` (Fase 12).

## De vier ontwerpprincipes

1. **Drie lagen, vaste volgorde.** 1 Steun (wegwijzer, stappenplannen, makelaar, forum) · 2 Kring & Buurt (buddy's, gratis) · 3 Voorzien (betaalde diensten). De tabvolgorde en alle keuzeschermen volgen deze volgorde.
2. **Rolkleuren uit het logo.** Blauw vraagt (hulpvrager, #2A6CB0) · groen geeft (buddy, #8DC93F) · navy draagt (beheerder, #1A4878). Bo kleurt per rol mee (spruitje blijft groen), elke persoonsnaam krijgt een rolchip in die kleur. Makelaar: paars (#6B4E93), zelfde tint als het wegwijzer-paars.
3. **De week is de rode draad.** Alles wat je in de app doet eindigt als afspraak in de week van de zorgzoekende. Eén Weekstrip-component met vaste stipkleuren in alle drie de apps: groen = buddy komt, kringblauw = geboekte dienst, oranje = nog leeg. "Weten → Regelen (gratis of betaald) → Er is iemand."
4. **Eén functie per pagina.** Hubs navigeren alleen; elke flow (plannen, afronden, boeken, vragen) is een eigen pagina met een terugweg. Geen subnavs die meerdere functies in één scherm proppen.

## Navigatiemodel

De zes fysieke tabroutes blijven bestaan; per rol wisselen zichtbaarheid, volgorde, label en icoon. Startroute per rol via `getStartRoute`.

| Rol | Tabs (volgorde = lagen) | Start |
|---|---|---|
| beheerder | steun **Steun** · rooster **Kring** · buurt **Buurt** · voorzien **Voorzien** · profiel **Profiel** (kring-tab verborgen) | `/steun` |
| vrijwilliger | rooster **Taken** · buurt **Buurt** · steun **Leren** · profiel **Profiel** | `/rooster` |
| hulpvrager | rooster **Vandaag** · voorzien **Hulp** · steun **Steun** · kring **Mijn kring** (buurt en profiel verborgen; instellingen via Mijn kring → profiel) | `/rooster` |

### Paginakaart per rol (F = functie van de pagina)

**Beheerder**
- `/steun` — hub: begroeting + weekkaart ("nog leeg op…" → vul-de-week) + 4 tegels (F: kiezen)
- `/wegwijzer-lijst` (nieuw) — WegwijzerLijst als eigen pagina (F: zoeken/lezen); `/wegwijzer/[id]` bestaat; artikel eindigt met "Zet in de week"
- `/hulpmakelaar` (nieuw) — BrokerChat als pagina (F: chatten; `/makelaar` blijft de makelaar-console)
- `/forum` (nieuw) — forumlijst + typebalk, gelicht uit het oude steun-scherm (F: forum)
- `/rooster` (tab "Kring") — de week: weekstrip, vandaag, taken; knoppen Leden en Berichten in de kop (F: de week zien)
- `/taak-plannen` (nieuw) — TaskPlanner als pagina (F: één taak plannen); `/weekplanning` blijft (F: concept-week)
- `/vul-de-week` (nieuw) — één open gat, drie routes: kring (gratis) / buurtoproep (gratis) / dienst (betaald) (F: kiezen hoe je het gat vult)
- `/leden` (nieuw) — kringleden + wie-doet-wat + uitnodigen-knop, uit KringScreen (F: leden)
- `/kringchat` bestaat (F: berichten)
- `/buurt` — alleen de kaart (F: kijken); `/directe-hulp` (nieuw) — RequesterFlow compose + status (F: oproep plaatsen)
- `/voorzien` — dienstengrid + "buddy's blijven gratis"-kaart (F: dienst kiezen); `/dienst/*` bestaat
- `/profiel` — profiel + instellingen; kringblok wordt één rij-link naar `/leden`

**Vrijwilliger**
- `/rooster` (tab "Taken") — weekstrip ("jouw stipje") + taak vandaag + open taken (F: taken)
- `/taak-afronden` (nieuw) — notitie achterlaten (F: afronden); uit RoosterVrijwilliger gelicht
- `/jouw-kring` (nieuw) — kringmotief + wie-is-wie met rolchips + kringchat-knop (F: de kring snappen)
- `/buurt` — kaart + open oproepen (bestaand VolunteerFlow, compose blijft op de kaartpagina omdat hij al één functie heeft)
- `/steun` (tab "Leren") — OpleidingenLijst + forumlink (F: leren)
- `/profiel` — buddy-pool, beschikbaarheid, instellingen

**Hulpvrager** (alles in ouderen-maat)
- `/rooster` (tab "Vandaag") — wie komt er, weekstrip met legenda, daarna-lijst incl. geboekte diensten, "Vraag om hulp"-knop (F: zien wie er komt)
- `/voorzien` (tab "Hulp") — keuzescherm: buddy (gratis) of hulp aan huis (betaald) (F: kiezen)
- `/buddy-vragen` (nieuw) — waarvoor-chips + versturen naar de kring (F: buddy vragen)
- dienstenlijst + boeken — bestaande voorzien-flow in grote variant (F: boeken)
- `/steun` — keuzescherm: praat met de makelaar / rustig lezen → `/hulpmakelaar` en `/wegwijzer-lijst` in grote variant
- `/kring` (tab "Mijn kring") — kringmotief + per persoon een uitlegkaart met rolchip + instellingen-rij (F: weten wie wie is)

## Datamodel

- **Migratie `hulpvrager_taak`:** hulpvrager mag een open taak (status `open`, zonder `claimed_by`) aanmaken in de eigen kring, zodat "Vraag een buddy" een echte roosterafspraak wordt. Eerst bestaande INSERT-policies op `tasks` nalezen; notificatie naar de beheerder via bestaand notificatiekanaal.
- Verder geen schemawijzigingen: weekstrip leest bestaande `tasks` + `bookings`.

## Componenten (nieuw of aangepast)

- `Bo.tsx`: prop `rol` → lijfgradient per rol; `BoPeek` idem; GradientHeader geeft de rol door. Spruitje blijft altijd groen.
- `RolChip.tsx` (nieuw): stip + label; tinten als `rolTints` in `theme.ts` (beheerder navy op #E4EBF4, buddy donkergroen op successBg, hulpvrager kringblauw op tintBlue, makelaar paars op #EFE6F7).
- `Weekstrip.tsx` (nieuw in `src/ui`): dagen + stipjes + vandaag-ring + optionele legenda; puur presentational, dot-logica als geteste pure functie (`weekDots(tasks, bookings)`).
- `KringMotief` bestaat en wordt hergebruikt op kringuitleg-, leden- en mijn-kring-pagina's.

## Onboarding en rondleiding

- Nieuw scherm `/verhaal` na welkom: "Eén doel: langer thuis wonen" met de drie stappen en een voorbeeldweek.
- `/rolkeuze`: drie kaarten (beheerder, buddy, hulpvrager) met mini-Bo in rolkleur; koppelcode-kaart blijft.
- Nieuw scherm `/kringuitleg` (per rol, na rolkeuze of koppelcode): kringmotief + "dit ben jij" + één zin per rol + rode-draadzin.
- Rondleiding: beheerder 5 wolkjes (steun → kring → buurt → voorzien → profiel), vrijwilliger 4 (taken → buurt → leren → profiel), hulpvrager 4 (vandaag → hulp → steun → mijn kring); teksten herschreven op de nieuwe labels.

## Copy-regels

Je-vorm overal (ook hulpvrager, brandbook 1.4), B1, geen em-dashes, nooit "mantelzorger", groen maximaal één CTA per scherm en altijd met nachtnavy tekst, alle copy via `i18n/nl.json`.

## Uitvoeringsfases

| Fase | Inhoud | Klaar als |
|---|---|---|
| C1 | rolTints in theme, Bo-rolvarianten, RolChip, Weekstrip + weekDots, tests | `npm test` groen, /dev/ui toont varianten |
| C2 | visibleTabs+volgorde+labels+iconen per rol, startroute, rondleiding-stappen | tabs kloppen per rol, tests bijgewerkt |
| C3 | beheerder: steun-hub, /wegwijzer-lijst, /hulpmakelaar, /forum, rooster-kop (Kring), /taak-plannen, /leden, /vul-de-week, /directe-hulp, buurt slank, voorzien-infokaart, profiel slank | alle pagina's één functie, flows klikbaar |
| C4 | vrijwilliger: taken-kop + weekstrip, /taak-afronden, /jouw-kring, Leren-invulling | idem |
| C5 | hulpvrager: vandaag (week+diensten), hulp-keuze, /buddy-vragen (+ migratie), steun-keuze, mijn kring | buddy-vraag komt als open taak in het rooster |
| C6 | /verhaal, rolkeuze-3-kaarten, /kringuitleg, rondleidingteksten | onboarding loopt rond voor drie rollen |
| C7 | i18n-restjes, tests, lint, typecheck, PLAN.md bijwerken | CI groen |

Commits klein en Nederlands, per subtaak; nooit `-a` (meerdere sessies in deze repo).
