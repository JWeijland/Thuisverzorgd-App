//  GamificationModels.swift
//  Verplaatst uit BuddyPoolView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

struct PointRule: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let points: Int
}

enum PointRules {
    static let all: [PointRule] = [
        .init(icon: "tv-voltooid",  title: "Hulpvraag afgerond", detail: "Voor elke voltooide hulpvraag", points: 50),
        .init(icon: "tv-ster",      title: "5-sterren beoordeling", detail: "Bonus bij een topbeoordeling", points: 20),
        .init(icon: "tv-bliksem",   title: "Spoedhulp", detail: "Een hulpvraag binnen het uur opgepakt", points: 15),
        .init(icon: "tv-avondhulp", title: "Avond of weekend", detail: "Hulp buiten kantooruren", points: 10),
        .init(icon: "tv-streak",    title: "Wekelijkse streak", detail: "Elke week minstens één hulpvraag", points: 25),
        .init(icon: "tv-maatje",    title: "Maatje aangebracht", detail: "Een nieuwe buddy via jou actief", points: 40),
    ]
}

struct GameStats {
    var competitionPoints: Int
    var teamPoints: Int
    var yourTeamContribution: Int
    var streakDays: Int
    var todayCount: Int
    var bestStreak: Int

    var multiplier: Double { GameStats.multiplier(for: todayCount) }

    static func multiplier(for todayCount: Int) -> Double {
        switch todayCount {
        case ...0: return 1.0
        case 1:    return 1.0
        case 2:    return 1.5
        case 3:    return 2.0
        default:   return 3.0
        }
    }

    static let zero = GameStats(competitionPoints: 0, teamPoints: 0, yourTeamContribution: 0,
                                streakDays: 0, todayCount: 0, bestStreak: 0)
}

enum GameStatsProvider {
    static func make(for b: BuddyUser) -> GameStats {
        let pts = b.totalTasks * 40
        let teams = GameData.teams(currentName: b.firstName, avatar: b.avatarSystemName, points: pts)
        let myTeam = teams.first { $0.isMyTeam }
        return GameStats(competitionPoints: pts,
                         teamPoints: myTeam?.totalPoints ?? 0,
                         yourTeamContribution: pts,
                         streakDays: 0, todayCount: 0, bestStreak: 0)
    }
}

func formatMultiplier(_ m: Double) -> String {
    m == m.rounded() ? String(Int(m)) : String(m).replacingOccurrences(of: ".", with: ",")
}

struct PoolMember: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String
    let points: Int
    var isCurrentUser: Bool = false
    var photoURL: String? = nil
    /// Profiel-id van deze buddy (nodig voor review/verwijderen in de zorgkring).
    var buddyId: UUID? = nil
}

enum CompetitionStatus { case inschrijving, loopt, afgelopen }

struct CompetitionPrize: Identifiable {
    let id = UUID()
    let rank: Int
    let title: String
    let icon: String
}

struct Competition: Identifiable, Hashable {
    /// Stabiele id — in live-modus de Supabase competitie-id, anders lokaal.
    var id = UUID()
    let name: String
    let tagline: String
    let icon: String
    let tint: [Color]
    let status: CompetitionStatus
    let deadline: Date
    let durationWeeks: Int
    let weeksRemaining: Int
    let minParticipants: Int
    let maxParticipants: Int
    let participantCount: Int
    let prizes: [CompetitionPrize]
    let members: [PoolMember]
    var isRegistered: Bool = false

    var ranked: [PoolMember] { members.sorted { $0.points > $1.points } }
    var currentUserRank: Int? { ranked.firstIndex(where: { $0.isCurrentUser }).map { $0 + 1 } }
    var spotsLeft: Int { max(0, maxParticipants - participantCount) }
    var isFull: Bool { participantCount >= maxParticipants }
    var reachedMinimum: Bool { participantCount >= minParticipants }

