import SwiftUI

// MARK: - App-icoon (merk-icoon of SF Symbol)

/// Toont een merk-icoon uit de Asset Catalog (naam met `tv-`-prefix, in de
/// originele kleuren) of valt terug op een SF Symbol. `size` is de hoogte in pt.
/// Zo kunnen call-sites één string gebruiken en kiezen we automatisch de bron.
///
/// White-label: call-sites blijven `tv-…` gebruiken, maar het getoonde icoon
/// hoort bij de iconenset van het actieve thema (`tv-`, `zuid-`, `present-`).
/// Ontbreekt een themed asset, dan vallen we netjes terug op het `tv-`-icoon.
struct AppIcon: View {
    let name: String
    var size: CGFloat = 20
    var weight: Font.Weight = .semibold
    var color: Color? = nil

    /// Vertaalt een merk-iconaam naar de variant van het actieve thema.
    /// "tv-dashboard" → "zuid-dashboard" (of terug naar "tv-dashboard" als die
    /// niet bestaat voor dit thema).
    static func resolvedAssetName(_ name: String) -> String? {
        // Strip een bekende iconset-prefix om de logische naam over te houden.
        let base: String
        if let r = name.range(of: "-") {
            let prefix = String(name[..<r.lowerBound])
            let known = ["tv", "zuid", "present"]
            base = known.contains(prefix) ? String(name[r.upperBound...]) : name
        } else {
            base = name
        }
        let prefix = BCThemeManager.current.iconPrefix
        let themed = "\(prefix)-\(base)"
        if UIImage(named: themed) != nil { return themed }
        let fallback = "tv-\(base)"
        if UIImage(named: fallback) != nil { return fallback }
        return nil
    }

    var body: some View {
        if name.hasPrefix("tv-") || name.hasPrefix("zuid-") || name.hasPrefix("present-") {
            if let asset = Self.resolvedAssetName(name) {
                Image(asset)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Color.clear.frame(width: size, height: size)
            }
        } else {
            Image(systemName: name)
                .font(.system(size: size, weight: weight))
                .foregroundStyle(color ?? Color.primary)
        }
    }
}

// MARK: - Corner radius helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Profielkit (gedeelde bouwstenen voor de profielschermen)
//
// Rustig, wit & ruim: een hoge navy-header met afgeronde onderhoeken, een avatar
// die over de witte sheet valt, en inset-lijsten met haarlijntjes. Alle kleuren,
// hoeken en fonts komen uit het actieve thema, dus white-label blijft werken.

// MARK: - Merkteken: de gestapelde T (Brand Guidelines h2)
//
// Constructie uit één maat, de balkhoogte b: hoekradius ½ b (volledig rond),
// stam 1 b breed en 2,5 b hoog, ruimte tussen balk en stam 0,23 b.
// Blauw = de hulpvraag, groen = de vrijwilliger, de stam = de steun.

enum BCLogoVariant {
    /// Blauw + groen + navy stam, voor lichte ondergronden.
    case kleur
    /// Blauw + groen + witte stam, de voorkeur op navy vlakken.
    case diapositief
    /// Eén kleur (stempel, watermerk); vormen blijven altijd gelijk.
    case mono(Color)
}

struct BCLogoMark: View {
    /// Totale hoogte van het merkteken in punten.
    var height: CGFloat = 40
    var variant: BCLogoVariant = .kleur

    private var b: CGFloat { height / 3.73 }

    var body: some View {
        VStack(spacing: 0.23 * b) {
            BCMicroBalk(barHeight: b, variant: variant)
            Capsule(style: .continuous)
                .fill(stemColor)
                .frame(width: b, height: 2.5 * b)
        }
        .accessibilityHidden(true)
    }

    private var stemColor: Color {
        switch variant {
        case .kleur:            return BCColors.primary
        case .diapositief:      return .white
        case .mono(let color):  return color
        }
    }
}

/// Alleen de tweekleurige balk: het micro-merkje voor ruimtes onder 24 pt
/// (badge, kaartpin, voetregel) en de bouwsteen van het volledige merkteken.
struct BCMicroBalk: View {
    var barHeight: CGFloat = 8
    var variant: BCLogoVariant = .kleur

    var body: some View {
        HStack(spacing: 0.16 * barHeight) {
            Capsule(style: .continuous)
                .fill(leftColor)
                .frame(width: 2.1 * barHeight, height: barHeight)
            Capsule(style: .continuous)
                .fill(rightColor)
                .frame(width: 2.1 * barHeight, height: barHeight)
        }
        .accessibilityHidden(true)
    }

    private var leftColor: Color {
        switch variant {
        case .kleur, .diapositief:  return BCColors.primaryMid
        case .mono(let color):      return color
        }
    }

    private var rightColor: Color {
        switch variant {
        case .kleur, .diapositief:  return BCColors.accent
        case .mono(let color):      return color
        }
    }
}

/// Het merkstreepje: klein blauw+groen streepje als bullet, onderstreping van
/// trotse cijfers en accent in voetregels (Brand Guidelines 2.6 en 3.3).
struct BCMerkstreepje: View {
    var height: CGFloat = 6

    var body: some View {
        HStack(spacing: height * 0.45) {
            Capsule(style: .continuous)
                .fill(BCColors.primaryMid)
                .frame(width: height * 2.8, height: height)
            Capsule(style: .continuous)
                .fill(BCColors.accent)
                .frame(width: height * 1.6, height: height)
            Circle()
                .fill(BCColors.accent)
                .frame(width: height, height: height)
        }
        .accessibilityHidden(true)
    }
}

