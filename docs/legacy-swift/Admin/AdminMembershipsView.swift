import SwiftUI

struct AdminMembershipsView: View {
    @Environment(AppState.self) private var appState
    @State private var filterStatus: MembershipStatus? = .pending
    @State private var selectedMembership: OrganizationMembership? = nil
    @State private var rejectReason = ""
    @State private var showRejectSheet = false

    private var filtered: [OrganizationMembership] {
        guard let f = filterStatus else { return appState.allMemberships }
        return appState.allMemberships.filter { $0.status == f }
    }

    private var pendingCount: Int {
        appState.allMemberships.filter { $0.status == .pending }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(
                title: "Aanvragen",
                subtitle: pendingCount > 0 ? "\(pendingCount) wachten op beoordeling" : "Alle beoordeeld"
            )

            filterBar

            ScrollView {
                VStack(spacing: BCSpacing.sm) {
                    if filtered.isEmpty {
                        emptyState
                    } else {
                        ForEach(filtered) { membership in
                            MembershipCard(
                                membership: membership,
                                orgName: orgName(for: membership.organizationId)
                            ) {
                                appState.approveMembership(id: membership.id)
                            } onReject: {
                                selectedMembership = membership
                                showRejectSheet = true
                            }
                            .padding(.horizontal, BCSpacing.lg)
                        }
                    }
                }
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xl)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .sheet(isPresented: $showRejectSheet) {
            RejectSheet(reason: $rejectReason) {
                if let id = selectedMembership?.id {
                    appState.rejectMembership(id: id, reason: rejectReason)
                }
                rejectReason = ""
                showRejectSheet = false
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 0) {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BCSpacing.sm) {
                FilterChip(label: "Alles", count: appState.allMemberships.count,
                           isActive: filterStatus == nil) {
                    filterStatus = nil
                }
                FilterChip(label: "In behandeling",
                           count: appState.allMemberships.filter { $0.status == .pending }.count,
                           isActive: filterStatus == .pending) {
                    filterStatus = .pending
                }
                FilterChip(label: "Goedgekeurd",
                           count: appState.allMemberships.filter { $0.status == .approved }.count,
                           isActive: filterStatus == .approved) {
                    filterStatus = .approved
                }
                FilterChip(label: "Afgewezen",
                           count: appState.allMemberships.filter { $0.status == .rejected }.count,
                           isActive: filterStatus == .rejected) {
                    filterStatus = .rejected
                }
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.vertical, BCSpacing.sm)
        }
        .background(BCColors.surface)
        Divider()
        } // VStack
    }

    private var emptyState: some View {
        BCCard {
            BCEmptyState(
                icon: "checkmark.circle.fill",
                title: "Geen aanvragen",
                message: "Er zijn geen aanvragen gevonden voor dit filter."
            )
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    private func orgName(for id: UUID) -> String {
        appState.availableOrganizations.first { $0.id == id }?.name ?? "Onbekend"
    }
}

// MARK: - Membership Card

private struct MembershipCard: View {
    let membership: OrganizationMembership
    let orgName: String
    let onApprove: () -> Void
    let onReject: () -> Void

    private var dateFormatted: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMM yyyy 'om' HH:mm"
        return f.string(from: membership.submittedAt)
    }

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.md) {
                // Header
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(BCColors.primary.opacity(0.08))
                            .frame(width: 44, height: 44)
                        Text(initials)
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(membership.userName)
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                            .lineLimit(1)
                        Text("\(membership.userRole == .buddy ? "Buddy" : "Cliënt") · \(orgName)")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                    BCStatusPill(label: membership.status.displayLabel,
                                 color: membership.status.color,
                                 showDot: true)
                }

                // Bewijs en datum
                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(BCColors.textTertiary)
                    Text(membership.proofNote)
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }

                Text("Ingediend op \(dateFormatted)")
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)

                if let note = membership.adminNote {
                    HStack(spacing: BCSpacing.xs) {
                        Image(systemName: "bubble.left.fill")
                            .foregroundStyle(BCColors.textTertiary)
                        Text("Admin: \(note)")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                            .italic()
                    }
                }

                // Actieknoppen (alleen voor pending)
                if membership.status == .pending {
                    HStack(spacing: BCSpacing.md) {
                        Button(action: onReject) {
                            Text("Afwijzen")
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.danger)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                        .fill(BCColors.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                        .stroke(BCColors.danger.opacity(0.5), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: onApprove) {
                            Text("Goedkeuren")
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                        .fill(BCColors.success)
                                )
                                .bcSoftShadow(.subtle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var initials: String {
        membership.userName.split(separator: " ").compactMap(\.first).map(String.init).prefix(2).joined()
    }
}

private struct FilterChip: View {
    let label: String
    let count: Int
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.xs) {
                Text(label)
                    .font(BCTypography.captionEmphasized)
                Text("\(count)")
                    .font(BCTypography.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(isActive ? .white.opacity(0.25) : BCColors.surfaceMuted))
            }
            .foregroundStyle(isActive ? .white : BCColors.textSecondary)
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(Capsule().fill(isActive ? BCColors.primary : BCColors.surface))
            .overlay(Capsule().stroke(isActive ? Color.clear : BCColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Afwijzen sheet

private struct RejectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var reason: String
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: BCSpacing.md) {
                Text("Geef optioneel een reden op voor de afwijzing. Deze reden is intern en wordt niet gedeeld met de aanvrager.")
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textSecondary)
                    .multilineTextAlignment(.leading)

                BCCard {
                    TextField("Bijv. onleesbaar document...", text: $reason, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .font(BCTypography.body)
                        .foregroundStyle(BCColors.textPrimary)
                }

                Spacer()
            }
            .padding(BCSpacing.lg)
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Aanvraag afwijzen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bevestig") { onConfirm() }
                        .font(BCTypography.bodyEmphasized)
                        .tint(BCColors.danger)
                }
            }
        }
    }
}

#Preview {
    AdminMembershipsView().environment(AppState())
}
