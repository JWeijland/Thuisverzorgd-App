//  RequestHelpTiles.swift
//  Verplaatst uit RequestHelpFlow.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct CategoryTile: View {
    @Environment(\.largeTextEnabled) private var largeText
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        Button(action: action) {
            if largeText {
                // Large: horizontal layout for 1-column rows
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(BCColors.navy900.opacity(0.08))
                        AppIcon(name: category.brandIcon, size: 40)
                    }
                    .frame(width: 68, height: 68)
                    Text(category.displayName)
                        .font(et.button)
                        .foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(BCColors.navy700)
                    }
                }
                .padding(BCSpacing.md)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).stroke(isSelected ? BCColors.navy700 : Color.clear, lineWidth: 2))
                .bcSoftShadow(.card)
            } else {
                // Normal: vertical layout for 2-column grid
                VStack(spacing: BCSpacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(BCColors.navy900.opacity(0.08))
                        AppIcon(name: category.brandIcon, size: 32)
                    }
                    .frame(width: 56, height: 56)
                    Text(category.displayName)
                        .font(BCTypography.bodyEmphasized)
                        .foregroundStyle(BCColors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(BCSpacing.md)
                .frame(maxWidth: .infinity, minHeight: 130)
                .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).stroke(isSelected ? BCColors.navy700 : Color.clear, lineWidth: 2))
                .bcSoftShadow(.card)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TimingTile: View {
    @Environment(\.largeTextEnabled) private var largeText
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    private var et: BCElderlyType { BCElderlyType(large: largeText) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                        .fill(isSelected ? BCColors.navy900 : BCColors.navy900.opacity(0.08))
                    Image(systemName: icon)
                        .font(.system(size: largeText ? 28 : 22, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : BCColors.navy700)
                }
                .frame(width: largeText ? 60 : 48, height: largeText ? 60 : 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(et.body)
                        .foregroundStyle(BCColors.textPrimary)
                    if !largeText {
                        Text(subtitle)
                            .font(et.caption)
                            .foregroundStyle(BCColors.textSecondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: largeText ? 28 : 22, weight: .semibold))
                        .foregroundStyle(BCColors.navy700)
                }
            }
            .padding(largeText ? BCSpacing.lg : BCSpacing.md)
            .frame(maxWidth: .infinity, minHeight: largeText ? 88 : 72)
            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
            .overlay(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).stroke(isSelected ? BCColors.navy700 : Color.clear, lineWidth: 2))
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BCColors.primary)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textSecondary)
                Text(value)
                    .font(BCTypography.bodyEmphasized)
                    .foregroundStyle(BCColors.textPrimary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
