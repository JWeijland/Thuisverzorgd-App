//  BCProfileComponents.swift
//  Verplaatst uit BCComponents.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

/// Hoge navy-header met afgeronde onderhoeken en een klein bovenschriftje.
/// Bedoeld als eerste element in een ScrollView; de profielinhoud schuift met een
/// negatieve bovenmarge er overheen zodat de avatar mooi overlapt.
///
/// Stretchy gedrag: bij naar beneden slepen (overscroll) rekt de volledige
/// header-achtergrond als één geheel mee omhoog om het gat te vullen, met behoud
/// van de ronde onderhoeken. Zo laat de header nooit los van zijn afgeronde
/// onderrand ("verkaot") en blijft eventuele decoratie in de achtergrond netjes
/// meebewegen. Werkt centraal voor elk profiel dat BCProfileScaffold gebruikt.
struct BCProfileHeader: View {
    let eyebrow: String

    private let baseHeight: CGFloat = 128

    var body: some View {
        GeometryReader { geo in
            // Positieve waarde = de gebruiker trekt de pagina naar beneden.
            let stretch = max(0, geo.frame(in: .global).minY)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Text(eyebrow)
                    .font(BCTypography.captionEmphasized)
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.7))
                    // Genoeg ruimte zodat de avatar (die met -44 overlapt) de tekst
                    // niet meer doorsnijdt; de eyebrow staat nu duidelijk erboven.
                    .padding(.bottom, 58)
            }
            .frame(width: geo.size.width, height: baseHeight + stretch)
            .background(
                LinearGradient(colors: [BCColors.navy700, BCColors.navy900],
                               startPoint: .top, endPoint: .bottom)
            )
            // De clip zit op de volledige (uitrekkende) achtergrond, dus de ronde
            // onderhoeken blijven altijd intact.
            .clipShape(.rect(bottomLeadingRadius: BCRadius.xl,
                             bottomTrailingRadius: BCRadius.xl,
                             style: .continuous))
            // Verankert de header bovenaan: de extra hoogte groeit naar boven mee
            // en vult zo het overscroll-gat.
            .offset(y: -stretch)
        }
        .frame(height: baseHeight)
    }
}

/// Ronde avatar met witte rand, die over de header valt. Toont een foto, initialen
/// of een SF Symbol.
struct BCProfileAvatar: View {
    var image: UIImage? = nil
    var initials: String = ""
    var systemName: String? = nil
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle()
                .fill(BCColors.surface)
                .frame(width: size, height: size)
                .bcSoftShadow(.raised)

            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(BCColors.primary.opacity(0.12))
                        if let systemName {
                            Image(systemName: systemName)
                                .font(.system(size: size * 0.42, weight: .semibold))
                                .foregroundStyle(BCColors.primary)
                        } else {
                            Text(initials)
                                .font(BCFont.heading(size * 0.31, .bold))
                                .foregroundStyle(BCColors.primary)
                        }
                    }
                }
            }
            .frame(width: size - 10, height: size - 10)
            .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }
}

/// Klein, rustig sectielabel (HOOFDLETTERS) met optionele actie rechts.
struct BCProfileSectionLabel: View {
    let title: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(BCTypography.captionEmphasized)
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(BCColors.textTertiary)
            Spacer()
            if let trailing, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailing)
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, BCSpacing.sm - 2)
        .padding(.bottom, BCSpacing.sm)
    }
}

/// Dunne scheidingslijn met optionele inspringing links (zoals onder een icoon).
struct BCHairline: View {
    var leading: CGFloat = BCSpacing.md

    var body: some View {
        Rectangle()
            .fill(BCColors.border)
            .frame(height: 1)
            .padding(.leading, leading)
    }
}

