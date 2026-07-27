//  AchievementsView.swift
//  Verplaatst uit BuddyPoolView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct AchievementsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var categories: [AchievementCategory] = []
    @State private var selected = 0
    @State private var shownTotal = 0
    @State private var total = 0
    @State private var totalUnlocked = 0

    private let columns = [GridItem(.flexible(), spacing: BCSpacing.md),
                           GridItem(.flexible(), spacing: BCSpacing.md),
                           GridItem(.flexible(), spacing: BCSpacing.md)]

    private var category: AchievementCategory? {
        categories.indices.contains(selected) ? categories[selected] : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    hero
                    categoryPicker
                    if let category {
                        nextMedalCard(category)
                        medalsGrid(category)
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.md)
                .padding(.bottom, BCSpacing.xxl)
            }
            .background(BCColors.background)
            .navigationTitle("Prestaties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Sluit") { dismiss() }.tint(BCColors.primary) } }
        }
        .onAppear(perform: setup)
    }

    private func setup() {
        guard categories.isEmpty else { return }
        let stats = GameStatsProvider.make(for: appState.buddyUser)
        categories = AchievementData.categories(for: appState.buddyUser, stats: stats)
        totalUnlocked = categories.reduce(0) { $0 + $1.unlockedCount }
        total = categories.reduce(0) { $0 + $1.thresholds.count }
        withAnimation(.easeOut(duration: 1.2)) { shownTotal = totalUnlocked }
    }

    // Hero
    private var hero: some View {
        VStack(spacing: BCSpacing.md) {
            HStack {
                Text("JOUW PRESTATIES").font(BCTypography.captionEmphasized).tracking(1.4).foregroundStyle(.white.opacity(0.85))
                Spacer()
                Image(systemName: "rosette").font(.system(size: 16, weight: .bold)).foregroundStyle(.white.opacity(0.9))
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(shownTotal)").font(BCFont.heading(50, .heavy)).foregroundStyle(.white).contentTransition(.numericText())
                Text("van \(total) medailles").font(BCTypography.subheadline).foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.25))
                    Capsule().fill(.white)
                        .frame(width: total > 0 ? geo.size.width * (Double(shownTotal) / Double(total)) : 0)
                }
            }
            .frame(height: 8)
        }
        .padding(BCSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.90, green: 0.70, blue: 0.20), Color(red: 0.80, green: 0.45, blue: 0.15)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .bcSoftShadow(.raised)
    }

    // Categorie-kiezer (horizontaal)
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BCSpacing.sm) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { idx, cat in
                    let active = idx == selected
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { selected = idx }
                    } label: {
                        HStack(spacing: 7) {
                            AppIcon(name: cat.icon, size: 16)
                            Text(cat.title).font(BCTypography.captionEmphasized)
                                .foregroundStyle(active ? .white : BCColors.textSecondary)
                        }
                        .padding(.horizontal, BCSpacing.md)
                        .padding(.vertical, 9)
                        .background(
                            Capsule(style: .continuous).fill(
                                active ? AnyShapeStyle(LinearGradient(colors: cat.tint, startPoint: .leading, endPoint: .trailing))
                                       : AnyShapeStyle(BCColors.surface))
                        )
                        .overlay(Capsule().stroke(active ? .clear : BCColors.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // Voortgang naar volgende medaille
    private func nextMedalCard(_ cat: AchievementCategory) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            if let next = cat.nextThreshold {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Volgende medaille").font(BCTypography.captionEmphasized).foregroundStyle(BCColors.textSecondary)
                        Text("\(next) \(cat.unit)").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                    }
                    Spacer()
                    Text("\(cat.current) / \(next)").font(BCTypography.captionEmphasized).foregroundStyle(BCColors.textTertiary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(BCColors.surfaceMuted)
                        Capsule().fill(LinearGradient(colors: cat.tint, startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * min(1, Double(cat.current) / Double(next)))
                    }
                }
                .frame(height: 8)
                Text("Nog \(next - cat.current) \(cat.unit) tot je volgende medaille.")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(BCColors.success)
                    Text("Alle medailles in deze categorie behaald! 🎉").font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                }
            }
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }

    // Medaille-grid
    private func medalsGrid(_ cat: AchievementCategory) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            HStack {
                Text(cat.title).font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                Spacer()
                Text("\(cat.unlockedCount)/\(cat.thresholds.count)").font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
            }
            LazyVGrid(columns: columns, spacing: BCSpacing.lg) {
                ForEach(Array(cat.medals.enumerated()), id: \.element.id) { idx, medal in
                    MedalBadge(medal: medal, unit: cat.unit, index: idx)
                }
            }
        }
    }
}
