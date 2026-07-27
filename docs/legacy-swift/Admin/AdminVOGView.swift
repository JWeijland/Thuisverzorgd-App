//  AdminVOGView.swift
//  Verplaatst uit AdminTabView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct AdminVOGView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "VOG-controle", subtitle: "Buddies verifiëren")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    if !appState.isLive {
                        BCCard {
                            Text("VOG-controle werkt alleen wanneer je echt bent ingelogd (live-modus). In demo zijn er geen echte aanvragen.")
                                .font(BCTypography.body)
                                .foregroundStyle(BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.lg)
                    } else if appState.pendingVOGs.isEmpty {
                        BCEmptyState(
                            icon: "checkmark.shield",
                            title: "Niets te controleren",
                            message: "Er staan geen VOG-aanvragen of uploads open."
                        )
                        .padding(.top, BCSpacing.xl)
                    } else {
                        ForEach(appState.pendingVOGs) { item in
                            vogCard(item)
                        }
                    }
                    Spacer().frame(height: BCSpacing.xl)
                }
                .padding(.top, BCSpacing.md)
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .onAppear { appState.adminLoadPendingVOGs() }
        .refreshable { appState.adminLoadPendingVOGs() }
    }

    private func vogCard(_ item: ProfileService.PendingVOG) -> some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack {
                    Text(item.name.isEmpty ? "Buddy" : item.name)
                        .font(BCTypography.headline)
                        .foregroundStyle(BCColors.textPrimary)
                    Spacer()
                    BCStatusPill(
                        label: VOGStatus(rawValue: item.vogStatus)?.label ?? item.vogStatus,
                        color: BCColors.warning,
                        showDot: true
                    )
                }

                if let path = item.vogDocumentUrl, !path.isEmpty {
                    Button {
                        Task {
                            if let url = try? await ProfileService().vogSignedURL(path: path) {
                                openURL(url)
                            }
                        }
                    } label: {
                        Label("Bekijk geüpload document", systemImage: "doc.text.magnifyingglass")
                            .font(BCTypography.subheadline)
                            .foregroundStyle(BCColors.primary)
                    }
                } else {
                    Text("Aanvraag via Thuisverzorgd: controleer in het Justis-portaal en keur daarna goed.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textSecondary)
                }

                HStack(spacing: BCSpacing.sm) {
                    Button {
                        appState.adminApproveVOG(buddyId: item.id)
                    } label: {
                        Text("Goedkeuren")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Capsule().fill(BCColors.success))
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        appState.adminRejectVOG(buddyId: item.id)
                    } label: {
                        Text("Afwijzen")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(BCColors.danger)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Capsule().stroke(BCColors.danger, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}
