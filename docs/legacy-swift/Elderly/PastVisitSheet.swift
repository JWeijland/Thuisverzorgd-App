//  PastVisitSheet.swift
//  Verplaatst uit ElderlyHomeView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import CoreImage

struct PastVisitSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let task: ServiceTask

    @State private var selectedStars: Int = 0
    @State private var reviewText: String = ""
    @State private var submitted: Bool = false

    private var buddy: BuddyUser? {
        guard let name = task.assignedBuddyName else { return nil }
        return appState.allBuddies.first { $0.firstName == name }
    }

    private var alreadyRated: Bool { appState.taskRatings[task.id] != nil }
    private var alreadySkipped: Bool { appState.skippedReviews.contains(task.id) }
    private var isFavorite: Bool {
        guard let name = task.assignedBuddyName else { return false }
        return appState.favoriteBuddyNames.contains(name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BCSpacing.lg) {

                    // Buddy header
                    VStack(spacing: BCSpacing.sm) {
                        ZStack {
                            Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 80, height: 80)
                            Image(systemName: buddy?.avatarSystemName ?? "person.crop.circle.fill")
                                .font(.system(size: 44, weight: .regular))
                                .foregroundStyle(BCColors.primary)
                        }
                        Text(task.assignedBuddyName ?? "Buddy")
                            .font(BCTypography.title2)
                            .foregroundStyle(BCColors.textPrimary)
                        if let b = buddy {
                            HStack(spacing: BCSpacing.sm) {
                                BCRatingStars(value: b.ratingAverage)
                                Text("\(b.totalTasks) bezoeken")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                            }
                        }
                    }
                    .padding(.top, BCSpacing.md)

                    // Visit summary
                    BCCard {
                        VStack(spacing: BCSpacing.sm) {
                            HStack {
                                Label(task.category.displayName, systemImage: task.category.icon)
                                    .font(BCTypography.bodyEmphasized)
                                    .foregroundStyle(BCColors.textPrimary)
                                Spacer()
                                BCStatusPill(label: "Voltooid", color: BCColors.success)
                            }
                            if let date = task.completedAt {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(BCColors.textTertiary)
                                    Text(date.formatted(date: .long, time: .shortened))
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    // Favorite toggle
                    if let name = task.assignedBuddyName {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            appState.toggleFavorite(buddyName: name)
                        } label: {
                            HStack(spacing: BCSpacing.md) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(isFavorite ? BCColors.danger : BCColors.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(isFavorite ? BCColors.danger.opacity(0.10) : BCColors.surface))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isFavorite ? "Vaste buddy" : "Voeg toe aan vaste buddies")
                                        .font(BCTypography.headline)
                                        .foregroundStyle(BCColors.textPrimary)
                                    Text(isFavorite ? "\(name) krijgt voorrang bij uw volgende aanvraag" : "Dan krijgt \(name) voorrang bij uw volgende aanvraag")
                                        .font(BCTypography.caption)
                                        .foregroundStyle(BCColors.textSecondary)
                                }
                                Spacer()
                                if isFavorite {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BCColors.success)
                                }
                            }
                            .padding(BCSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                    .fill(BCColors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                                            .stroke(isFavorite ? BCColors.danger.opacity(0.3) : BCColors.border, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, BCSpacing.lg)
                        .animation(.easeInOut(duration: 0.2), value: isFavorite)
                    }

                    // Rating section — niet voor zorginstelling-cliënten
                    if !appState.isCordaanElderly {
                    if alreadyRated {
                        BCCard {
                            HStack {
                                Text("Uw beoordeling")
                                    .font(BCTypography.subheadline)
                                    .foregroundStyle(BCColors.textSecondary)
                                Spacer()
                                BCRatingStars(value: Double(appState.taskRatings[task.id] ?? 0))
                            }
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else if submitted {
                        VStack(spacing: BCSpacing.md) {
                            BCPopIcon(systemName: "star.fill", color: BCColors.warning, size: 44)
                            Text("Bedankt voor uw beoordeling!")
                                .font(BCTypography.headline)
                                .foregroundStyle(BCColors.textPrimary)
                        }
                        .padding(BCSpacing.xl)
                    } else if alreadySkipped {
                        Button {
                            appState.unskipReview(taskId: task.id)
                        } label: {
                            Text("Beoordeling alsnog geven")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.primary)
                                .padding(.vertical, BCSpacing.sm)
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(spacing: BCSpacing.md) {
                            Text("Hoe was het bezoek?")
                                .font(BCTypography.elderlyHeading)
                                .foregroundStyle(BCColors.textPrimary)

                            HStack(spacing: BCSpacing.md) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedStars = star
                                    } label: {
                                        Image(systemName: star <= selectedStars ? "star.fill" : "star")
                                            .font(.system(size: 36, weight: .semibold))
                                            .foregroundStyle(star <= selectedStars ? BCColors.warning : BCColors.border)
                                            .frame(width: 56, height: 56)
                                            .scaleEffect(star <= selectedStars ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.2), value: selectedStars)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedStars > 0 {
                                BCCard {
                                    TextField("Vertel er iets meer over (optioneel)", text: $reviewText, axis: .vertical)
                                        .lineLimit(3, reservesSpace: true)
                                        .font(BCTypography.elderlyBody)
                                        .foregroundStyle(BCColors.textPrimary)
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                                BCPrimaryButton(title: "Verstuur beoordeling", icon: "star.fill") {
                                    appState.rateTask(taskId: task.id, stars: selectedStars, body: reviewText)
                                    withAnimation { submitted = true }
                                }
                                .padding(.horizontal, BCSpacing.lg)
                                .transition(.opacity)
                            }

                            Button {
                                appState.skipReview(taskId: task.id)
                                dismiss()
                            } label: {
                                Text("Beoordeling overslaan")
                                    .font(BCTypography.caption)
                                    .foregroundStyle(BCColors.textTertiary)
                                    .padding(.vertical, BCSpacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                        .animation(.easeInOut(duration: 0.2), value: selectedStars)
                    }
                    } // einde rating section (niet-Cordaan)

                    Spacer(minLength: BCSpacing.xl)
                }
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Bezoek details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sluiten") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .onAppear {
            selectedStars = appState.taskRatings[task.id] ?? 0
        }
    }
}
