//  AdminHelpers.swift
//  Verplaatst uit AdminTabView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(BCTypography.body)
                .foregroundStyle(BCColors.textSecondary)
            Spacer()
            Text(value)
                .font(BCTypography.bodyEmphasized)
                .foregroundStyle(BCColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, BCSpacing.sm)
    }
}

struct AdminRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BCColors.primary)
                    .frame(width: 32)
                Text(label)
                    .font(BCTypography.body)
                    .foregroundStyle(BCColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(BCColors.textTertiary)
            }
            .padding(.vertical, BCSpacing.md)
        }
        .buttonStyle(.plain)
    }
}