    static func == (lhs: Competition, rhs: Competition) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Team: Identifiable, Hashable {
    /// Stabiele id — in live-modus de Supabase team-id, anders lokaal gegenereerd.
    var id = UUID()
    let name: String
    let icon: String
    let tint: [Color]
    let members: [PoolMember]
    let outingTarget: Int
    /// Prijs die wordt uitgedeeld zodra het puntendoel is behaald.
    var prizeTitle: String = ""
    var isMyTeam: Bool = false
    var inviteCode: String = ""
    /// Heb je een openstaand join-verzoek voor dit team (wacht op goedkeuring)?
    var pendingJoin: Bool = false

    /// Net leesbare prijs (terugval als de maker niets invulde).
    var prizeDisplay: String { prizeTitle.isEmpty ? "Een team-uitje" : prizeTitle }

    var totalPoints: Int { members.reduce(0) { $0 + $1.points } }
    var ranked: [PoolMember] { members.sorted { $0.points > $1.points } }
    var fraction: Double { min(1, Double(totalPoints) / Double(max(1, outingTarget))) }
    var pointsToGo: Int { max(0, outingTarget - totalPoints) }
    var currentUserRank: Int? { ranked.firstIndex(where: { $0.isCurrentUser }).map { $0 + 1 } }

    static func == (lhs: Team, rhs: Team) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum Palette {
    static let purple = [Color(red: 0.42, green: 0.27, blue: 0.78), Color(red: 0.30, green: 0.46, blue: 0.92)]
    static let green  = [Color(red: 0.14, green: 0.52, blue: 0.42), Color(red: 0.44, green: 0.72, blue: 0.30)]
    static let amber  = [Color(red: 0.93, green: 0.60, blue: 0.18), Color(red: 0.86, green: 0.38, blue: 0.22)]
    static let teal   = [Color(red: 0.10, green: 0.49, blue: 0.55), Color(red: 0.22, green: 0.68, blue: 0.62)]
    static let indigo = [Color(red: 0.28, green: 0.31, blue: 0.66), Color(red: 0.40, green: 0.45, blue: 0.85)]

    /// Sleutels zoals bewaard in `teams.accent` (volgorde = CreateTeamSheet-keuze).
    static let keys = ["amber", "teal", "purple", "green", "indigo"]
    static let byKey: [String: [Color]] = [
        "amber": amber, "teal": teal, "purple": purple, "green": green, "indigo": indigo
    ]
    /// Gradient bij een opgeslagen accent-sleutel (val terug op teal).
    static func tint(forKey key: String?) -> [Color] { byKey[key ?? ""] ?? teal }
}

enum MedalTier {
    case bronze, silver, gold, platinum, diamond

    var name: String {
        switch self {
        case .bronze: return "Brons"
        case .silver: return "Zilver"
        case .gold: return "Goud"
        case .platinum: return "Platina"
        case .diamond: return "Diamant"
        }
    }
    var colors: [Color] {
        switch self {
        case .bronze:   return [Color(red: 0.80, green: 0.52, blue: 0.28), Color(red: 0.62, green: 0.38, blue: 0.18)]
        case .silver:   return [Color(red: 0.78, green: 0.81, blue: 0.86), Color(red: 0.55, green: 0.59, blue: 0.66)]
        case .gold:     return [Color(red: 0.96, green: 0.79, blue: 0.30), Color(red: 0.83, green: 0.60, blue: 0.13)]
        case .platinum: return [Color(red: 0.70, green: 0.80, blue: 0.85), Color(red: 0.45, green: 0.58, blue: 0.66)]
        case .diamond:  return [Color(red: 0.55, green: 0.83, blue: 0.96), Color(red: 0.30, green: 0.55, blue: 0.90)]
        }
    }
    static func forIndex(_ i: Int, count: Int) -> MedalTier {
        let f = count <= 1 ? 0 : Double(i) / Double(count - 1)
        switch f {
        case ..<0.2:  return .bronze
        case ..<0.45: return .silver
        case ..<0.7:  return .gold
        case ..<0.9:  return .platinum
        default:      return .diamond
        }
    }
}

struct Medal: Identifiable {
    let id = UUID()
    let threshold: Int
    let unlocked: Bool
    let tier: MedalTier
}

struct AchievementCategory: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let unit: String
    let tint: [Color]
    let current: Int
    let thresholds: [Int]

    var medals: [Medal] {
        thresholds.enumerated().map { i, t in
            Medal(threshold: t, unlocked: current >= t, tier: MedalTier.forIndex(i, count: thresholds.count))
        }
    }
    var unlockedCount: Int { thresholds.filter { current >= $0 }.count }
    var nextThreshold: Int? { thresholds.first { current < $0 } }
}

enum AchievementData {
    static func categories(for b: BuddyUser, stats: GameStats) -> [AchievementCategory] {
        // Echte voortgang — geen kunstmatige minimum-floor. Zonder voltooide
        // taken zijn er dus nog géén medailles. Avond/weekend/waardering worden
        // (bij gebrek aan losse tellers) afgeleid van het aantal voltooide taken.
        let visits  = b.totalTasks
        let evening = visits / 3
        let weekend = visits / 4
        let perDay  = 0
        let streak  = stats.bestStreak
        let reviews = visits / 2

        return [
            AchievementCategory(title: "Bezoeken", subtitle: "Voltooide hulpvragen", icon: "tv-bezoek",
                                unit: "bezoeken", tint: Palette.green, current: visits,
                                thresholds: [5,10,15,20,25,30,40,50,75,100,150,200,250,300,400,500]),
            AchievementCategory(title: "Avondhulp", subtitle: "Geholpen in de avond", icon: "tv-avondhulp",
                                unit: "avonden", tint: Palette.indigo, current: evening,
                                thresholds: [3,5,10,15,20,30,40,50,75,100]),
            AchievementCategory(title: "Weekendhulp", subtitle: "Geholpen in het weekend", icon: "tv-weekendhulp",
                                unit: "weekenden", tint: Palette.amber, current: weekend,
                                thresholds: [3,5,10,15,20,30,40,50,75,100]),
            AchievementCategory(title: "Dagtoppers", subtitle: "Meerdere hulpvragen op één dag", icon: "tv-bliksem",
                                unit: "dagen", tint: Palette.purple, current: perDay,
                                thresholds: [1,3,5,10,15,20,30,50]),
            AchievementCategory(title: "Streak", subtitle: "Dagen achter elkaar actief", icon: "tv-streak",
                                unit: "dagen", tint: Palette.teal, current: streak,
                                thresholds: [3,7,14,30,60,100,180,365]),
            AchievementCategory(title: "Waardering", subtitle: "5-sterren beoordelingen", icon: "tv-ster",
                                unit: "sterren", tint: Palette.amber, current: reviews,
                                thresholds: [1,5,10,25,50,100,200]),
        ]
    }

    static func totalUnlocked(for b: BuddyUser, stats: GameStats) -> Int {
        categories(for: b, stats: stats).reduce(0) { $0 + $1.unlockedCount }
    }
    static func totalMedals(for b: BuddyUser, stats: GameStats) -> Int {
        categories(for: b, stats: stats).reduce(0) { $0 + $1.thresholds.count }
    }
}
