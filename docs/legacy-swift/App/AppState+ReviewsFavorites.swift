//  AppState+ReviewsFavorites.swift
//  Onderdeel van AppState — Reviews & favoriete buddies.
//  Puur verplaatst uit AppState.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import Foundation
import CoreLocation

extension AppState {

    func toggleFavorite(buddyName: String) {
        let nowFavorite = !favoriteBuddyNames.contains(buddyName)
        if nowFavorite {
            favoriteBuddyNames.insert(buddyName)
            showToast(text: "\(buddyName) toegevoegd aan vaste buddies", icon: "heart.fill")
        } else {
            favoriteBuddyNames.remove(buddyName)
        }

        // Live: bewaar in favorite_buddies. We hebben de buddy-UUID nodig — die
        // halen we uit de buddy-lijst of uit een eerder bezoek.
        guard isLive, currentRole == .elderly, let elderlyId = realUserId else {
            if nowFavorite { notifyBuddyBecameFavorite(buddyName: buddyName) }
            return
        }
        let buddyId = allBuddies.first { $0.firstName == buddyName }?.id
            ?? taskHistory.first { $0.assignedBuddyName == buddyName }?.assignedBuddyId
        guard let buddyId else { return }
        let elderlyName = elderlyUser.firstName
        Task {
            if nowFavorite {
                try? await ProfileService().addFavorite(elderlyId: elderlyId, buddyId: buddyId,
                                                        buddyName: buddyName, elderlyName: elderlyName)
                try? await ProfileService().notifyFavoriteBuddy(buddyId: buddyId)
            } else {
                try? await ProfileService().removeFavorite(elderlyId: elderlyId, buddyId: buddyId)
            }
        }
    }

    /// Maakt een buddy een vaste buddy met de UUID rechtstreeks uit de (zojuist
    /// afgeronde) taak. Robuuster dan `toggleFavorite(buddyName:)` omdat de buddy
    /// niet per se in `allBuddies` hoeft te staan.
    func addFavoriteBuddy(name: String, buddyId: UUID?) {
        guard !favoriteBuddyNames.contains(name) else { return }
        favoriteBuddyNames.insert(name)

        guard isLive, currentRole == .elderly, let elderlyId = realUserId else {
            notifyBuddyBecameFavorite(buddyName: name)
            return
        }
        let resolvedId = buddyId
            ?? allBuddies.first { $0.firstName == name }?.id
            ?? taskHistory.first { $0.assignedBuddyName == name }?.assignedBuddyId
        guard let resolvedId else { return }
        let elderlyName = elderlyUser.firstName
        Task {
            try? await ProfileService().addFavorite(elderlyId: elderlyId, buddyId: resolvedId,
                                                    buddyName: name, elderlyName: elderlyName)
            // De buddy krijgt push + inbox-bericht: "je bent een vaste buddy geworden".
            try? await ProfileService().notifyFavoriteBuddy(buddyId: resolvedId)
        }
    }

    /// Demo-variant van de vaste-buddy-melding: zet het bericht lokaal in de
    /// inbox en op het buddy-profiel, zodat de buddy-rol het meteen kan zien.
    private func notifyBuddyBecameFavorite(buddyName: String) {
        let elderlyName = elderlyUser.firstName
        inbox.insert(InboxMessage(
            id: UUID(), kind: .favoriteBuddy,
            title: "\(elderlyName) heeft jou als vaste buddy gekozen",
            body: "Wat leuk! Je bent nu een vertrouwd gezicht voor \(elderlyName).",
            teamId: nil, requestId: nil,
            read: false, date: Date()
        ), at: 0)
        if !buddyFans.contains(elderlyName) { buddyFans.append(elderlyName) }
    }

    /// De buddy beoordeelt na afloop de hulpvrager (reviewee = cliënt). Wordt in
    /// live-modus echt naar Supabase geschreven; de trigger werkt het
    /// cliënt-gemiddelde bij (zie fase26_elderly_rating.sql).
    func buddySubmitsReview(for task: ServiceTask, stars: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isLive, let elderlyId = task.elderlyId, let reviewerId = realUserId else {
            showToast(text: "Bedankt voor je beoordeling!", icon: "star.fill")
            return
        }
        let bodyToSend = trimmed.isEmpty ? "Fijn bezoek, bedankt!" : trimmed
        Task {
            try? await TaskService().submitReview(
                taskId: task.id,
                reviewerId: reviewerId,
                revieweeId: elderlyId,
                stars: stars,
                body: bodyToSend
            )
        }
        showToast(text: "Bedankt voor je beoordeling!", icon: "star.fill")
    }

    func rateTask(taskId: UUID, stars: Int, body: String) {
        taskRatings[taskId] = stars
        skippedReviews.remove(taskId)
        // Zoek de bijbehorende taak op (historie óf actief), zodat ook
        // beoordelingen van eerdere bezoeken écht in Supabase belanden.
        let task = taskHistory.first { $0.id == taskId } ?? activeTaskForElderly
        submitReview(for: task, stars: stars, body: body)
    }

    func skipReview(taskId: UUID) {
        skippedReviews.insert(taskId)
        if isLive, let reviewerId = realUserId {
            Task { try? await ProfileService().addSkippedReview(reviewerId: reviewerId, taskId: taskId) }
        }
    }

    func unskipReview(taskId: UUID) {
        skippedReviews.remove(taskId)
        if isLive, let reviewerId = realUserId {
            Task { try? await ProfileService().removeSkippedReview(reviewerId: reviewerId, taskId: taskId) }
        }
    }

    var familyHasUnreviewedVisits: Bool {
        let name = activeFamilyElderly.firstName
        return taskHistory.contains { task in
            task.elderlyName == name && taskRatings[task.id] == nil && !skippedReviews.contains(task.id)
        }
    }
}
