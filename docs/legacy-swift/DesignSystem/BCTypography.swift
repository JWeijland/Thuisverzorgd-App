import SwiftUI
import UIKit

// MARK: - Font routing (Montserrat koppen + Open Sans tekst, met systeem-fallback)
//
// Zodra de fontbestanden in de bundle zitten (zie stuk 10) gebruiken alle
// tokens automatisch Montserrat/Open Sans. Is een font niet aanwezig, dan
// valt alles netjes terug op het afgeronde systeem-font — geen lelijke
// kale San Francisco en geen code-wijziging nodig.

enum BCFont {
    /// Naam van een geïnstalleerd custom font of nil als het niet bestaat.
    private static func installedName(_ candidates: [String]) -> String? {
        for name in candidates where UIFont(name: name, size: 12) != nil {
            return name
        }
        return nil
    }

    static func heading(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        let theme = BCThemeManager.current
        let names: [String]
        switch weight {
        case .heavy, .black:       names = theme.headingHeavy
        case .bold:                names = theme.headingBold
        case .semibold, .medium:   names = theme.headingSemibold
        default:                   names = theme.headingRegular
        }
        if let n = installedName(names) { return .custom(n, size: size) }
        return .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let theme = BCThemeManager.current
        let names: [String]
        switch weight {
        case .bold, .heavy, .black: names = theme.bodyBold
        case .semibold, .medium:    names = theme.bodySemibold
        default:                    names = theme.bodyRegular
        }
        if let n = installedName(names) { return .custom(n, size: size) }
        return .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: - Cursief (koppen + tekst)
    //
    // Zit een echte italic-TTF in de bundle (zie het thema), dan gebruiken we die.
    // Ontbreekt hij, dan zetten we `.italic()` op de gewone variant: SwiftUI maakt
    // dan een nette schuine (oblique) letter. Zo werkt cursief altijd zichtbaar,
    // ook zolang de italic-fontbestanden nog niet zijn toegevoegd.

    static func headingItalic(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        if let n = installedName(BCThemeManager.current.headingItalic) { return .custom(n, size: size) }
        return heading(size, weight).italic()
    }

    static func bodyItalic(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if let n = installedName(BCThemeManager.current.bodyItalic) { return .custom(n, size: size) }
        return body(size, weight).italic()
    }
}

enum BCTypography {
    // Computed (geen `let`) zodat de fonts met het actieve thema meebewegen —
    // een `static let` zou de eerst-gebruikte huisstijl voorgoed vastpinnen.

    // Standard mode (buddy/family) — koppen + tekst volgens het thema
    static var largeTitle: Font        { BCFont.heading(34, .bold) }
    static var title: Font             { BCFont.heading(28, .bold) }
    static var titleEmphasized: Font   { BCFont.heading(22, .heavy) }
    static var title2: Font            { BCFont.heading(22, .semibold) }
    static var title3: Font            { BCFont.heading(20, .semibold) }
    static var headline: Font          { BCFont.heading(18, .semibold) }
    static var body: Font              { BCFont.body(17, .regular) }
    static var bodyEmphasized: Font    { BCFont.body(17, .semibold) }
    static var subheadline: Font       { BCFont.body(15, .regular) }
    static var callout: Font           { BCFont.body(16, .regular) }
    static var caption: Font           { BCFont.body(13, .regular) }
    static var captionEmphasized: Font { BCFont.body(13, .semibold) }

    // Cursief — voor citaten, subtiele nadruk en persoonlijke noten.
    static var bodyItalic: Font        { BCFont.bodyItalic(17) }
    static var calloutItalic: Font     { BCFont.bodyItalic(16) }
    static var subheadlineItalic: Font { BCFont.bodyItalic(15) }
    static var captionItalic: Font     { BCFont.bodyItalic(13) }
    static var headingItalic: Font     { BCFont.headingItalic(20, .semibold) }

    // Elderly mode — larger sizes, minimum 20pt body per accessibility spec
    static var elderlyTitle: Font      { BCFont.heading(28, .bold) }
    static var elderlyHeading: Font    { BCFont.heading(24, .bold) }
    static var elderlyBody: Font       { BCFont.body(20, .regular) }
    static var elderlyCaption: Font    { BCFont.body(17, .regular) }
    static var elderlyButton: Font     { BCFont.heading(22, .semibold) }
}

// MARK: - Elderly large-text scale

struct BCElderlyType {
    let large: Bool
    // Normal → Large: each step adds ~6pt
    var title:   Font { BCFont.heading(large ? 36 : 28, .bold) }
    var heading: Font { BCFont.heading(large ? 30 : 24, .bold) }
    var body:    Font { BCFont.body(large ? 26 : 20, .regular) }
    var caption: Font { BCFont.body(large ? 21 : 17, .regular) }
    var button:  Font { BCFont.heading(large ? 28 : 22, .semibold) }
    var iconBoxSize: CGFloat { large ? 88 : 72 }
    var iconSize:    CGFloat { large ? 40 : 32 }
    var tileHeight:  CGFloat { large ? 148 : 120 }
}

// MARK: - EnvironmentKey so every elderly view inherits the flag

private struct LargeTextEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var largeTextEnabled: Bool {
        get { self[LargeTextEnabledKey.self] }
        set { self[LargeTextEnabledKey.self] = newValue }
    }
}
