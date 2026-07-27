import SwiftUI

// ============================================================
// AdminPrizesView — de beheerder bepaalt de team-prijzenladder (fase20)
//
// Eén prijs per puntendoel; hoe hoger het doel, hoe mooier de prijs. Bij het
// aanmaken van een team kiest de maker alleen het doel — de prijs rolt hieruit.
// Competitieprijzen (plek 1/2/3) worden per competitie ingesteld.
// ============================================================

struct AdminPrizesView: View {
    @Environment(AppState.self) private var appState
    @State private var editing: DBTeamPrize? = nil
    @State private var showAdd = false

    private var ladder: [DBTeamPrize] { appState.teamPrizes.sorted { $0.pointsThreshold < $1.pointsThreshold } }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Prijzen", subtitle: "Teamprijzen per puntendoel")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    BCCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hoe het werkt").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                            Text("Elke prijs hangt aan een puntendoel. Een hoger doel hoort bij een mooiere prijs. Teams kiezen bij het aanmaken een doel; die prijs verdienen ze als ze het halen. Competitieprijzen (plek 1/2/3) stel je per competitie in.")
                                .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, BCSpacing.lg)

                    Button {
                        showAdd = true
                    } label: {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Nieuwe prijs-tier")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.primary))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, BCSpacing.lg)

                    if ladder.isEmpty {
                        BCEmptyState(icon: "gift", title: "Nog geen prijzen",
                                     message: "Voeg per puntendoel een prijs toe.")
                            .padding(.top, BCSpacing.xl)
                    } else {
                        ForEach(ladder) { prize in
                            prizeCard(prize)
                        }
                    }
                    Spacer().frame(height: BCSpacing.xl)
                }
                .padding(.top, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .onAppear { appState.adminLoadTeamPrizes() }
        .refreshable { appState.adminLoadTeamPrizes() }
        .sheet(isPresented: $showAdd) {
            PrizeEditSheet(existing: nil, suggestedThreshold: (ladder.last?.pointsThreshold ?? 500) + 500)
        }
        .sheet(item: $editing) { prize in
            PrizeEditSheet(existing: prize, suggestedThreshold: prize.pointsThreshold)
        }
    }

    private func prizeCard(_ prize: DBTeamPrize) -> some View {
        BCCard {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 44, height: 44)
                    Image(systemName: prize.icon ?? "gift.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BCColors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(prize.title).font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                    Text("Bij \(prize.pointsThreshold) punten").font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                }
                Spacer()
                Menu {
                    Button { editing = prize } label: { Label("Wijzig", systemImage: "pencil") }
                    Button(role: .destructive) { appState.adminDeleteTeamPrize(id: prize.id) } label: {
                        Label("Verwijder", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.system(size: 20)).foregroundStyle(BCColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}

private struct PrizeEditSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let existing: DBTeamPrize?
    @State private var threshold: Int
    @State private var title: String
    @State private var icon: String

    private let icons = ["gift.fill", "popcorn.fill", "cup.and.saucer.fill", "fork.knife",
                         "suitcase.fill", "ticket.fill", "trophy.fill", "star.fill"]

    init(existing: DBTeamPrize?, suggestedThreshold: Int) {
        self.existing = existing
        _threshold = State(initialValue: existing?.pointsThreshold ?? suggestedThreshold)
        _title = State(initialValue: existing?.title ?? "")
        _icon = State(initialValue: existing?.icon ?? "gift.fill")
    }

    private var canSave: Bool { threshold > 0 && !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Puntendoel") {
                    Stepper("\(threshold) punten", value: $threshold, in: 100...100000, step: 100)
                }
                Section("Prijs") {
                    TextField("Bijv. Weekendje weg met het team", text: $title)
                }
                Section("Icoon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: BCSpacing.sm) {
                        ForEach(icons, id: \.self) { sym in
                            Button { icon = sym } label: {
                                Image(systemName: sym)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(icon == sym ? .white : BCColors.textSecondary)
                                    .frame(width: 48, height: 48)
                                    .background(Circle().fill(icon == sym ? AnyShapeStyle(BCColors.primary) : AnyShapeStyle(BCColors.surfaceMuted)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(existing == nil ? "Nieuwe prijs" : "Prijs wijzigen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bewaar") {
                        if let existing {
                            appState.adminUpdateTeamPrize(id: existing.id, threshold: threshold, title: title, icon: icon)
                        } else {
                            appState.adminAddTeamPrize(threshold: threshold, title: title, icon: icon)
                        }
                        dismiss()
                    }
                    .font(BCTypography.bodyEmphasized)
                    .tint(BCColors.primary)
                    .disabled(!canSave)
                }
            }
        }
    }
}
