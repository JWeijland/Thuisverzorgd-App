//  GameData.swift
//  Verplaatst uit BuddyPoolView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI

enum GameData {
    private static func members(_ rows: [(String, Int)]) -> [PoolMember] {
        rows.map { PoolMember(name: $0.0, avatar: "person.crop.circle.fill", points: $0.1) }
    }
    private static func days(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: Date()) ?? Date()
    }

    static func competitions(currentName: String, avatar: String, points: Int) -> [Competition] {
        var lopend = members([("Sara", 540), ("Tariq", 420), ("Lieke", 300), ("Daan", 260),
                              ("Yara", 180), ("Mees", 160), ("Bo", 120)])
        lopend.insert(PoolMember(name: currentName, avatar: avatar, points: points, isCurrentUser: true), at: 1)

        let prizesTech = [
            CompetitionPrize(rank: 1, title: "JBL Boombox 3", icon: "hifispeaker.fill"),
            CompetitionPrize(rank: 2, title: "Draadloze koptelefoon", icon: "headphones"),
            CompetitionPrize(rank: 3, title: "Bluetooth-speaker", icon: "speaker.wave.2.fill"),
        ]
        let prizesUit = [
            CompetitionPrize(rank: 1, title: "Weekendje weg", icon: "suitcase.fill"),
            CompetitionPrize(rank: 2, title: "Diner voor twee", icon: "fork.knife"),
            CompetitionPrize(rank: 3, title: "Bioscoopbon", icon: "popcorn.fill"),
        ]

        return [
            Competition(name: "Lentestrijd", tagline: "De grote voorjaarscompetitie", icon: "leaf.fill",
                        tint: Palette.green, status: .loopt, deadline: days(-7), durationWeeks: 6, weeksRemaining: 3,
                        minParticipants: 10, maxParticipants: 50, participantCount: 32,
                        prizes: prizesUit, members: lopend, isRegistered: true),
            Competition(name: "Zomerchallenge", tagline: "Studenten & jonge buddies", icon: "sun.max.fill",
                        tint: Palette.purple, status: .inschrijving, deadline: days(5), durationWeeks: 8, weeksRemaining: 8,
                        minParticipants: 10, maxParticipants: 50, participantCount: 41,
                        prizes: prizesTech, members: members([]), isRegistered: false),
            Competition(name: "Buurtbattle", tagline: "Wijkgericht, samen sterk", icon: "house.fill",
                        tint: Palette.amber, status: .inschrijving, deadline: days(12), durationWeeks: 4, weeksRemaining: 4,
                        minParticipants: 10, maxParticipants: 30, participantCount: 7,
                        prizes: prizesUit, members: members([]), isRegistered: false),
            Competition(name: "Wintercup", tagline: "Afgelopen seizoen", icon: "snowflake",
                        tint: Palette.teal, status: .afgelopen, deadline: days(-60), durationWeeks: 6, weeksRemaining: 0,
                        minParticipants: 10, maxParticipants: 50, participantCount: 38,
                        prizes: prizesTech,
                        members: members([("Noor", 880), ("Sem", 760), ("Iris", 720), ("Joost", 540), ("Pim", 410)]),
                        isRegistered: false),
        ]
    }

    static func teams(currentName: String, avatar: String, points: Int) -> [Team] {
        var mine = members([("Sara", 520), ("Tariq", 360), ("Lieke", 300)])
        mine.insert(PoolMember(name: currentName, avatar: avatar, points: points, isCurrentUser: true), at: 1)
        return [
            Team(name: "De Koffiemaatjes", icon: "cup.and.saucer.fill", tint: Palette.amber,
                 members: mine, outingTarget: 2000, isMyTeam: true, inviteCode: "KOFFIE24"),
            Team(name: "Wandelclub Noord", icon: "figure.walk", tint: Palette.teal,
                 members: members([("Eva", 620), ("Tom", 540), ("Anouk", 460), ("Saar", 300)]), outingTarget: 2000),
            Team(name: "Studiehelden", icon: "graduationcap.fill", tint: Palette.purple,
                 members: members([("Mila", 700), ("Ravi", 520), ("Fenna", 380)]), outingTarget: 2000),
            Team(name: "Buurtbrigade", icon: "shield.fill", tint: Palette.green,
                 members: members([("Wim", 480), ("Riet", 420), ("Hassan", 360), ("Greet", 260)]), outingTarget: 2000),
        ]
    }
}
