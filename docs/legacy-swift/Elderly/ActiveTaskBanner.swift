//  ActiveTaskBanner.swift
//  Verplaatst uit ElderlyHomeView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import CoreImage

struct ActiveTaskBanner: View {
    let task: ServiceTask
    /// 0…1 — hoe ver de buddy onderweg is (voller naarmate hij dichterbij komt).
    var routeProgress: Double = 0
    var onCall: () -> Void = {}
    var onMessage: () -> Void = {}
    var onShowQR: () -> Void = {}
    var onCancel: () -> Void = {}
    var onShowBuddyLocation: () -> Void = {}

    /// Buddy is gevonden en onderweg (aangenomen, nog niet ingecheckt).
    private var isOnTheWay: Bool { task.status == .accepted }
    /// Buddy is ingecheckt en bij de hulpvrager (of bezig met het bezoek).
    private var isHere: Bool { task.status == .arrived || task.status == .inProgress }
    /// Er is een buddy gekoppeld — onderweg óf aanwezig. Stuurt de hele
    /// "gevonden"-weergave aan, los van of we de buddynaam al binnen hebben
    /// (de naam kan door RLS nog ontbreken; de status is leidend).
    private var hasBuddy: Bool { isOnTheWay || isHere }

    private var statusLabel: String {
        switch task.status {
        case .accepted:             return "Onderweg naar u"
        case .arrived, .inProgress: return "Buddy is bij u"
        default:                    return task.status.label
        }
    }

    private var statusColor: Color {
        hasBuddy ? BCColors.success : task.status.color
    }

    /// Ondertitel onder de groene bevestiging; valt netjes terug als de
    /// buddynaam nog niet bekend is.
    private var buddyStatusSubtitle: String {
        if let buddy = task.assignedBuddyName {
            return isHere ? "\(buddy) is bij u aangekomen." : "\(buddy) is onderweg naar u."
        }
        return isHere ? "De buddy is bij u aangekomen." : "Een buddy is onderweg naar u."
    }

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                HStack {
                    BCStatusPill(
                        label: statusLabel,
                        color: statusColor,
                        showDot: true
                    )
                    Spacer()
                    if let eta = task.assignedBuddyEtaMinutes, isOnTheWay {
                        HStack(spacing: 4) {
                            AppIcon(name: "tv-klok", size: 13)
                            Text("\(eta) min")
                        }
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(BCColors.surfaceMuted))
                    }
                }

                if hasBuddy {
                    // Duidelijke bevestiging zodra een buddy de hulpvraag aanneemt.
                    // Gestuurd op status (niet op naam) zodat het hele vak meteen
                    // omslaat naar "gevonden", ook als de naam nog onderweg is.
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(BCColors.success)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isHere ? "Buddy is bij u" : "Buddy gevonden en onderweg")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                            Text(buddyStatusSubtitle)
                                .font(BCTypography.subheadline)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }

                    // Buddyprofiel tonen zodra de naam binnen is.
                    if let buddy = task.assignedBuddyName {
                        HStack(spacing: BCSpacing.sm) {
                            ZStack {
                                if let img = buddyAvatarImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    LinearGradient(
                                        colors: [BCColors.navy700, BCColors.navy500],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.95))
                                }
                            }
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .bcSoftShadow(.subtle)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isHere ? "\(buddy) is bij u" : "\(buddy) komt naar u toe")
                                    .font(BCTypography.headline)
                                    .foregroundStyle(BCColors.textPrimary)
                                HStack(spacing: 4) {
                                    Text(task.category.displayName)
                                    if let r = task.assignedBuddyRating {
                                        Text("· ★ \(String(format: "%.1f", r))")
                                    }
                                }
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    // Voller naarmate de buddy dichterbij komt (live afstand).
                    BCProgressBar(value: isHere ? 1.0 : max(routeProgress, 0.05), color: BCColors.accent)

                    if isHere {
                        // Buddy is ingecheckt → bezoek afronden door de QR te tonen
                        // zodat de buddy weer kan uitchecken.
                        ctaButton("Bezoek afronden: QR tonen", icon: "qrcode", action: onShowQR)
                    } else {
                        // Live volgen waar de buddy nu is.
                        ctaButton("Kijk waar uw buddy nu is", icon: "location.fill", action: onShowBuddyLocation)
                        HStack(spacing: BCSpacing.sm) {
                            actionButton("Bellen", icon: "phone.fill", filled: true, action: onCall)
                            actionButton("Bericht", icon: "message.fill", filled: false, action: onMessage)
                        }
                        // QR-code zodat de buddy bij aankomst kan inchecken.
                        ctaButton("Toon QR-code voor de buddy", icon: "qrcode", action: onShowQR)
                        cancelButton
                    }
                } else {
                    VStack(spacing: BCSpacing.md) {
                        BCBuddySearchPulse()
                            .padding(.top, BCSpacing.xs)
                        VStack(spacing: 6) {
                            Text("We zoeken een buddy voor u…")
                                .font(BCTypography.elderlyHeading)
                                .foregroundStyle(BCColors.textPrimary)
                            Text("Een vertrouwde buddy in de buurt voor: \(task.category.displayName)")
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        cancelButton
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BCSpacing.xs)
                }
            }
        }
    }

    /// Toont automatisch een echte foto zodra je een afbeelding met de buddynaam
    /// (bv. "Sanne" of "buddy-sanne") aan Assets.xcassets toevoegt; anders een nette avatar.
    private var buddyAvatarImage: UIImage? {
        guard let name = task.assignedBuddyName else { return nil }
        return UIImage(named: name) ?? UIImage(named: "buddy-\(name.lowercased())")
    }

    /// Subtiele knop om de hulpvraag in te trekken (zolang er nog geen bezoek bezig is).
    private var cancelButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onCancel()
        } label: {
            Text("Hulpvraag intrekken")
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BCSpacing.xs)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func ctaButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: icon).font(.system(size: 16, weight: .bold))
                Text(title).font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(BCColors.navy900)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(BCColors.accent)
            )
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(title).font(BCTypography.bodyEmphasized)
            }
            .foregroundStyle(filled ? .white : BCColors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(filled ? BCColors.primary : BCColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .stroke(BCColors.primary.opacity(filled ? 0 : 0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
