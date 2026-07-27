//  BCFormFields.swift
//  Verplaatst uit BCComponents.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

/// Sheet met de intrekbare toestemmingen, geopend vanuit de "Privacy & gegevens"-rij.
struct PrivacyConsentSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.md) {
                    Text("Jij beslist. We delen alleen anonieme, geaggregeerde cijfers, nooit je naam, adres of gezondheidsgegevens. Je kunt dit op elk moment wijzigen.")
                        .font(BCTypography.subheadline)
                        .foregroundStyle(BCColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    BCInsetCard {
                        BCProfileToggleRow(
                            title: "Help de app verbeteren",
                            subtitle: "Anonieme gebruiksstatistieken.",
                            isOn: Binding(
                                get: { appState.consentProductAnalytics },
                                set: { appState.recordConsent(productAnalytics: $0,
                                                              researchInsights: appState.consentResearchInsights) }
                            )
                        )
                        BCHairline()
                        BCProfileToggleRow(
                            title: "Welzijnsinzichten delen",
                            subtitle: "Geaggregeerd en anoniem, nooit herleidbaar tot jou.",
                            isOn: Binding(
                                get: { appState.consentResearchInsights },
                                set: { appState.recordConsent(productAnalytics: appState.consentProductAnalytics,
                                                              researchInsights: $0) }
                            )
                        )
                    }

                    Text("Uitzetten stopt het verzamelen direct.")
                        .font(BCTypography.caption)
                        .foregroundStyle(BCColors.textTertiary)
                }
                .padding(BCSpacing.lg)
            }
            .background(BCColors.background.ignoresSafeArea())
            .navigationTitle("Privacy & gegevens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klaar") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
    }
}

/// Optioneel geboortedatum-veld. `date` blijft nil zolang er niets is ingevuld;
/// dan toont het een "Invullen"-knop. Zodra er een datum is, verschijnt een
/// volledige datumkiezer (dag, maand én jaar) zodat de leeftijd exact klopt.
struct BirthDateField: View {
    @Binding var date: Date?
    var font: Font = BCTypography.body

    private var range: ClosedRange<Date> {
        let cal = Calendar.current
        let now = Date()
        let earliest = cal.date(from: DateComponents(year: 1900, month: 1, day: 1)) ?? now
        return earliest...now
    }

    private var defaultDate: Date {
        Calendar.current.date(from: DateComponents(year: 1950, month: 1, day: 1)) ?? Date()
    }

    var body: some View {
        if let bound = Binding($date) {
            HStack(spacing: BCSpacing.sm) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BCColors.textTertiary)
                DatePicker("", selection: bound, in: range, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "nl_NL"))
                Spacer()
                Button {
                    date = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(BCColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(BCSpacing.md)
            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.border, lineWidth: 1))
        } else {
            Button {
                date = defaultDate
            } label: {
                HStack(spacing: BCSpacing.sm) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Geboortedatum invullen")
                        .font(font)
                    Spacer()
                }
                .foregroundStyle(BCColors.primary)
                .padding(BCSpacing.md)
                .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(BCColors.surface))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(BCColors.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}
