# Huisstijl Thuisverzorgd v4.0

De single source of truth voor kleuren, lettertypes, de getekende laag, de paginabalk,
hoeken, schaduwen en spacing. Alles in de app loopt via de tokens hieronder.
Gebruik nooit losse kleuren of fonts in de views: dan blijft de thema-engine werken
en oogt de app consistent.

> **Nieuw in v4.0 (augustus 2026)**
> 1. **Thuisrood `#E55A40` is de primaire merkkleur.** Navy is geen merkkleur meer.
> 2. **Linnenwit `#FCF8F6`** (bijna wit, warme ondertoon) is de schermachtergrond.
> 3. **Groen is geen CTA-kleur meer.** Groen hoort bij Bo, bevestiging en beschikbaarheid.
> 4. **De getekende laag** (kringelstreep en de pennenset) is vastgelegd, met eigen assets.
> 5. **De paginabalk** boven elk scherm is een component met vier vaste varianten.
> 6. **Fout is Alarmrood `#9B1B30`**, niet het merkrood. Altijd met icoon en woord erbij.

Waar staat wat:

| Plek | Rol |
| --- | --- |
| `BCColors.swift` / `theme.ts` | De echte waarden. Wijzigt er iets, dan hier eerst. |
| `HUISSTIJL.md` (dit bestand) | Wat elk token betekent en wanneer je het gebruikt. |
| Brand Guidelines v4.0 (pdf) | Het verhaal, de regels en de voorbeelden eromheen. |

---

## 1. Kleur

### 1.1 De rode schaal

| Tint | Hex | Waar |
| --- | --- | --- |
| 50 | `#FEF4F1` | zachte merk-achtergrond, geselecteerde rij, tip-vlak |
| 100 | `#FCE7E1` | chips, badges, avatar-vulling, eigen chatbubbel |
| 200 | `#F8CEC3` | randen van rode vlakken, voortgangsspoor |
| 300 | `#F2A797` | illustratie, kringen, tekst op Nachtbruin |
| 400 | `#EC806A` | bovenkant van het verloop in de paginabalk |
| **500** | **`#E55A40`** | **Thuisrood.** Merk, balk, kringelstreep, actieve staat |
| 600 | `#CE3B24` | Gloedrood: knoppen met witte tekst (4,9 : 1), links |
| 700 | `#9F2F21` | Diepbaksteen: rode tekst op licht, ingedrukte knop |
| 800 | `#72251D` | donkere merkvlakken, hoofdstukpagina's |
| 900 | `#4A1B17` | diepste tint, alleen als vlak |

### 1.2 Merk

| Token | Hex | Gebruik |
| --- | --- | --- |
| `primary` | `#E55A40` | Hoofdkleur: paginabalk, actieve staat, merk |
| `primaryStrong` / `primaryMid` | `#CE3B24` | Knop met witte tekst, links, iconen |
| `primaryDark` | `#9F2F21` | Rode tekst op licht, ingedrukt, donker merkvlak |
| `primaryMuted` | primary @ 8% | Zachte merk-achtergrond |
| `nachtbruin` | `#3A1D16` | Donkere vlakken, covers, schaduwkleur |
| `accent` | `#8DC93F` | Hulpgroen: Bo, bevestiging, beschikbaar |
| `accentDark` | `#73B02B` | Donker accent |
| `onAccent` | `#3A1D16` | Tekst of icoon op groen of oker. **Nooit wit** |
| `blue` / `info` | `#2A6CB0` | Kringblauw: kring, kaart, uitleg |

### 1.3 Oppervlakken en tekst

| Token | Hex | Gebruik |
| --- | --- | --- |
| `background` / `bg` | `#FCF8F6` | Schermachtergrond (Linnenwit) |
| `surface` / `white` | `#FFFFFF` | Kaarten, panelen |
| `surfaceMuted` / `surfaceAlt` | `#F6EEEA` | Ingezonken vlakken, iconentegels |
| `border` / `line` | `#EDE2DD` | Hairlines, randen |
| `textPrimary` / `ink` | `#2B1A16` | Primaire tekst (15,8 : 1) |
| `textSecondary` / `inkSoft` | `#6E574F` | Secundaire tekst (6,3 : 1) |
| `textTertiary` / `inkFaint` | `#9C857C` | Labels, placeholders (3,3 : 1, geen lopende tekst) |