/// Informatierij: icoon · label links, waarde rechts. Lege waarde toont een
/// subtiel "Nog invullen" en is aantikbaar (mits `action` gezet) — zo blijft het
/// rustig op het scherm maar kan ontbrekende info toch aangevuld worden.
struct BCProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    var placeholder: String = "Nog invullen"
    /// Punt 13: toont subtiel of dit gegeven zichtbaar is voor anderen. nil = geen tag.
    var visible: Bool? = nil
    var action: (() -> Void)? = nil

    private var isEmpty: Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BCColors.navy500)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                    if let visible {
                        BCVisibilityTag(isVisible: visible)
                    }
                }
                Spacer(minLength: BCSpacing.sm)
                Text(isEmpty ? placeholder : value)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(isEmpty ? BCColors.textTertiary : BCColors.textPrimary)
                    .multilineTextAlignment(.trailing)
                if isEmpty && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BCColors.textTertiary)
                }
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

/// Klein, subtiel labeltje dat aangeeft of een gegeven zichtbaar is voor anderen
/// (oog) of privé (oog met streep). Punt 13.
struct BCVisibilityTag: View {
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 9, weight: .semibold))
            Text(isVisible ? "Zichtbaar" : "Privé")
                .font(BCTypography.caption)
        }
        .foregroundStyle(isVisible ? BCColors.success : BCColors.textTertiary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill((isVisible ? BCColors.success : BCColors.textTertiary).opacity(0.12)))
    }
}

/// Compacte schakelaar om per gegeven de zichtbaarheid te regelen (in een editor).
struct BCVisibilityToggle: View {
    @Binding var isVisible: Bool

    var body: some View {
        Toggle(isOn: $isVisible) {
            HStack(spacing: 6) {
                Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isVisible ? BCColors.success : BCColors.textTertiary)
                Text(isVisible ? "Zichtbaar voor anderen" : "Privé, alleen voor jou")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
            }
        }
        .tint(BCColors.success)
    }
}

/// Schakelaar-rij binnen een inset-card (groene pil).
struct BCProfileToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var tint: Color = BCColors.accent

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(tint)
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, 12)
    }
}

/// Navigatierij met chevron rechts (bijv. "Privacy & gegevens").
struct BCProfileNavRow: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BCColors.navy500)
                        .frame(width: 24)
                }
                Text(title)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Rustige statistiek-band onder de naam op een profiel: 2–4 cijfers met label,
/// gescheiden door dunne verticale lijntjes. Geeft elk profiel direct structuur
/// en een herkenbare "looks" — net als de vertrouwens-strip, maar met getallen.
struct BCProfileStatRow: View {
    struct Stat: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        var tint: Color = BCColors.textPrimary
    }
    let stats: [Stat]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Rectangle().fill(BCColors.border).frame(width: 1, height: 30)
                }
                VStack(spacing: 3) {
                    Text(stat.value)
                        .font(BCFont.heading(20, .bold))
                        .foregroundStyle(stat.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(stat.label.uppercased())
                        .font(BCTypography.caption)
                        .tracking(0.6)
                        .foregroundStyle(BCColors.textTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, BCSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                .fill(BCColors.surface)
        )
        .bcSoftShadow(.card)
    }
}

/// Klein, rustig label met de organisatie-herkomst ("Via …"). Staat onder de
/// naam op de profielen van cliënt, familielid en buddy; alleen zichtbaar als
/// de gebruiker via een vrijwilligersorganisatie is binnengekomen. Puur
/// informatief: de huisstijl van de app verandert niet per organisatie.
struct BCOrganizationTag: View {
    let name: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "building.2")
                .font(.system(size: 11, weight: .semibold))
            Text("Via \(name)")
                .font(BCTypography.captionEmphasized)
                .lineLimit(1)
        }
        .foregroundStyle(BCColors.primary)
        .padding(.horizontal, BCSpacing.sm + 2)
        .padding(.vertical, 5)
        .background(Capsule().fill(BCColors.primaryMuted))
    }
}

/// Schermvullende profiel-scaffold: hoge header + scrollbare witte inhoud met de
/// avatar die over de header valt. De inhoud levert de call-site aan.
struct BCProfileScaffold<Content: View>: View {
    let eyebrow: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BCProfileHeader(eyebrow: eyebrow)
                VStack(spacing: BCSpacing.lg) {
                    content()
                }
                .padding(.horizontal, BCSpacing.md + 2)
                .padding(.top, -44)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }
}
