//  BuddyPoolComponents.swift
//  Verplaatst uit BuddyPoolView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(BCTypography.captionEmphasized)
            .tracking(1.4)
            .foregroundStyle(BCColors.textTertiary)
    }
}

struct PointsHero: View {
    let points: Int
    let subtitle: String
    let stats: GameStats
    let tint: [Color]
    var showsChevron: Bool = false
    var prizeLine: String? = nil

    @State private var shown = 0
    @State private var flame = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.md) {
            HStack {
                Text("JOUW COMPETITIEPUNTEN")
                    .font(BCTypography.captionEmphasized).tracking(1.4)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 34, height: 34)
                    Image(systemName: "trophy.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(shown)")
                    .font(BCFont.heading(56, .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .scaleEffect(appeared ? 1.0 : 0.92, anchor: .bottomLeading)
                Text("punten")
                    .font(BCTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            HStack(spacing: 6) {
                Image(systemName: "flag.checkered").font(.system(size: 11, weight: .bold))
                Text(subtitle).font(BCTypography.caption)
            }
            .foregroundStyle(.white.opacity(0.9))

            if let prizeLine {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill").font(.system(size: 11, weight: .bold))
                    Text("1e prijs: \(prizeLine)").font(BCTypography.caption).lineLimit(1)
                }
                .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: BCSpacing.sm) {
                GlassStat(icon: "flame.fill", value: "\(stats.streakDays)", label: "dagen streak", iconScale: flame ? 1.18 : 1.0)
                GlassStat(icon: "bolt.fill", value: "×\(formatMultiplier(stats.multiplier))", label: "vandaag")
                GlassStat(icon: "checkmark.circle.fill", value: "\(stats.todayCount)", label: "vandaag")
            }
            .padding(.top, 2)

            if showsChevron {
                HStack(spacing: 4) {
                    Text("Bekijk competitie").font(BCTypography.captionEmphasized)
                    Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(BCSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                .fill(LinearGradient(colors: tint, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .bcSoftShadow(.raised)
        .onAppear { animateIn() }
        .onChange(of: points) { _, _ in animateIn() }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
        withAnimation(.easeOut(duration: 1.1)) { shown = points }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { flame = true }
    }
}

struct GlassStat: View {
    let icon: String
    let value: String
    let label: String
    var iconScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold)).scaleEffect(iconScale)
                Text(value).font(BCFont.heading(17, .heavy))
            }
            .foregroundStyle(.white)
            Text(label).font(BCTypography.caption).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(.white.opacity(0.16)))
    }
}

struct MultiplierStrip: View {
    let todayCount: Int
    private let steps: [(n: Int, m: Double, label: String)] = [(1, 1.0, "1e"), (2, 1.5, "2e"), (3, 2.0, "3e"), (4, 3.0, "4e+")]

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(BCColors.warning)
                Text("Vandaag-multiplier").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
            }
            Text("Hoe meer hulpvragen je op één dag doet, hoe hoger je multiplier.")
                .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
            HStack(spacing: BCSpacing.sm) {
                ForEach(steps, id: \.n) { step in
                    let active = todayCount >= step.n
                    VStack(spacing: 3) {
                        Text("×\(formatMultiplier(step.m))")
                            .font(BCFont.heading(17, .heavy))
                            .foregroundStyle(active ? .white : BCColors.textSecondary)
                        Text(step.label)
                            .font(BCTypography.caption)
                            .foregroundStyle(active ? .white.opacity(0.9) : BCColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                            .fill(active
                                  ? AnyShapeStyle(LinearGradient(colors: [BCColors.warning, BCColors.accentDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(BCColors.surfaceMuted))
                    )
                    .scaleEffect(active ? 1.0 : 0.96)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: active)
                }
            }
        }
        .padding(BCSpacing.md)
        .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
        .bcSoftShadow(.card)
    }
}

struct TeamPointsHero: View {
    let team: Team
    let contribution: Int
    @State private var shown = 0

    var body: some View {
        VStack(spacing: BCSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("JOUW TEAM").font(BCTypography.captionEmphasized).tracking(1.4).foregroundStyle(.white.opacity(0.85))
                    Text(team.name).font(BCFont.heading(22, .heavy)).foregroundStyle(.white)
                    HStack(spacing: 5) {
                        Image(systemName: "gift.fill").font(.system(size: 11, weight: .bold))
                        Text(team.prizeDisplay).font(BCTypography.caption).lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 2)
                }
                Spacer()
                ProgressRing(fraction: team.fraction, colors: [.white, .white.opacity(0.7)], lineWidth: 8, track: .white.opacity(0.25))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text("\(Int(team.fraction * 100))%").font(BCFont.heading(15, .heavy)).foregroundStyle(.white)
                    }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(shown)").font(BCFont.heading(46, .heavy)).foregroundStyle(.white).contentTransition(.numericText())
                Text("teampunten").font(BCTypography.caption).foregroundStyle(.white.opacity(0.85))
                Spacer()
            }

            HStack(spacing: BCSpacing.sm) {
                GlassStat(icon: "person.fill", value: "\(contribution)", label: "jouw bijdrage")
                GlassStat(icon: "gift.fill", value: "\(team.pointsToGo)", label: "tot het uitje")
                GlassStat(icon: "person.3.fill", value: "\(team.members.count)", label: "maatjes")
            }

            HStack(spacing: 4) {
                Text("Bekijk team").font(BCTypography.captionEmphasized)
                Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(BCSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BCRadius.xl, style: .continuous)
                .fill(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .bcSoftShadow(.raised)
        .onAppear { withAnimation(.easeOut(duration: 1.2)) { shown = team.totalPoints } }
    }
}

struct CompetitionRow: View {
    let c: Competition
    init(competition: Competition) { self.c = competition }

    var body: some View {
        HStack(spacing: BCSpacing.md) {
            ZStack {
                Circle().stroke(LinearGradient(colors: c.tint, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5).frame(width: 42, height: 42)
                Image(systemName: c.icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(c.tint.first ?? BCColors.primary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(c.name).font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                StatusTag(status: c.status, deadline: c.deadline, weeksRemaining: c.weeksRemaining)
                if let topPrize = c.prizes.first(where: { $0.rank == 1 }) ?? c.prizes.first {
                    HStack(spacing: 5) {
                        Image(systemName: "trophy.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(Podium.medalColor(1))
                        Text("1e prijs: \(topPrize.title)").font(BCTypography.caption).foregroundStyle(BCColors.textSecondary).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(BCColors.textTertiary)
        }
        .padding(.vertical, BCSpacing.md).contentShape(Rectangle())
    }
}

struct StatusTag: View {
    let status: CompetitionStatus
    let deadline: Date
    let weeksRemaining: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
        }
    }
    private var color: Color {
        switch status {
        case .inschrijving: return BCColors.warning
        case .loopt: return BCColors.success
        case .afgelopen: return BCColors.textTertiary
        }
    }
    private var text: String {
        switch status {
        case .inschrijving:
            let d = max(0, Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0)
            return d <= 0 ? "Inschrijving sluit vandaag" : "Inschrijven kan nog \(d) dag\(d == 1 ? "" : "en")"
        case .loopt: return "Loopt · nog \(weeksRemaining) week\(weeksRemaining == 1 ? "" : "en")"
        case .afgelopen: return "Afgelopen"
        }
    }
}

struct TeamRow: View {
    let team: Team
    var rank: Int? = nil

    var body: some View {
        HStack(spacing: BCSpacing.md) {
            if let rank {
                Text("\(rank)").font(BCFont.heading(16, .semibold))
                    .foregroundStyle(rank <= 3 ? Podium.medalColor(rank) : BCColors.textTertiary).frame(width: 22)
            }
            ZStack {
                Circle().stroke(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5).frame(width: 42, height: 42)
                Image(systemName: team.icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(team.tint.first ?? BCColors.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(team.name).font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                    if team.isMyTeam { Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundStyle(BCColors.success) }
                }
                Text("\(team.members.count) maatjes").font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
            }
            Spacer(minLength: 0)
            Text("\(team.totalPoints)").font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
            Text("pt").font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(BCColors.textTertiary).padding(.leading, 2)
        }
        .padding(.vertical, BCSpacing.md).contentShape(Rectangle())
    }
}

struct PrizesList: View {
    let prizes: [CompetitionPrize]
    var awarded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            Text(awarded ? "Beloond" : "Te winnen").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
            VStack(spacing: 0) {
                ForEach(Array(prizes.sorted { $0.rank < $1.rank }.enumerated()), id: \.element.id) { idx, p in
                    HStack(spacing: BCSpacing.md) {
                        ZStack {
                            Circle().fill(Podium.medalColor(p.rank).opacity(0.16)).frame(width: 38, height: 38)
                            Text("\(p.rank)").font(BCFont.heading(16, .heavy)).foregroundStyle(Podium.medalColor(p.rank))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(p.title).font(p.rank == 1 ? BCTypography.bodyEmphasized : BCTypography.body).foregroundStyle(BCColors.textPrimary)
                            Text(ordinaal(p.rank) + " prijs").font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: p.icon).font(.system(size: 18, weight: .medium)).foregroundStyle(Podium.medalColor(p.rank))
                    }
                    .padding(.vertical, BCSpacing.sm + 2)
                    if idx < prizes.count - 1 { Divider().overlay(BCColors.border).padding(.leading, 50) }
                }
            }
        }
    }
    private func ordinaal(_ n: Int) -> String { n == 1 ? "1e" : (n == 2 ? "2e" : "\(n)e") }
}

struct MembersBoard: View {
    let members: [PoolMember]
    let tint: Color
    private var top3: [PoolMember] { Array(members.prefix(3)) }
    private var rest: [PoolMember] { Array(members.dropFirst(3)) }

    var body: some View {
        VStack(spacing: BCSpacing.lg) {
            if top3.count == 3 {
                Podium(first: top3[0], second: top3[1], third: top3[2], tint: tint)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(top3.enumerated()), id: \.element.id) { idx, m in
                        LeaderRow(rank: idx + 1, member: m, tint: tint)
                        if idx < top3.count - 1 { Divider().overlay(BCColors.border).padding(.leading, 44) }
                    }
                }
            }
            if !rest.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(rest.enumerated()), id: \.element.id) { idx, m in
                        LeaderRow(rank: idx + 4, member: m, tint: tint)
                        if idx < rest.count - 1 { Divider().overlay(BCColors.border).padding(.leading, 44) }
                    }
                }
            }
        }
    }
}

