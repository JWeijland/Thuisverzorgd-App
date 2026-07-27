import SwiftUI

// MARK: - Huisstijl-tokens
//
// De app draait altijd in de Thuisverzorgd-huisstijl, ongeacht via welke
// vrijwilligersorganisatie iemand is binnengekomen. De organisatie-herkomst
// wordt alleen als naam op het profiel getoond (zie AppState.organizationName);
// kleuren, hoeken, fonts en iconen veranderen er bewust niet door.
//
// Werking: één basis (BCTheme) met design-tokens. `BCColors`, `BCRadius`,
// `BCShadow` en de fonts (BCTypography) lezen allemaal uit dit vaste thema, dus
// alle call-sites (BCColors.primary, …) werken via dezelfde tokennamen.

struct BCTheme: Equatable {
    let key: String
    let displayName: String
    /// Asset-prefix voor de iconenset (bv. "tv", "zuid", "present").
    let iconPrefix: String

    // Merk-schaal
    let primary: Color       // hoofdkleur (was navy700)
    let primaryDark: Color   // donkere merk-kleur, hero/gradient (was navy900)
    let primaryMid: Color    // tussentint (was navy500)
    let accent: Color        // accent / CTA-vlak (was green500)
    let accentDark: Color    // donker accent (was green600)
    /// Tekst/icoon-kleur bovenop een accent-vlak (donker op groen, wit op rood/oranje).
    let onAccent: Color

    // Oppervlakken
    let background: Color
    let surface: Color
    let surfaceMuted: Color

    // Tekst
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let border: Color

    // Semantisch
    let success: Color
    let warning: Color
    let danger: Color

    // Buddy-level pins
    let level0: Color
    let level1: Color
    let level2: Color
    let level3: Color
    let level4: Color

    // Vorm (hoeken)
    let radiusSm: CGFloat
    let radiusMd: CGFloat
    let radiusLg: CGFloat
    let radiusXl: CGFloat

    // Fonts — kandidaatnamen per gewicht; valt terug op afgerond systeem-font
    // als de TTF niet in de bundle zit (zie BCFont).
    let headingHeavy: [String]
    let headingBold: [String]
    let headingSemibold: [String]
    let headingRegular: [String]
    let bodyBold: [String]
    let bodySemibold: [String]
    let bodyRegular: [String]
    // Cursief. Zit de TTF niet in de bundle, dan synthetiseert BCFont een nette
    // schuine variant met `.italic()` (zie BCTypography). Zo blijft cursief altijd
    // beschikbaar via een token, ook zonder eigen italic-fontbestand.
    let headingItalic: [String]
    let bodyItalic: [String]

    static func == (lhs: BCTheme, rhs: BCTheme) -> Bool { lhs.key == rhs.key }
}

// MARK: - Het vaste thema

enum BCThemes {

    // Thuisverzorgd — de enige huisstijl (navy + fris groen, Montserrat/Open Sans).
    // Iedereen krijgt deze look, ook leden van een aangesloten organisatie.
    static let thuisverzorgd = BCTheme(
        key: "thuisverzorgd",
        displayName: "Thuisverzorgd",
        iconPrefix: "tv",
        primary:      Color(hex: 0x1A4878),
        primaryDark:  Color(hex: 0x112F50),
        primaryMid:   Color(hex: 0x2A6CB0),
        accent:       Color(hex: 0x8DC93F),
        accentDark:   Color(hex: 0x73B02B),
        onAccent:     Color(hex: 0x112F50),
        background:   Color(hex: 0xF5F8FC),
        surface:      .white,
        surfaceMuted: Color(hex: 0xEEF2F8),
        textPrimary:   Color(hex: 0x112640),
        textSecondary: Color(hex: 0x5A687A),
        textTertiary:  Color(hex: 0x8F9AAA),
        border:        Color(hex: 0xE3E8F1),
        success: Color(hex: 0x73B02B),
        warning: Color(hex: 0xE19E11),
        danger:  Color(hex: 0xD9413A),
        level0: Color(hex: 0x8D9CAB),
        level1: Color(hex: 0x2A6CB0),
        level2: Color(hex: 0x70469A),
        level3: Color(hex: 0xD9413A),
        level4: Color(hex: 0x112F50),
        radiusSm: 10, radiusMd: 16, radiusLg: 22, radiusXl: 30,
        headingHeavy:    ["Montserrat-ExtraBold", "Montserrat-Bold"],
        headingBold:     ["Montserrat-Bold"],
        headingSemibold: ["Montserrat-SemiBold"],
        headingRegular:  ["Montserrat-Medium", "Montserrat-Regular"],
        bodyBold:        ["OpenSans-Bold", "OpenSans-SemiBold"],
        bodySemibold:    ["OpenSans-SemiBold"],
        bodyRegular:     ["OpenSans-Regular"],
        headingItalic:   ["Montserrat-Italic", "Montserrat-MediumItalic"],
        bodyItalic:      ["OpenSans-Italic"]
    )

