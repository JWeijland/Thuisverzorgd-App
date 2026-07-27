//  BuddyPoolDetailViews.swift
//  Verplaatst uit BuddyPoolView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct CompetitionDetailView: View {
    let competition: Competition
    var onRegisterChange: (Bool) -> Void
    @State private var isRegistered: Bool

    init(competition: Competition, onRegisterChange: @escaping (Bool) -> Void) {
        self.competition = competition
        self.onRegisterChange = onRegisterChange
        _isRegistered = State(initialValue: competition.isRegistered)
    }

    private var c: Competition { competition }
    private var tint: Color { c.tint.first ?? BCColors.primary }

    var body: some View {
        ScrollView {
            VStack(spacing: BCSpacing.xl) {
                head
                PrizesList(prizes: c.prizes, awarded: c.status == .afgelopen)
                if c.status == .inschrijving { registration }
                else {
                    VStack(alignment: .leading, spacing: BCSpacing.lg) {
                        Text(c.status == .afgelopen ? "Eindstand" : "Ranglijst").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                        MembersBoard(members: c.ranked, tint: tint)
                    }
                }
            }
            .padding(.horizontal, BCSpacing.lg).padding(.top, BCSpacing.md).padding(.bottom, BCSpacing.xxl)
        }
        .background(BCColors.background)
        .navigationTitle(c.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var head: some View {
        VStack(spacing: BCSpacing.md) {
            ZStack {
                Circle().fill(LinearGradient(colors: c.tint, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 72, height: 72)
                Image(systemName: c.icon).font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
            }
            Text(c.tagline).font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary)
            StatusTag(status: c.status, deadline: c.deadline, weeksRemaining: c.weeksRemaining)
            HStack(spacing: 0) {
                headStat("\(c.durationWeeks)", "weken duur"); cell
                headStat("\(c.participantCount)/\(c.maxParticipants)", "deelnemers"); cell
                headStat("min. \(c.minParticipants)", "voor start")
            }
            .padding(.top, BCSpacing.xs)
        }
    }

    private func headStat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 3) {
            Text(v).font(BCFont.heading(18, .bold)).foregroundStyle(BCColors.textPrimary)
            Text(l).font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
        }.frame(maxWidth: .infinity)
    }
    private var cell: some View { Rectangle().fill(BCColors.border).frame(width: 1, height: 28) }

    private var registration: some View {
        VStack(spacing: BCSpacing.md) {
            VStack(spacing: 8) {
                HStack {
                    Text("Inschrijvingen").font(BCTypography.captionEmphasized).foregroundStyle(BCColors.textSecondary)
                    Spacer()
                    Text("\(c.participantCount) / \(c.maxParticipants)").font(BCTypography.captionEmphasized).foregroundStyle(BCColors.textSecondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(BCColors.surfaceMuted)
                        Capsule().fill(LinearGradient(colors: c.tint, startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * min(1, Double(c.participantCount) / Double(c.maxParticipants)))
                    }
                }
                .frame(height: 8)
                Text(c.reachedMinimum
                     ? "Het minimum van \(c.minParticipants) is gehaald, de competitie kan van start."
                     : "Nog \(c.minParticipants - c.participantCount) nodig om het minimum van \(c.minParticipants) te halen.")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary).frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { isRegistered.toggle(); onRegisterChange(isRegistered) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isRegistered ? "checkmark.circle.fill" : "pencil.and.list.clipboard").font(.system(size: 16, weight: .semibold))
                    Text(isRegistered ? "Je bent ingeschreven" : (c.isFull ? "Competitie is vol" : "Schrijf je in")).font(BCTypography.bodyEmphasized)
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(isRegistered ? tint : .white)
                .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                    .fill(isRegistered ? AnyShapeStyle(BCColors.surface) : AnyShapeStyle(LinearGradient(colors: c.tint, startPoint: .leading, endPoint: .trailing))))
                .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(isRegistered ? tint.opacity(0.4) : .clear, lineWidth: 1))
                .opacity(c.isFull && !isRegistered ? 0.5 : 1)
            }
            .buttonStyle(.plain)
            .disabled(c.isFull && !isRegistered)
            Text("Je kunt aan maximaal 1 actieve competitie tegelijk meedoen.")
                .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary).frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct TeamDetailView: View {
    @Environment(AppState.self) private var appState
    let team: Team
    @State private var requested: Bool
    private var tint: Color { team.tint.first ?? BCColors.primary }

    init(team: Team) {
        self.team = team
        _requested = State(initialValue: team.pendingJoin)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: BCSpacing.xl) {
                VStack(spacing: BCSpacing.md) {
                    ProgressRing(fraction: team.fraction, colors: team.tint, lineWidth: 12).frame(width: 150, height: 150)
                        .overlay {
                            VStack(spacing: 2) {
                                Image(systemName: "gift.fill").font(.system(size: 24, weight: .semibold)).foregroundStyle(tint)
                                Text("\(Int(team.fraction * 100))%").font(BCFont.heading(26, .heavy)).foregroundStyle(BCColors.textPrimary)
                                Text("naar het uitje").font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                            }
                        }
                    HStack(spacing: 0) {
                        s("\(team.totalPoints)", "punten samen"); cell
                        s("\(team.pointsToGo)", "nog te gaan"); cell
                        s("\(team.members.count)", "maatjes")
                    }
                }
                HStack(spacing: BCSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).fill(LinearGradient(colors: team.tint, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 52, height: 52)
                        Image(systemName: "gift.fill").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(team.prizeDisplay).font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                        Text("Haal samen \(team.outingTarget) punten en jullie verdienen: \(team.prizeDisplay).").font(BCTypography.caption).foregroundStyle(BCColors.textSecondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, BCSpacing.md)
                .overlay(alignment: .top) { Divider().overlay(BCColors.border) }
                .overlay(alignment: .bottom) { Divider().overlay(BCColors.border) }

                VStack(alignment: .leading, spacing: BCSpacing.lg) {
                    Text("Bijdrage per maatje").font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
                    MembersBoard(members: team.ranked, tint: tint)
                }

                if !team.isMyTeam {
                    if requested {
                        actionButton(filled: false, icon: "hourglass",
                                     text: "In afwachting van goedkeuring") {}
                            .disabled(true)
                        Text("De teameigenaar krijgt je verzoek in zijn berichten en moet het goedkeuren.")
                            .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        actionButton(filled: true, icon: "person.fill.badge.plus",
                                     text: "Vraag om lid te worden") {
                            appState.requestToJoinTeam(team)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { requested = true }
                        }
                    }
                } else {
                    actionButton(filled: false, icon: "person.crop.circle.badge.plus", text: "Nodig een maatje uit") {}
                }
            }
            .padding(.horizontal, BCSpacing.lg).padding(.top, BCSpacing.md).padding(.bottom, BCSpacing.xxl)
        }
        .background(BCColors.background)
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func actionButton(filled: Bool, icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(text).font(BCTypography.bodyEmphasized)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(filled ? .white : tint)
            .background(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                .fill(filled ? AnyShapeStyle(LinearGradient(colors: team.tint, startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(BCColors.surface)))
            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous).stroke(filled ? .clear : tint.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func s(_ v: String, _ l: String) -> some View {
        VStack(spacing: 3) {
            Text(v).font(BCFont.heading(22, .bold)).foregroundStyle(BCColors.textPrimary)
            Text(l).font(BCTypography.caption).foregroundStyle(BCColors.textTertiary)
        }.frame(maxWidth: .infinity)
    }
    private var cell: some View { Rectangle().fill(BCColors.border).frame(width: 1, height: 30) }
}

struct SpelregelsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BCSpacing.xl) {
                intro
                VStack(alignment: .leading, spacing: BCSpacing.sm) {
                    SectionLabel("Punten verdienen")
                    VStack(spacing: 0) {
                        ForEach(Array(PointRules.all.enumerated()), id: \.element.id) { idx, rule in
                            HStack(spacing: BCSpacing.md) {
                                AppIcon(name: rule.icon, size: 24).frame(width: 28)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(rule.title).font(BCTypography.bodyEmphasized).foregroundStyle(BCColors.textPrimary)
                                    Text(rule.detail).font(BCTypography.caption).foregroundStyle(BCColors.textSecondary)
                                }
                                Spacer(minLength: 0)
                                Text("+\(rule.points)").font(BCFont.heading(17, .heavy)).foregroundStyle(BCColors.accentDark)
                            }
                            .padding(.vertical, BCSpacing.sm + 2)
                            if idx < PointRules.all.count - 1 { Divider().overlay(BCColors.border).padding(.leading, 40) }
                        }
                    }
                }
                rulesBlock(icon: "tv-streak", title: "Streak & multipliers", lines: [
                    "Doe je meer hulpvragen op één dag, dan stijgt je multiplier: 2e ×1,5 · 3e ×2 · 4e en verder ×3.",
                    "Een dagelijkse streak houd je vast door elke dag minstens één hulpvraag te doen.",
                    "Hoe langer je streak, hoe meer bonuspunten je extra verdient.",
                ])
                rulesBlock(icon: "tv-beker", title: "Competitie", lines: [
                    "Schrijf je vóór de deadline in. Je kunt aan maximaal 1 actieve competitie tegelijk meedoen.",
                    "Een competitie heeft minimaal 10 en maximaal 50 deelnemers.",
                    "Zodra het minimum is gehaald start de competitie en loopt die een aantal weken.",
                    "Aan het eind worden de top 3 beloond: nr. 1 de grootste prijs, daarna aflopend.",
                ])
                rulesBlock(icon: "tv-team", title: "Punten-teams", lines: [
                    "Vorm een team met je maatjes die ook buddy zijn.",
                    "Alle punten van de teamleden tellen samen op.",
                    "Teams staan op een gezamenlijke ranglijst.",
                    "Haalt je team het puntendoel? Dan verdienen jullie samen een team-uitje.",
                ])
                rulesBlock(icon: "tv-team", title: "Zorg-teams", lines: [
                    "Zorg met een paar vaste maatjes samen voor 1 ouder.",
                    "De aangevraagde bezoeken komen in een schema; teamleden pakken ze op.",
                    "Wordt een bezoek niet binnen 1 dag opgepakt? Dan gaat het naar de gewone buddy-pool.",
                    "Alleen aanvragen die 2 dagen of meer vooruit zijn ingepland komen bij het team.",
                ])
                Text("Punten worden eerlijk bijgehouden per afgeronde hulpvraag. Kwaliteit telt: beoordelingen wegen mee.")
                    .font(BCTypography.caption).foregroundStyle(BCColors.textTertiary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, BCSpacing.lg).padding(.top, BCSpacing.md).padding(.bottom, BCSpacing.xxl)
        }
        .background(BCColors.background)
        .navigationTitle("Spelregels")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Gereed") { dismiss() }.tint(BCColors.primary) } }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Help mee, verdien punten").font(BCFont.heading(22, .heavy)).foregroundStyle(BCColors.textPrimary)
            Text("Met elke hulpvraag die je oppakt verdien je punten. Bouw een streak, pak je multiplier en win samen met je team of in een competitie mooie prijzen.")
                .font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rulesBlock(icon: String, title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack(spacing: 8) {
                AppIcon(name: icon, size: 20)
                Text(title).font(BCTypography.headline).foregroundStyle(BCColors.textPrimary)
            }
            VStack(alignment: .leading, spacing: BCSpacing.sm) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(BCColors.accentDark).padding(.top, 3)
                        Text(line).font(BCTypography.body).foregroundStyle(BCColors.textSecondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