/// Laadstand: het logo valt uiteen in drie stuiterende stippen
/// (blauw, groen, navy). Respecteert reduce-motion met een rustige, vaste rij.
struct BCLoadingDots: View {
    var label: String? = nil
    var dotSize: CGFloat = 10
    var onDark: Bool = false

    @State private var bouncing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var colors: [Color] {
        [BCColors.primaryMid, BCColors.accent, onDark ? .white : BCColors.primary]
    }

    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            HStack(spacing: dotSize * 0.5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(colors[i])
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: bouncing && !reduceMotion ? -dotSize * 0.55 : dotSize * 0.2)
                        .animation(
                            reduceMotion ? nil :
                                .easeInOut(duration: 0.45)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: bouncing
                        )
                }
            }
            if let label {
                Text(label)
                    .font(BCTypography.subheadline)
                    .foregroundStyle(onDark ? .white.opacity(0.85) : BCColors.textSecondary)
            }
        }
        .onAppear { bouncing = true }
        .accessibilityLabel(label ?? "Even geduld")
    }
}

extension View {
    /// T-watermerk op 7% dekking in een hoek, nooit midden onder tekst
    /// (Brand Guidelines 2.6).
    func bcLogoWatermark(alignment: Alignment = .bottomTrailing,
                         height: CGFloat = 160,
                         color: Color = BCColors.primary) -> some View {
        overlay(alignment: alignment) {
            BCLogoMark(height: height, variant: .mono(color))
                .opacity(0.07)
                .padding(BCSpacing.lg)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Typografie met karakter (Brand Guidelines 3.3)
//
// Vier vaste stijlmiddelen, nooit een derde lettertype. Spelregel: één
// stijlmiddel per uiting; lopende tekst blijft rustig Open Sans in textPrimary.

/// 1 · Groene punt & accentwoord: een kop die eindigt op een Hulpgroene punt,
/// met optioneel één woord in Donkergroen.
struct BCHeroKop: View {
    let text: String
    var accentWord: String? = nil
    var font: Font = BCTypography.title
    var color: Color = BCColors.textPrimary
    var alignment: TextAlignment = .leading

    var body: some View {
        (styledText + Text(".").foregroundStyle(BCColors.accent))
            .font(font)
            .multilineTextAlignment(alignment)
    }

    private var styledText: Text {
        let base = text.hasSuffix(".") ? String(text.dropLast()) : text
        guard let accentWord, !accentWord.isEmpty,
              let range = base.range(of: accentWord) else {
            return Text(base).foregroundStyle(color)
        }
        return Text(String(base[..<range.lowerBound])).foregroundStyle(color)
            + Text(accentWord).foregroundStyle(BCColors.accentDark)
            + Text(String(base[range.upperBound...])).foregroundStyle(color)
    }
}

/// 2 · Het pil-woord: één woord in een volle pil, rond om iets belangrijks.
struct BCPillWord: View {
    enum Style {
        case navy, kringblauw, hulpgroen
    }

    let word: String
    var style: Style = .navy
    var font: Font = BCTypography.title2

    var body: some View {
        Text(word)
            .font(font)
            .foregroundStyle(foreground)
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.xs + 2)
            .background(Capsule(style: .continuous).fill(background))
    }

    private var background: Color {
        switch style {
        case .navy:       return BCColors.primary
        case .kringblauw: return BCColors.primaryMid
        case .hulpgroen:  return BCColors.accent
        }
    }

    private var foreground: Color {
        switch style {
        case .navy, .kringblauw: return .white
        case .hulpgroen:         return BCColors.onAccent
        }
    }
}

/// 3 · Trotse cijfers: een stat groot in Montserrat ExtraBold met het
/// merkstreepje als onderstreping.
struct BCProudStat: View {
    let value: String
    let label: String
    var valueSize: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: BCSpacing.sm) {
                Text(value)
                    .font(BCFont.heading(valueSize, .heavy))
                    .foregroundStyle(BCColors.primaryMid)
                Text(label)
                    .font(BCTypography.headline)
                    .foregroundStyle(BCColors.textPrimary)
            }
            BCMerkstreepje()
        }
        .accessibilityElement(children: .combine)
    }
}

/// 4 · Het pil-citaat: cursief citaat met pil-aanhalingstekens, altijd met naam.
struct BCPillQuote: View {
    let quote: String
    let attribution: String
    var onDark: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.sm + 2) {
            HStack(spacing: 3) {
                Capsule(style: .continuous)
                    .fill(BCColors.accent)
                    .frame(width: 7, height: 16)
                Capsule(style: .continuous)
                    .fill(BCColors.primaryMid)
                    .frame(width: 7, height: 16)
            }
            .padding(.top, 4)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: BCSpacing.xs + 2) {
                Text(quote)
                    .font(BCTypography.bodyItalic)
                    .foregroundStyle(onDark ? .white : BCColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(attribution)
                    .font(BCTypography.captionEmphasized)
                    .foregroundStyle(onDark ? .white.opacity(0.8) : BCColors.primaryMid)
            }
        }
    }
}

// MARK: - De logotaal in de app (Brand Guidelines 5.2)

/// De losse pillen als vriendelijke illustratie voor lege en foutschermen:
/// de twee helften zoeken elkaar nog even. Nooit sombere iconen.
struct BCPillenPaar: View {
    var barHeight: CGFloat = 12

    var body: some View {
        HStack(spacing: barHeight * 1.1) {
            Capsule(style: .continuous)
                .fill(BCColors.primaryMid)
                .frame(width: barHeight * 2.4, height: barHeight)
                .rotationEffect(.degrees(-8))
            Capsule(style: .continuous)
                .fill(BCColors.accent)
                .frame(width: barHeight * 2.4, height: barHeight)
                .rotationEffect(.degrees(7))
        }
        .accessibilityHidden(true)
    }
}

