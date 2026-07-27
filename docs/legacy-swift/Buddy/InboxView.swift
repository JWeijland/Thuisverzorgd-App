import SwiftUI

// ============================================================
// InboxView — in-app berichten-inbox van de buddy (fase18)
//
// Toont meldingen uit appState.inbox. Join-verzoeken (team_join_request) zijn
// actie-baar: de teameigenaar keurt ze hier goed of af.
// ============================================================

struct InboxView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if appState.inbox.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(appState.inbox) { msg in
                            row(msg)
                                .listRowInsets(EdgeInsets(top: BCSpacing.xs, leading: BCSpacing.lg,
                                                          bottom: BCSpacing.xs, trailing: BCSpacing.lg))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        appState.deleteInboxMessage(msg.id)
                                    } label: {
                                        Label("Verwijder", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(BCColors.background)
            .navigationTitle("Berichten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sluit") { dismiss() }.tint(BCColors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if appState.unreadInboxCount > 0 {
                        Button("Alles gelezen") { appState.markAllInboxRead() }.tint(BCColors.primary)
                    }
                }
            }
        }
    }

    // MARK: Rij

    private func row(_ msg: InboxMessage) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(alignment: .top, spacing: BCSpacing.md) {
                ZStack {
                    Circle().fill(tint(for: msg.kind).opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: msg.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint(for: msg.kind))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(msg.title)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let body = msg.body, !body.isEmpty {
                        Text(body)
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(relativeTime(msg.date))
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }
                Spacer(minLength: 0)
                if !msg.read {
                    Circle().fill(BCColors.danger).frame(width: 9, height: 9).padding(.top, 4)
                }
            }

            if msg.isActionable {
                HStack(spacing: BCSpacing.sm) {
                    Button {
                        appState.approveJoinRequest(msg)
                    } label: {
                        Label("Goedkeuren", systemImage: "checkmark")
                            .font(BCTypography.captionEmphasized)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundStyle(.white)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.success))
                    }
                    .buttonStyle(.plain)
                    Button {
                        appState.rejectJoinRequest(msg)
                    } label: {
                        Label("Afwijzen", systemImage: "xmark")
                            .font(BCTypography.captionEmphasized)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundStyle(BCColors.danger)
                            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.danger.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
        .contentShape(Rectangle())
        .onTapGesture {
            if !msg.read { appState.markInboxRead(msg.id) }
            // Punt 10: navigeer naar de relevante pagina (BuddyMapView pikt dit op).
            appState.inboxDestination = msg.destination
            dismiss()
        }
    }

    private var emptyState: some View {
        VStack(spacing: BCSpacing.sm) {
            BCPillenPaar()
                .padding(.bottom, BCSpacing.xs)
            Text("Geen berichten")
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
            Text("Hier zie je join-verzoeken voor je team en updates over je teams.")
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, BCSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BCColors.background)
    }

    private func tint(for kind: InboxMessage.Kind) -> Color {
        switch kind {
        case .teamJoinApproved, .teamMilestone100, .competitionResult:
            return BCColors.success
        case .teamJoinRejected:
            return BCColors.danger
        case .neighborhoodNeedsYou, .helpReminder, .newTaskNearby:
            return BCColors.accentDark
        case .elderlyMessage:
            return BCColors.primary
        case .favoriteBuddy:
            return BCColors.danger
        case .teamJoinRequest, .teamMilestone75, .competitionEndingSoon, .competitionRankChange:
            return BCColors.primary
        // Zorgkring-pivot (fase35): uitnodigingen/verzoeken in de huisstijl-
        // kleur, roostermomenten in de aandacht-tint, spoed en excuses in rood.
        // De navigatie loopt gewoon via msg.destination (onTapGesture hieronder).
        case .teamInvite, .teamInviteReminder, .careJoinRequest, .teamReviewReady, .teamChoiceNeeded, .scheduleChanged:
            return BCColors.primary
        case .teamTaskNew, .slotNew, .slotReminder48, .slotReminder24, .slotUnfilled:
            return BCColors.accentDark
        case .slotUrgent, .noBuddyFound:
            return BCColors.danger
        // Teamchat & vervanging (fase36): chat in de huisstijlkleur, een
        // vervangingsvraag in de aandacht-tint, geregeld/herinnering in groen.
        case .teamChat:
            return BCColors.primary
        case .swapRequest:
            return BCColors.warning
        case .swapTaken, .shiftReminder:
            return BCColors.success
        case .generic:
            return BCColors.textSecondary
        }
    }

    private func relativeTime(_ date: Date) -> String {
        BCFormatters.relativeDateTime.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    InboxView().environment(AppState())
}
