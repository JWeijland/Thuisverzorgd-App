# Huisstijl Thuisverzorgd

De single source of truth voor lettertypes, kleuren, hoeken, schaduwen en spacing.
Alles in de app loopt via de tokens hieronder. Gebruik nooit losse kleuren of fonts
in de views: dan blijft de white-label thema-engine werken en oogt de app consistent.

> Let op: de app heeft één vaste huisstijl (Thuisverzorgd), ook voor gebruikers die
> via een organisatie zijn binnengekomen. De organisatie-herkomst wordt alleen als
> naam op het profiel getoond (`AppState.organizationName` + `BCOrganizationTag`).
> Codeer nog steeds altijd tegen de token, nooit tegen een letterlijke waarde.

---

## 1. Lettertypes (2 fonts + cursief)

Twee families, elk met een duidelijke rol. Definitie: `DesignSystem/BCTypography.swift`.

| Rol | Font (Thuisverzorgd) | Gebruik |
| --- | --- | --- |
| Koppen / titels | **Montserrat** | Titels, knoppen, labels, cijfers in stats |
| Tekst / body | **Open Sans** | Lopende tekst, omschrijvingen, invoervelden |
| Cursief | Montserrat-Italic / OpenSans-Italic | Citaten, persoonlijke noten, subtiele nadruk |

Ontbreekt een TTF in de bundle, dan valt alles netjes terug op het afgeronde
systeemfont (koppen/tekst) of op een gesynthetiseerde schuine letter (cursief).
Er is dus nooit een kale San Francisco of een missende cursief.

### Type-schaal (gebruik altijd deze tokens, nooit `.font(.system(...))` op tekst)

```
BCTypography.largeTitle        34pt  Montserrat Bold
BCTypography.title             28pt  Montserrat Bold
BCTypography.titleEmphasized   22pt  Montserrat Heavy
BCTypography.title2            22pt  Montserrat SemiBold
BCTypography.title3            20pt  Montserrat SemiBold
BCTypography.headline          18pt  Montserrat SemiBold
BCTypography.body              17pt  Open Sans Regular
BCTypography.bodyEmphasized    17pt  Open Sans SemiBold
BCTypography.callout           16pt  Open Sans Regular
BCTypography.subheadline       15pt  Open Sans Regular
BCTypography.caption           13pt  Open Sans Regular
BCTypography.captionEmphasized 13pt  Open Sans SemiBold

Cursief:
BCTypography.bodyItalic        17pt  Open Sans Italic
BCTypography.calloutItalic     16pt  Open Sans Italic
BCTypography.subheadlineItalic 15pt  Open Sans Italic
BCTypography.captionItalic     13pt  Open Sans Italic
BCTypography.headingItalic     20pt  Montserrat Italic
```

Voor de ouderen-modus (grotere maten): `BCTypography.elderly*` en `BCElderlyType`.

### Cursief zelf gebruiken

```swift
Text("Zij is echt een steun in mijn week.")
    .font(BCTypography.bodyItalic)
    .foregroundStyle(BCColors.textSecondary)
```

### Echte italic-TTF's toevoegen (optioneel, verbetert de cursief)

Nu wordt cursief gesynthetiseerd met `.italic()`. Wil je de echte snit:

1. Zet de bestanden in `Fonts/`: `Montserrat-Italic.ttf` en `OpenSans-Italic.ttf`.
2. Voeg ze toe aan `Info.plist` onder `UIAppFonts`.
3. Voeg ze toe aan het Xcode-target (Build Phases → Copy Bundle Resources).
4. Controleer de PostScript-namen (`Montserrat-Italic`, `OpenSans-Italic`); die staan
   al als kandidaat in `BCThemes.thuisverzorgd.headingItalic` / `bodyItalic`.

Zodra de TTF's in de bundle zitten, pakken de tokens ze automatisch op. Geen code-wijziging nodig.

---

## 2. Kleuren (semantische tokens)

Definitie: `DesignSystem/BCColors.swift`. Hex-waarden hieronder gelden voor het
standaardthema **Thuisverzorgd**. Andere organisaties overschrijven ze; gebruik dus
altijd de token, nooit de hex.

### Merk

| Token | Hex | Gebruik |
| --- | --- | --- |
| `BCColors.primary` | `#1A4878` | Hoofdkleur (navy), headers, primaire knoppen |
| `BCColors.primaryDark` | `#112F50` | Donkere merk-kleur, hero/gradient |
| `BCColors.primaryMid` | `#2A6CB0` | Tussentint, iconen |
| `BCColors.primaryMuted` | primary @ 8% | Zachte merk-achtergrond |
| `BCColors.accent` | `#8DC93F` | Accent / CTA-vlak (fris groen) |
| `BCColors.accentDark` | `#73B02B` | Donker accent |
| `BCColors.onAccent` | `#112F50` | Tekst/icoon bovenop een accent-vlak |

### Oppervlakken

| Token | Hex | Gebruik |
| --- | --- | --- |
| `BCColors.background` | `#F5F8FC` | Schermachtergrond |
| `BCColors.surface` | `#FFFFFF` | Kaarten, panelen |
| `BCColors.surfaceMuted` | `#EEF2F8` | Ingezonken vlakken |
| `BCColors.border` | `#E3E8F1` | Hairlines, randen |