### 1.4 Semantisch

| Token | Hex | Gebruik |
| --- | --- | --- |
| `success` | `#73B02B` | Goedgekeurd, beschikbaar |
| `warning` | `#C98A0F` | In behandeling, let op |
| `danger` / `error` | `#9B1B30` | Fout, afgewezen |
| `info` | `#2A6CB0` | Kring, kaart, uitleg |

**Rood is merk, geen alarm.** Omdat de merkkleur rood is, mag een foutmelding nooit
Thuisrood zijn. Fout is Alarmrood, donkerder en koeler, en staat nooit alleen: altijd
met een icoon en een woord erbij.

### 1.5 Buddy-levels (kaartpins)

`level0` `#B3A49C` · `level1` `#2A6CB0` · `level2` `#73B02B` · `level3` `#C98A0F` · `level4` `#E55A40`

Alleen voor pins en level-badges op de kaart, nooit als algemene merkkleur.

### 1.6 Toegankelijkheid (nagerekend)

| Combinatie | Contrast | Oordeel |
| --- | --- | --- |
| Inkt `#2B1A16` op Linnen `#FCF8F6` | 15,8 : 1 | AAA |
| Wit op Nachtbruin `#3A1D16` | 15,4 : 1 | AAA |
| Wit op Diepbaksteen `#9F2F21` | 7,2 : 1 | AAA |
| Wit op Gloedrood `#CE3B24` | 4,9 : 1 | AA |
| Wit op Thuisrood `#E55A40` | 3,6 : 1 | **alleen grote tekst en UI-onderdelen** |
| Diepbaksteen op Linnen | 6,9 : 1 | AA |
| Nachtbruin op Hulpgroen | 7,7 : 1 | AA |
| Wit op Hulpgroen | 2,0 : 1 | **nooit doen** |

Vaste regels:

- Kleine witte tekst nooit op Thuisrood: gebruik Gloedrood (600) of donkerder.
- Op Hulpgroen en Okergeel altijd Nachtbruin (`onAccent`), nooit wit.
- Rode tekst op een licht vlak is Diepbaksteen (700), niet Thuisrood.
- Kleur is nooit de enige betekenisdrager: altijd ook een woord of icoon.

### 1.7 Verhouding in een gemiddeld scherm

Linnenwit 60% · Thuisrood 20% · Nachtbruin 10% · Hulpgroen 6% · Kringblauw 4%.

---

## 2. Lettertypes

Twee families, elk met een duidelijke rol. Definitie: `BCTypography.swift` / `theme.ts`.

| Rol | Font | Gebruik |
| --- | --- | --- |
| Koppen / titels | **Baloo 2** | Titels, knoppen, labels, cijfers in stats |
| Tekst / body | **Comic Neue** | Lopende tekst, omschrijvingen, invoervelden |
| Cursief | Comic Neue Italic | Citaten, persoonlijke noten, subtiele nadruk |

### Type-schaal

```
largeTitle        34 pt  Baloo 2 Bold
title             28 pt  Baloo 2 Bold
title2            22 pt  Baloo 2 SemiBold
title3            20 pt  Baloo 2 SemiBold
headline          18 pt  Baloo 2 SemiBold
body              17 pt  Comic Neue Regular
bodyEmphasized    17 pt  Comic Neue Bold
callout           16 pt  Comic Neue Regular
subheadline       15 pt  Comic Neue Regular
caption           13 pt  Comic Neue Regular
bodyItalic        17 pt  Comic Neue Italic
```

Voor de ouderen-modus schalen alle tokens een slag op (`elderly*`). Body nooit
kleiner dan 17 pt in de app, 9,5 pt in druk.

### Typografie met karakter

Vier stijlmiddelen, nooit een derde lettertype. **Een stijlmiddel per uiting.**