struct Podium: View {
    let first: PoolMember
    let second: PoolMember
    let third: PoolMember
    let tint: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: BCSpacing.lg) {
            avatar(second, rank: 2, size: 60)
            avatar(first, rank: 1, size: 78)
            avatar(third, rank: 3, size: 60)
        }
        .frame(maxWidth: .infinity)
    }

    private func avatar(_ m: PoolMember, rank: Int, size: CGFloat) -> some View {
        VStack(spacing: 6) {
            if rank == 1 { AppIcon(name: "tv-kroon", size: 20) }
            else { Spacer().frame(height: 20) }
            ZStack {
                MemberAvatar(member: m, size: size, tint: tint)
                Circle().stroke(Podium.medalColor(rank), lineWidth: 2.5).frame(width: size, height: size)
                Text("\(rank)").font(BCTypography.captionEmphasized).foregroundStyle(.white)
                    .frame(width: 20, height: 20).background(Circle().fill(Podium.medalColor(rank))).offset(y: size * 0.42)
            }
            Text(m.isCurrentUser ? "\(m.name) (jij)" : m.name).font(BCTypography.captionEmphasized).foregroundStyle(BCColors.textPrimary).lineLimit(1).padding(.top, 4)
            Text("\(m.points) pt").font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
        }
    }

    static func medalColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 0.85, green: 0.65, blue: 0.13)
        case 2: return Color(red: 0.62, green: 0.66, blue: 0.72)
        default: return Color(red: 0.74, green: 0.48, blue: 0.28)
        }
    }
}