    static let `default`: BCTheme = thuisverzorgd
}

// MARK: - Actief thema (vast)
//
// Het thema is een constante: de app kleurt nooit meer om per organisatie.
// De tokens (BCColors, BCRadius, BCTypography, AppIcon) blijven hier uit lezen.

enum BCThemeManager {
    static let current: BCTheme = BCThemes.default
}

// MARK: - BCColors (leest uit het actieve thema; API ongewijzigd)

enum BCColors {
    private static var t: BCTheme { BCThemeManager.current }

    // MARK: - Brand roles
    static var primary: Color      { t.primary }
    static var primaryDark: Color  { t.primaryDark }
    static var primaryMid: Color   { t.primaryMid }
    static var primaryMuted: Color { t.primary.opacity(0.08) }

    static var accent: Color     { t.accent }
    static var accentDark: Color { t.accentDark }
    /// Leesbare voorgrondkleur bovenop een accent-vlak (donker op groen, wit op rood/oranje).
    static var onAccent: Color   { t.onAccent }

    // MARK: - Navy/green-aliassen (historische namen → merk-schaal van het thema)
    static var navy900: Color { t.primaryDark }
    static var navy700: Color { t.primary }
    static var navy500: Color { t.primaryMid }
    static var green500: Color { t.accent }
    static var green600: Color { t.accentDark }
    static var green700: Color { t.accentDark }

    // MARK: - Surfaces
    static var background: Color   { t.background }
    static var surface: Color      { t.surface }
    static var surfaceMuted: Color { t.surfaceMuted }

    // MARK: - Text
    static var textPrimary: Color   { t.textPrimary }
    static var textSecondary: Color { t.textSecondary }
    static var textTertiary: Color  { t.textTertiary }
    static var border: Color        { t.border }

    // MARK: - Semantic
    static var success: Color { t.success }
    static var warning: Color { t.warning }
    static var danger: Color  { t.danger }

    // MARK: - Buddy level pins
    static var level0: Color { t.level0 }
    static var level1: Color { t.level1 }
    static var level2: Color { t.level2 }
    static var level3: Color { t.level3 }
    static var level4: Color { t.level4 }
}

enum BCSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum BCRadius {
    static var sm: CGFloat { BCThemeManager.current.radiusSm }
    static var md: CGFloat { BCThemeManager.current.radiusMd }
    static var lg: CGFloat { BCThemeManager.current.radiusLg }
    static var xl: CGFloat { BCThemeManager.current.radiusXl }
    static let pill: CGFloat = 999
}

// MARK: - Soft elevation (zachte schaduw i.p.v. harde randen)

extension View {
    /// Zachte, rustige kaartschaduw die past bij de website-vibe.
    func bcSoftShadow(_ strength: BCShadow = .card) -> some View {
        shadow(color: strength.color, radius: strength.radius, x: 0, y: strength.y)
    }
}

enum BCShadow {
    case card        // standaard kaart
    case raised      // hero / belangrijke kaart
    case subtle      // lichte hint

    var color: Color { BCColors.primaryDark.opacity(opacity) }
    var opacity: Double {
        switch self {
        case .card: return 0.06
        case .raised: return 0.10
        case .subtle: return 0.04
        }
    }
    var radius: CGFloat {
        switch self {
        case .card: return 12
        case .raised: return 20
        case .subtle: return 6
        }
    }
    var y: CGFloat {
        switch self {
        case .card: return 4
        case .raised: return 8
        case .subtle: return 2
        }
    }
}

// MARK: - Color hex-helper

extension Color {
    /// Maakt een Color uit een 0xRRGGBB-waarde.
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
}