1. **Rode punt en accentwoord** — hero-koppen eindigen op een Thuisrode punt.
2. **Het pil-woord** — een woord in een volle pil (rood met wit, of groen met Nachtbruin).
3. **Trotse cijfers** — Baloo 2 ExtraBold met de handstreep eronder.
4. **Het pil-citaat** — Comic Neue Italic, altijd met naam erbij.

---

## 3. De getekende laag

Een handgetekende lijn per vlak, in Thuisrood op licht of wit op donker.
Assets: `DesignSystem/Getekend/*.svg`.

| Asset | Gebruik |
| --- | --- |
| `kringelstreep.svg` | Het hoofdgebaar: onder koppen, op covers, in de paginabalk |
| `kringel-kort.svg` | Een lus, onder een enkel woord |
| `kringel-lang.svg` | Vijf lussen, cover en scheiding |
| `kringel-onder.svg` | Plat profiel, als onderstreping van een kop |
| `kringel-onder-wit.svg` / `kringelstreep-wit.svg` | Wit, voor rode en donkere vlakken |
| `onderstreping.svg` | Twee snelle halen onder een cijfer of naam |
| `handcirkel.svg` | Omcirkelt een datum, woord of gezicht |
| `handpijl.svg` | Wijst naar de volgende stap, alleen in uitleg en onboarding |
| `vonkje.svg` | Klein feestje: voltooide taak, nieuw level, bedankje |
| `golfrand.svg` | De onderrand van de paginabalk, alleen daar |

Regels:

- **Een gebaar per vlak.** Twee kringels op een scherm halen elkaar onderuit.
- Lijndikte is ongeveer 4% van de breedte van de vorm.
- Altijd horizontaal, nooit gekanteld, nooit met verloop, schaduw of stippellijn.
- Nooit over tekst, gezichten of knoppen heen, en nooit als tikbaar gebied.
- Breedte tussen 40% en 80% van de kop, en nooit breder dan de kop.
- Op Hulpgroen komt de kringel niet: te weinig contrast.

Waar het mag:

| Drager | Wat mag |
| --- | --- |
| App-scherm | Een gebaar: in de paginabalk of onder de hoofdkop, niet allebei |
| Kaart in een lijst | Niets, kaarten blijven rustig |
| Leeg scherm | Kringel plus Bo |
| Onboarding | Handpijl of handcirkel, een per stap |
| Social post | Een kringel of een cirkel, nooit beide |
| Drukwerk A4 | Kringel onder de kop, golfrand onderaan |

---

## 4. Bo, de mascotte

Bo is het vriendelijke gezicht van de app: zij kijkt mee en zoekt mee, zij beslist niet.
Bo blijft groen, want groen is de kleur van bevestiging.

| Variant | Bestand | Gebruik |
| --- | --- | --- |
| Hele Bo | `mascot/bo.svg` | Leeg scherm, onboarding, bevestiging. Minimaal 30 mm |
| Bo die gluurt | `mascot/bo-peek.svg` | Tips, toasts, de buurt-scan |
| Silhouet wit | `mascot/bo-mono-wit.svg` | Watermerk in de paginabalk en op donkere vlakken |
| Silhouet rood | `mascot/bo-mono-rood.svg` | Stempel op drukwerk, sticker, favicon-achtergrond |

Watermerk-regels: 12% wit op rood (8% op Nachtbruin), hoogte 110 tot 140% van de
balkhoogte, rechts geplaatst en 6 mm buiten de rand, onder en rechts uitgesneden,
altijd rechtop. Het watermerk mag het contrast van de tekst nooit onder 4,5 : 1 duwen.

Bo verandert nooit van kleur, krijgt nooit een uniform of medisch instrument, en praat
nooit over een hulpvraag alsof zij een mens is. Een Bo per scherm.

---

## 5. De paginabalk

Elk scherm begint met dezelfde balk. Component: `BCPaginabalk(titel:ondertitel:variant:chips:)`.
Bouw nooit zelf een balk in een view.