struct LeaderRow: View {
    let rank: Int
    let member: PoolMember
    let tint: Color

    var body: some View {
        HStack(spacing: BCSpacing.md) {
            Text("\(rank)").font(BCFont.heading(16, .semibold)).foregroundStyle(BCColors.textTertiary).frame(width: 28)
            MemberAvatar(member: member, size: 34, tint: tint)
            Text(member.isCurrentUser ? "\(member.name) (jij)" : member.name)
                .font(member.isCurrentUser ? BCTypography.bodyEmphasized : BCTypography.body).foregroundStyle(BCColors.textPrimary)
            Spacer(minLength: 0)
            Text("\(member.points)").font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
            Text("pt").font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
        }
        .padding(.vertical, BCSpacing.sm + 2)
        .overlay(alignment: .leading) {
            if member.isCurrentUser {
                Capsule().fill(tint).frame(width: 3, height: 22).offset(x: -BCSpacing.md)
            }
        }
    }
}

struct ProgressRing: View {
    var fraction: Double
    var colors: [Color]
    var lineWidth: CGFloat = 10
    var track: Color = BCColors.surfaceMuted
    @State private var animated = false

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle().trim(from: 0, to: animated ? fraction : 0)
                .stroke(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onAppear { withAnimation(.easeOut(duration: 1.0)) { animated = true } }
    }
}