### Tekst

| Token | Hex | Gebruik |
| --- | --- | --- |
| `BCColors.textPrimary` | `#112640` | Primaire tekst |
| `BCColors.textSecondary` | `#5A687A` | Secundaire tekst |
| `BCColors.textTertiary` | `#8F9AAA` | Labels, placeholders |

### Semantisch

| Token | Hex | Gebruik |
| --- | --- | --- |
| `BCColors.success` | `#73B02B` | Goedgekeurd, beschikbaar |
| `BCColors.warning` | `#E19E11` | In behandeling, let op |
| `BCColors.danger` | `#D9413A` | Fout, afgewezen, ophangen |

### Buddy-level pins

`BCColors.level0…level4` — kleuren voor de kaart-pins per buddy-niveau.

---

## 3. Hoeken (radii)

Definitie: `DesignSystem/BCColors.swift` (`BCRadius`, per thema).

| Token | Waarde (Thuisverzorgd) | Gebruik |
| --- | --- | --- |
| `BCRadius.sm` | 10 | Kleine chips, badges |
| `BCRadius.md` | 16 | Knoppen, invoervelden |
| `BCRadius.lg` | 22 | Kaarten |
| `BCRadius.xl` | 30 | Headers, grote panelen |
| `BCRadius.pill` | 999 | Pillen, capsules |

---

## 4. Schaduwen

Definitie: `DesignSystem/BCColors.swift` (`BCShadow`). Gebruik `.bcSoftShadow(_:)`.

| Token | Gebruik |
| --- | --- |
| `.bcSoftShadow(.subtle)` | Lichte hint |
| `.bcSoftShadow(.card)` | Standaard kaart |
| `.bcSoftShadow(.raised)` | Hero / belangrijke kaart |

Zachte, rustige schaduw in de merk-donkerkleur. Nooit een harde `Color.black`-schaduw.

---

## 5. Spacing

Definitie: `DesignSystem/BCColors.swift` (`BCSpacing`).

`xxs 2 · xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48`

Gebruik deze stappen voor padding en spacing; geen losse magische getallen voor layout.

---

## 6. Merkteken & logotaal (Brand Guidelines v2.1, h2 + 5.2)

Definitie: `DesignSystem/BCComponents.swift`.

| Component | Gebruik |
| --- | --- |
| `BCLogoMark(height:variant:)` | De gestapelde T, getekend uit tokens. Varianten: `.kleur` (licht), `.diapositief` (op navy), `.mono(Color)` (stempel/watermerk) |
| `BCMicroBalk(barHeight:)` | Alleen de tweekleurige balk; het micro-merkje onder 24 pt (badge, voetregel, kaartpin) |
| `BCMerkstreepje(height:)` | Blauw+groen streepje als bullet of onderstreping van stats |
| `BCLoadingDots(label:onDark:)` | Laadstand: drie stuiterende stippen (blauw, groen, navy) |
| `.bcLogoWatermark(alignment:height:)` | T-watermerk op 7% in een hoek, nooit midden onder tekst |
| `BCPillenPaar()` | De losse pillen voor lege/foutschermen (gebruikt door `BCEmptyState`) |
| `BCRatingStars(value:)` | Waardering als kringstippen (geen sterren) |

Spelregels: maximaal één logo-expressie per scherm; het statische logo in headers
blijft altijd de vaste vorm.

## 7. Typografie met karakter (Brand Guidelines v2.1, 3.3)

Vier vaste stijlmiddelen, nooit een derde lettertype. **Spelregel: één
stijlmiddel per uiting**; lopende tekst blijft rustig Open Sans in textPrimary.

| Component | Stijlmiddel |
| --- | --- |
| `BCHeroKop(text:accentWord:font:)` | Kop met Hulpgroene punt; optioneel één woord Donkergroen |
| `BCPillWord(word:style:font:)` | Eén woord in een volle pil (navy / kringblauw / hulpgroen) |
| `BCProudStat(value:label:valueSize:)` | Trotse cijfers: groot Montserrat ExtraBold + merkstreepje |
| `BCPillQuote(quote:attribution:onDark:)` | Citaat in Open Sans Italic met pil-aanhalingstekens, altijd met naam |

## 8. Do's en don'ts

**Do**
- Tekst altijd met een `BCTypography`-token.
- Kleuren altijd met een `BCColors`-token.
- Hoeken/schaduw/spacing via `BCRadius` / `.bcSoftShadow` / `BCSpacing`.
- Herbruik de BC-componenten (`BCButtons`, `BCCards`, `BCBadges`, `BCStatusPill`, ...).

**Don't**
- Geen `Text(...).font(.system(...))` of `Font.custom(...)` in de views.
- Geen hardcoded `Color(hex:)` / `Color(red:green:blue:)` in de views.
- De thema-engine niet omzeilen met vaste waarden.
- **Geen em-dash (—) in gebruikersgerichte copy.** Een em-dash komt tegenwoordig over
  als "door een bot gebouwd". Gebruik een komma, dubbele punt of haakjes.

**Uitzondering:** `.font(.system(size:weight:))` op een **SF Symbol** (`Image(systemName:)`)
is toegestaan: dat is glyph-grootte, geen tekstlettertype. Voor leesbare **tekst** geldt
de regel wel.