| Onderdeel | Regel |
| --- | --- |
| Vlak | Verloop 152 graden: `#EE6E52` → `#E55A40` → `#D0492F`. Nooit rood naar groen |
| Golfrand | Vaste golf van 8 pt hoog, altijd dezelfde vorm en kleur als de onderkant van het verloop |
| Bo | Wit silhouet op 12%, rechts uitgesneden, nooit voor de titel |
| Titel | Baloo 2 Bold wit, 22 pt (groot) of 18 pt (compact), maximaal drie woorden |
| Ondertitel | Comic Neue 15 pt, wit op 85%, een regel zonder punt |
| Kringelstreep | Wit op 50%, plat profiel, linksonder, alleen bij balken hoger dan 100 pt |
| Acties | Rechtsboven, rond, wit op 22%, maximaal twee |
| Chips | Pillen op wit 20%, actieve chip wit met Diepbaksteen tekst |
| Ruimte | Titel start onder de statusbalk plus 8 pt, houdt 16 pt afstand tot de golfrand |

Varianten: `.groot` 180 pt (hoofdschermen met tabs) · `.compact` 120 pt (schermen zonder
tabs, geen kringel) · `.klein` 96 pt (detailschermen, terugknop plus titel, geen Bo) ·
`.donker` (alleen beheer- en organisatieomgeving, in Nachtbruin).

Bij scrollen krimpt de balk naar compact en blijft de golfrand staan.

---

## 6. Hoeken, schaduw en spacing

| Token | Waarde | Gebruik |
| --- | --- | --- |
| `radius.chip` | 6 | Chips, badges |
| `radius.field` | 8 | Invoervelden |
| `radius.card` | 10 | Kaarten, panelen, paginabalk |
| `radius.tile` | 16 | Iconentegels |
| `radius.pill` | 999 | Knoppen, chips, tabs, statuspillen |

Vakken die inhoud dragen zijn bijna vierkant, alles wat je indrukt of wat status toont
is rond. Nooit meer 22 of 30: te rond.

Schaduw altijd zacht en in Nachtbruin (`.bcSoftShadow(.subtle/.card/.raised)`), nooit
hard zwart. Spacing: `2 · 4 · 8 · 16 · 24 · 32 · 48`.

Tikdoelen: alles minimaal 44 x 44 pt, belangrijkste CTA's 72 pt hoog.

---

## 7. Do's en don'ts

**Do**

- Tekst altijd met een typografie-token, kleuren altijd met een kleur-token.
- Herbruik de componenten (`BCPaginabalk`, `BCButtons`, `BCCards`, `BCBadges`, ...).
- Een primaire knop, een getekend gebaar en een paginabalk per scherm.
- Zeg wat er gebeurt en wat de volgende stap is.

**Don't**

- Geen `Font.custom(...)` of `Color(hex:)` in de views.
- Geen kleine witte tekst op Thuisrood, geen witte tekst op groen.
- Geen tweede kringel in dezelfde balk of op hetzelfde scherm.
- Geen foto's of illustraties in de paginabalk.
- **Geen em-dash (—) in gebruikersgerichte copy.** Gebruik een komma, dubbele punt of haakjes.

**Uitzondering:** een systeemfont-grootte op een SF Symbol is toegestaan, dat is
glyph-grootte en geen tekstlettertype.

---

## 8. Migreren van v3 naar v4

1. Vervang `BCColors.swift` (SwiftUI) of het `colors`-blok in `theme.ts` (Expo).
2. Zoek op oude hexwaarden in de codebase: `1A4878`, `112F50`, `2A6CB0`, `F5F8FC`,
   `112640`, `5A687A`, `8F9AAA`, `E3E8F1`, `EEF2F8`, `D9413A`, `E19E11`. Elke treffer
   die niet in een tokenbestand staat, is een view die tegen een letterlijke waarde codeert.
3. Loop de CTA's na: groene knoppen worden rood (`primaryStrong`), groen blijft alleen
   voor bevestiging en beschikbaarheid.
4. Loop de foutmeldingen na: `#D9413A` wordt `#9B1B30` en krijgt een icoon.
5. `gradient.colors` is in v4 een drietal in plaats van een tweetal. Componenten die het
   type als `[string, string]` annoteren, moeten naar `string[]` of het nieuwe drietal.
6. De legacy-aliassen `navy900`, `navy700` en `navy500` blijven in v4 bestaan zodat oude
   views compileren, en verdwijnen in v5.