struct GameMapButton: View {
    let icon: String
    let tint: [Color]
    let value: String
    var action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(tint.last!.opacity(0.22)).frame(width: 54, height: 54)
                        .scaleEffect(pulse ? 1.45 : 1.0).opacity(pulse ? 0 : 0.5)
                    Circle().fill(BCColors.surface).frame(width: 50, height: 50).shadow(color: BCColors.primaryDark.opacity(0.18), radius: 8, y: 3)
                    Circle().stroke(LinearGradient(colors: tint, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2).frame(width: 50, height: 50)
                    Image(icon).renderingMode(.original).resizable().scaledToFit().frame(width: 28, height: 28)
                }
                Text(value)
                    .font(BCTypography.captionEmphasized).foregroundStyle(BCColors.navy900)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(BCColors.surface))
                    .shadow(color: BCColors.primaryDark.opacity(0.12), radius: 3, y: 1)
            }
        }
        .buttonStyle(.plain)
        .onAppear { withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

struct MedalBadge: View {
    let medal: Medal
    let unit: String
    let index: Int
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(medal.unlocked
                          ? AnyShapeStyle(LinearGradient(colors: medal.tier.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(BCColors.surfaceMuted))
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(.white.opacity(medal.unlocked ? 0.5 : 0), lineWidth: 1.5).padding(5))
                    .shadow(color: medal.unlocked ? medal.tier.colors.last!.opacity(0.45) : .clear, radius: 7, y: 3)
                if medal.unlocked {
                    Text("\(medal.threshold)").font(BCFont.heading(20, .heavy)).foregroundStyle(.white)
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 20, weight: .semibold)).foregroundStyle(BCColors.textTertiary)
                }
            }
            Text(medal.unlocked ? medal.tier.name : "\(medal.threshold)")
                .font(BCTypography.captionEmphasized)
                .foregroundStyle(medal.unlocked ? BCColors.textPrimary : BCColors.textTertiary)
            Text(unit).font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(min(index, 12)) * 0.04)) { appeared = true }
        }
    }
}

struct CreateTeamCTA: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: BCSpacing.sm) {
                ZStack {
                    Circle().fill(LinearGradient(colors: Palette.teal, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 56, height: 56)
                    Image(systemName: "person.3.fill").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                }
                Text("Maak een team").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                Text("Verzamel samen met je maatjes punten en verdien een team-uitje.")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textSecondary).multilineTextAlignment(.center)
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Nieuw team")
                }
                .font(BCTypography.bodyEmphasized).foregroundStyle(.white)
                .padding(.horizontal, BCSpacing.lg).padding(.vertical, 12)
                .background(Capsule().fill(LinearGradient(colors: Palette.teal, startPoint: .leading, endPoint: .trailing)))
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(BCSpacing.lg)
            .background(RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous).fill(BCColors.surface))
            .bcSoftShadow(.card)
        }
        .buttonStyle(.plain)
    }
}
