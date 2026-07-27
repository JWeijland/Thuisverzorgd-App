//  AdminCodesView.swift
//  Verplaatst uit AdminTabView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct AdminCodesView: View {
    @Environment(AppState.self) private var appState
    @State private var showGenerate = false

    var body: some View {
        VStack(spacing: 0) {
            BCNavBar(title: "Koppelcodes", subtitle: "Voor gemeenten, verzekeraars & werkgevers")
            ScrollView {
                VStack(spacing: BCSpacing.md) {
                    Button {
                        showGenerate = true
                    } label: {
                        HStack(spacing: BCSpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                            Text("Nieuwe koppelcode genereren")
                        }
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.primary))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, BCSpacing.lg)
                    .padding(.top, BCSpacing.md)

                    ForEach(appState.partnerCodes) { pc in
                        CodeCard(code: pc) {
                            appState.deactivatePartnerCode(id: pc.id)
                        }
                    }

                    if appState.partnerCodes.isEmpty {
                        BCEmptyState(icon: "qrcode",
                                     title: "Nog geen koppelcodes",
                                     message: "Genereer er één voor een partner.")
                            .padding(.top, BCSpacing.xl)
                    }

                    Spacer().frame(height: BCSpacing.xl)
                }
            }
        }
        .background(BCColors.background.ignoresSafeArea())
        .sheet(isPresented: $showGenerate) {
            GenerateCodeSheet()
        }
    }
}

struct CodeCard: View {
    let code: PartnerCode
    let onDeactivate: () -> Void

    var body: some View {
        BCCard {
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        Circle().fill(BCColors.primary.opacity(0.08)).frame(width: 44, height: 44)
                        Image(systemName: code.partnerType.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(BCColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(code.code)
                            .font(BCTypography.title3)
                            .foregroundStyle(BCColors.textPrimary)
                        Text("\(code.partnerName) · \(code.partnerType.displayName)")
                            .font(BCTypography.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                    Spacer()
                    BCStatusPill(label: code.statusLabel, color: code.statusColor, showDot: true)
                }
                HStack {
                    Label(code.usesLabel, systemImage: "person.2.fill")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                    Spacer()
                    if code.isActive {
                        Button("Intrekken", role: .destructive, action: onDeactivate)
                            .font(BCTypography.captionEmphasized)
                            .tint(BCColors.danger)
                    }
                }
            }
        }
        .padding(.horizontal, BCSpacing.lg)
    }
}

struct GenerateCodeSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var partnerName: String = ""
    @State private var partnerType: PartnerType = .gemeente
    @State private var limitUses: Bool = false
    @State private var maxUses: Int = 100
    @State private var hasExpiry: Bool = false
    @State private var expiryDate: Date = Date().addingTimeInterval(86400 * 365)

    var body: some View {
        NavigationStack {
            Form {
                Section("Partner") {
                    TextField("Naam, bijv. Gemeente Zeist", text: $partnerName)
                    Picker("Type", selection: $partnerType) {
                        ForEach(PartnerType.allCases) { t in
                            Label(t.displayName, systemImage: t.icon).tag(t)
                        }
                    }
                }
                Section("Gebruikslimiet") {
                    Toggle("Maximaal aantal gebruiken", isOn: $limitUses)
                    if limitUses {
                        Stepper("Max. \(maxUses) keer", value: $maxUses, in: 1...10000, step: 10)
                    }
                }
                Section("Geldigheid") {
                    Toggle("Verloopdatum instellen", isOn: $hasExpiry)
                    if hasExpiry {
                        DatePicker("Verloopt op", selection: $expiryDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Koppelcode genereren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuleer") { dismiss() }.tint(BCColors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Genereer") {
                        appState.generatePartnerCode(
                            partnerName: partnerName,
                            partnerType: partnerType,
                            maxUses: limitUses ? maxUses : nil,
                            expiresAt: hasExpiry ? expiryDate : nil
                        )
                        dismiss()
                    }
                    .font(BCTypography.bodyEmphasized)
                    .tint(BCColors.primary)
                }
            }
        }
    }
}
