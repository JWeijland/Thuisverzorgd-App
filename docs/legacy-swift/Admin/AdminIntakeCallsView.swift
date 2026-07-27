//  AdminIntakeCallsView.swift
//  Verplaatst uit AdminTabView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct AdminIntakeCallsView: View {
    @Environment(AppState.self) private var appState
    @State private var videoCall: ProfileService.DBIntakeCall?

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Live intake", subtitle: "Inkomende videogesprekken")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    if !appState.isLive {
                        BCCard {
                            Text("Live intake-gesprekken werken alleen wanneer je echt bent ingelogd (live-modus).")
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else if appState.waitingCalls.isEmpty && appState.scheduledCalls.isEmpty {
                        BCEmptyState(
                            icon: "video.slash",
                            title: "Geen gesprekken",
                            message: "Er staat niemand in de wachtrij en er zijn geen ingeplande gesprekken. Nieuwe gesprekken verschijnen hier vanzelf."
                        )
                        .padding(.top, BCSpacing.xl)
                    } else {
                        // Ingeplande gesprekken (zelf gekozen moment).
                        if !appState.scheduledCalls.isEmpty {
                            sectionHeader("Planning", subtitle: "Ingeplande gesprekken")
                            ForEach(appState.scheduledCalls) { call in
                                scheduledCard(call)
                            }
                        }
                        // Live-wachtrij.
                        sectionHeader("Wachtrij", subtitle: "Live gesprekken")
                        if appState.waitingCalls.isEmpty {
                            Text("Er staat nu niemand in de live-wachtrij.")
                                .font(BCTypography.caption)
                                .foregroundStyle(BCColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, BCSpacing.lg)
                        } else {
                            ForEach(appState.waitingCalls) { call in
                                callCard(call)
                            }
                        }
                    }
                    Spacer().frame(height: BCSpacing.xl)
                }
                .padding(.top, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .onAppear { refresh() }
        .refreshable { refresh() }
        .fullScreenCover(item: $videoCall) { call in
            IntakeVideoView(
                callId: call.id,
                isAdmin: true,
                onApprove: { appState.adminApproveIntakeAndEndCall(call); videoCall = nil },
                onReject: { appState.adminRejectBuddyAndEndCall(call); videoCall = nil },
                onEnd: { videoCall = nil }
            )
        }
    }

    private func refresh() {
        appState.adminRefreshWaitingCalls()
        appState.adminRefreshScheduledCalls()
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: BCSpacing.sm) {
            Text(title)
                .font(BCTypography.captionEmphasized)
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(BCColors.textTertiary)
            Text(subtitle)
                .font(BCTypography.caption)
                .foregroundStyle(BCColors.textTertiary.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, BCSpacing.lg)
        .padding(.top, BCSpacing.sm)
    }

    /// Kaart voor een zelf-ingepland gesprek: naam, datum/tijd en openen.
    private func scheduledCard(_ call: ProfileService.DBIntakeCall) -> some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack {
                    ZStack {
                        Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 44, height: 44)
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(BCColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(call.name.isEmpty ? "Buddy" : call.name)
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                        Text(call.scheduledDate.map { Self.planFormatter.string(from: $0) } ?? "Gepland")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    Spacer()
                    BCStatusPill(label: "Ingepland", color: BCColors.primary, showDot: true)
                }
                Button {
                    appState.adminAnswerCall(call)
                    videoCall = call
                } label: {
                    HStack(spacing: BCSpacing.sm) {
                        Image(systemName: "video.fill")
                        Text("Open gesprek")
                    }
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Capsule().fill(BCColors.primary))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }

    private static let planFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEEE d MMM, HH:mm"
        return f
    }()

    private func callCard(_ call: ProfileService.DBIntakeCall) -> some View {
        let inProgress = call.status == "in_progress"
        return BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack {
                    ZStack {
                        Circle().fill(BCColors.primary.opacity(0.10)).frame(width: 44, height: 44)
                        Image(systemName: "person.fill")
                            .foregroundStyle(BCColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(call.name.isEmpty ? "Buddy" : call.name)
                            .font(BCTypography.headline)
                            .foregroundStyle(BCColors.textPrimary)
                        Text(inProgress ? "In gesprek" : "Wacht op antwoord")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    Spacer()
                    BCStatusPill(
                        label: inProgress ? "In gesprek" : "Wachtrij",
                        color: inProgress ? BCColors.success : BCColors.warning,
                        showDot: true
                    )
                }

                if inProgress {
                    Button {
                        videoCall = call
                    } label: {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "video.fill")
                            Text("Open videogesprek")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Capsule().fill(BCColors.primary))
                    }
                    .buttonStyle(.plain)
                    Button {
                        appState.adminApproveIntakeAndEndCall(call)
                    } label: {
                        Text("Keur intake goed")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Capsule().fill(BCColors.success))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: BCSpacing.sm) {
                        Button {
                            appState.adminRejectBuddyAndEndCall(call)
                        } label: {
                            Text("Afwijzen")
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Capsule().fill(BCColors.danger))
                        }
                        .buttonStyle(.plain)
                        Button {
                            appState.adminEndCall(call)
                        } label: {
                            Text("Beëindig")
                                .font(BCTypography.bodyEmphasized)
                                .foregroundStyle(BCColors.textSecondary)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Capsule().stroke(BCColors.border, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        appState.adminAnswerCall(call)
                        videoCall = call
                    } label: {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "video.fill")
                            Text("Opnemen")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Capsule().fill(BCColors.primary))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}
