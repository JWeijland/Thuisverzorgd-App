import SwiftUI

struct ReviewView: View {
    @Environment(AppState.self) private var appState

    /// Naam van de beoordeelde (buddy óf hulpvrager).
    let revieweeName: String
    let onDismiss: () -> Void
    /// Wordt aangeroepen met (sterren, tekst) bij versturen.
    var onSubmit: ((Int, String) -> Void)? = nil
    /// Eigen vraag-kop; standaard "Hoe was het bezoek van [naam]?".
    var question: String? = nil
    var thankYouMessage: String = "Uw beoordeling helpt ons om betere buddies te vinden."
    /// Optioneel: knop op het bedankscherm om deze persoon als vaste buddy te
    /// markeren (alleen relevant voor de hulpvrager die een buddy beoordeelt).
    var onMakeFavorite: (() -> Void)? = nil

    @State private var selectedStars: Int = 0
    @State private var reviewText: String = ""
    @State private var submitted: Bool = false
    @State private var madeFavorite: Bool = false
    @State private var showHeartMoment: Bool = false

    private var questionText: String { question ?? "Hoe was het bezoek van \(revieweeName)?" }

    var body: some View {
        ZStack {
            if submitted {
                thankYouView
            } else {
                reviewForm
            }

            // Het feestelijke moment zodra deze buddy een vaste buddy wordt.
            if showHeartMoment {
                BCHeartCelebration(
                    buddyName: revieweeName,
                    subtitle: "\(revieweeName) krijgt hier meteen een berichtje van en blijft zo een vertrouwd gezicht voor u."
                ) {
                    withAnimation(.easeOut(duration: 0.3)) { showHeartMoment = false }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    private var reviewForm: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Beoordeling", subtitle: "Hoe was het bezoek?")

            ScrollView {
                VStack(spacing: BCSpacing.xl) {
                    VStack(spacing: BCSpacing.md) {
                        ZStack {
                            Circle().fill(BCColors.primary.opacity(0.12)).frame(width: 80, height: 80)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(BCColors.primary)
                        }

                        Text(questionText)
                            .font(BCTypography.elderlyHeading)
                            .foregroundStyle(BCColors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, BCSpacing.xl)
                    .padding(.horizontal, BCSpacing.lg)

                    // Large star buttons — minimum 60×60pt each per accessibility spec
                    HStack(spacing: BCSpacing.md) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                selectedStars = star
                            } label: {
                                Image(systemName: star <= selectedStars ? "star.fill" : "star")
                                    .font(.system(size: 38, weight: .semibold))
                                    .foregroundStyle(star <= selectedStars ? BCColors.warning : BCColors.border)
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(star <= selectedStars ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.2), value: selectedStars)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(star) ster\(star == 1 ? "" : "ren")")
                        }
                    }

                    if selectedStars > 0 {
                        BCCard {
                            VStack(alignment: .leading, spacing: BCSpacing.xs) {
                                Text("Vertel er iets meer over (optioneel)")
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                TextField("Uw ervaring met dit bezoek…", text: $reviewText, axis: .vertical)
                                    .lineLimit(4, reservesSpace: true)
                                    .font(BCTypography.elderlyBody)
                                    .foregroundStyle(BCColors.textPrimary)
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: BCSpacing.xl)
                }
            }

            VStack(spacing: BCSpacing.sm) {
                Divider()

                BCCTAButton(
                    title: "Verstuur beoordeling",
                    icon: "star.fill"
                ) {
                    if let onSubmit {
                        onSubmit(selectedStars, reviewText)
                    } else {
                        appState.elderlySubmitsReview(stars: selectedStars, body: reviewText)
                    }
                    withAnimation { submitted = true }
                }
                .opacity(selectedStars > 0 ? 1.0 : 0.4)
                .disabled(selectedStars == 0)
                .padding(.horizontal, BCSpacing.lg)

                Button { onDismiss() } label: {
                    Text("Misschien later")
                        .font(BCTypography.elderlyCaption)
                        .foregroundStyle(BCColors.textTertiary)
                        .padding(.vertical, BCSpacing.sm)
                }
                .buttonStyle(.plain)
                .padding(.bottom, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
    }

    private var thankYouView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()

            BCPopIcon(systemName: "star.fill", color: BCColors.warning, size: 72)

            VStack(spacing: BCSpacing.sm) {
                Text("Bedankt!")
                    .font(BCTypography.elderlyTitle)
                    .foregroundStyle(BCColors.textPrimary)
                Text(thankYouMessage)
                    .font(BCTypography.elderlyBody)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BCSpacing.lg)
            }

            // De persoonlijke vervolgvraag: wordt deze buddy een vaste buddy?
            // Bewust prominent — een vaste band maakt de hulp persoonlijker.
            if let onMakeFavorite {
                VStack(spacing: BCSpacing.md) {
                    if madeFavorite {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(BCColors.danger)
                            Text("\(revieweeName) is nu uw vaste buddy")
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BCSpacing.md)
                    } else {
                        VStack(spacing: BCSpacing.xs) {
                            Text("Wilt u \(revieweeName) als vaste buddy?")
                                .font(BCTypography.title3)
                                .foregroundStyle(BCColors.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("Zo houdt u een vertrouwd gezicht: \(revieweeName) krijgt er meteen bericht van en staat voortaan bovenaan bij uw buddies.")
                                .font(BCTypography.subheadline)
                                .foregroundStyle(BCColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onMakeFavorite()
                            withAnimation {
                                madeFavorite = true
                                showHeartMoment = true
                            }
                        } label: {
                            HStack(spacing: BCSpacing.sm) {
                                Image(systemName: "heart.fill")
                                Text("Ja, maak \(revieweeName) mijn vaste buddy")
                            }
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                    .fill(BCColors.danger)
                            )
                        }
                        .buttonStyle(.plain)

                        Text("Liever niet? Dan verandert er niets.")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textTertiary)
                    }
                }
                .padding(BCSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                        .fill(BCColors.danger.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                        .stroke(BCColors.danger.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.sm)
            }

            Spacer()

            BCPrimaryButton(title: "Terug naar huis", icon: "house.fill") {
                onDismiss()
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.bottom, BCSpacing.xl)
        }
        .background(BCColors.background.ignoresSafeArea())
    }
}

#Preview {
    ReviewView(revieweeName: "Aiyla", onDismiss: {})
        .environment(AppState())
}
