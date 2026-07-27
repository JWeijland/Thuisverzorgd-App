import SwiftUI
import UIKit
import Combine
import Supabase

// ============================================================================
// Gamification — Competitie & Zorgkringen
//
// Front-end met voorbeelddata; backend in
// supabase/migrations/fase14_competitions_teams.sql (+ fase35_zorgkring.sql).
//
//  • COMPETITIE (individueel): inschrijven vóór de deadline (max 1 actief),
//    loopt enkele weken, top 3 beloond met aflopende prijzen, 10–50 deelnemers.
//  • ZORGKRING (fase35): hét team van de app — een vast groepje buddies rond
//    1 hulpvrager. Punten en het uitjes-doel hangen aan de zorgkring; losse
//    punten-teams bestaan niet meer.
//  • STREAK & MULTIPLIERS: meer doen op één dag geeft een hogere multiplier;
//    een streak vasthouden geeft bonuspunten.
// ============================================================================

// MARK: - Hub

struct BuddyPoolView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var tab: Int

    /// Berekend uit het buddy-profiel, dus meteen correct bij de eerste render
    /// (geen "0" meer terwijl de stats nog laden).
    private var stats: GameStats { GameStatsProvider.make(for: appState.buddyUser) }
    @State private var query = ""
    @State private var showRules = false

    /// Navigatiepad zodat we vanuit een inbox-melding direct naar een specifiek
    /// team of de eigen competitie kunnen doorschakelen.
    @State private var path = NavigationPath()
    /// Deep-link-doelen (uit de inbox). Worden 1 keer verzilverd zodra de data er is.
    private let initialTeamId: UUID?
    private let openActiveCompetition: Bool
    @State private var didDeepLink = false

    init(initialTab: Int = 0, initialTeamId: UUID? = nil, openActiveCompetition: Bool = false) {
        _tab = State(initialValue: initialTab)
        self.initialTeamId = initialTeamId
        self.openActiveCompetition = openActiveCompetition
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Competitie én Teams zitten nu in 1 pagina; hier wissel je ertussen.
                Picker("", selection: $tab) {
                    Text("Competitie").tag(0)
                    Text("Zorgkringen").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, BCSpacing.lg)
                .padding(.top, BCSpacing.sm)
                .padding(.bottom, BCSpacing.xs)

                ScrollView {
                    if tab == 0 { competitieTab } else { teamsTab }
                }
            }
            .background(BCColors.background)
            .navigationTitle(tab == 0 ? "Competitie" : "Zorgkringen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: tab == 0 ? "Zoek een competitie" : "Zoek een zorgkring")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Sluit") { dismiss() }.tint(BCColors.primary) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showRules = true } label: { Image(systemName: "info.circle") }.tint(BCColors.primary)
                }
            }
            .navigationDestination(for: Competition.self) { comp in
                CompetitionDetailView(competition: comp) { reg in appState.setCompetitionRegistered(comp.id, reg) }
            }
            // Legacy: oude inbox-berichten kunnen nog naar een (gearchiveerd)
            // punten-team wijzen; die pagina blijft daarvoor bereikbaar.
            .navigationDestination(for: Team.self) { team in TeamDetailView(team: team) }
            .navigationDestination(for: CareTeam.self) { team in CareTeamDetailView(teamId: team.id) }
            .sheet(isPresented: $showRules) { NavigationStack { SpelregelsView() } }
        }
        .onAppear {
            setup()
            resolveDeepLink()
        }
        // Live laadt teams/competities async; probeer de deep-link opnieuw zodra de
        // data binnen is.
        .onChange(of: appState.teams) { _, _ in resolveDeepLink() }
        .onChange(of: appState.competitions) { _, _ in resolveDeepLink() }
    }

    /// Schakelt (1 keer) door naar het specifieke team of de eigen competitie die
    /// vanuit de inbox is aangetikt, zodra dat item beschikbaar is.
    private func resolveDeepLink() {
        guard !didDeepLink else { return }
        if let tid = initialTeamId, let team = appState.teams.first(where: { $0.id == tid }) {
            didDeepLink = true
            path.append(team)
        } else if openActiveCompetition, let comp = myCompetition {
            didDeepLink = true
            path.append(comp)
        }
    }

    private func setup() {
        // Competities & teams komen uit appState (live: Supabase; demo: mock).
        // Buiten live-modus en zonder seed vullen we eenmalig met voorbeelddata.
        guard !appState.isLive else { return }
        let b = appState.buddyUser
        let pts = b.totalTasks * 40
        if appState.competitions.isEmpty {
            appState.competitions = GameData.competitions(currentName: b.firstName, avatar: b.avatarSystemName, points: pts)
        }
        if appState.teams.isEmpty {
            appState.teams = GameData.teams(currentName: b.firstName, avatar: b.avatarSystemName, points: pts)
        }
        if appState.careTeams.isEmpty {
            appState.careTeams = CareTeamData.demoTeams(currentName: b.firstName, currentId: b.id)
        }
    }

    // MARK: Competitie-tab

    private var myCompetition: Competition? { appState.competitions.first { $0.isRegistered && $0.status != .afgelopen } }
    /// Jouw competitiepunten: live = je punten in je actieve competitie; anders mock.
    private var myCompetitionPoints: Int {
        if let me = myCompetition?.members.first(where: { $0.isCurrentUser }) { return me.points }
        return appState.isLive ? 0 : stats.competitionPoints
    }
    private var heroSubtitle: String {
        if let c = myCompetition, let r = c.currentUserRank {
            return "Je staat #\(r) van \(c.participantCount) in \(c.name)"
        }
        return "Doe mee aan een competitie en verdien prijzen"
    }
    private var openCompetitions: [Competition] { appState.competitions.filter { !($0.isRegistered && $0.status != .afgelopen) } }
    private var competitionSearch: [Competition] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return appState.competitions.filter { $0.name.lowercased().contains(q) || $0.tagline.lowercased().contains(q) }
    }

    @ViewBuilder private var competitieTab: some View {
        if !query.isEmpty {
            resultList(competitionSearch)
        } else {
            VStack(alignment: .leading, spacing: BCSpacing.lg) {
                if let myCompetition {
                    // De grote hero is zelf de ingang naar de competitie-details
                    // (net als de team-hero bij Teams).
                    NavigationLink(value: myCompetition) {
                        PointsHero(points: myCompetitionPoints, subtitle: heroSubtitle,
                                   stats: stats, tint: Palette.purple, showsChevron: true,
                                   prizeLine: (myCompetition.prizes.first(where: { $0.rank == 1 }) ?? myCompetition.prizes.first)?.title)
                    }
                    .buttonStyle(.plain)
                } else {
                    PointsHero(points: myCompetitionPoints, subtitle: heroSubtitle,
                               stats: stats, tint: Palette.purple)
                }
                MultiplierStrip(todayCount: stats.todayCount)
                VStack(alignment: .leading, spacing: BCSpacing.xs) {
                    SectionLabel("Ontdek competities").padding(.top, BCSpacing.sm)
                    listOf(openCompetitions)
                }
            }
            .padding(.horizontal, BCSpacing.lg)
            .padding(.top, BCSpacing.md)
            .padding(.bottom, BCSpacing.xxl)
        }
    }

    private func listOf(_ comps: [Competition]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(comps.enumerated()), id: \.element.id) { idx, comp in
                NavigationLink(value: comp) { CompetitionRow(competition: comp) }.buttonStyle(.plain)
                if idx < comps.count - 1 { Divider().overlay(BCColors.border) }
            }
        }
    }

    private func resultList(_ comps: [Competition]) -> some View {
        Group {
            if comps.isEmpty { emptySearch }
            else { listOf(comps).padding(.horizontal, BCSpacing.lg).padding(.top, BCSpacing.sm) }
        }
    }

    // MARK: Teams-tab (fase35: alleen nog zorgkringen)

    @ViewBuilder private var teamsTab: some View {
        CareTeamsSection(query: query)
    }

    private var emptySearch: some View {
        VStack(spacing: BCSpacing.md) {
            BCPillenPaar()
            Text("Niets gevonden voor \u{201C}\(query)\u{201D}").font(BCTypography.subheadline).foregroundStyle(BCColors.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.top, BCSpacing.xxl)
    }
}

#Preview {
    BuddyPoolView().environment(AppState())
}
