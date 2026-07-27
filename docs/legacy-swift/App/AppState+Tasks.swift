//  AppState+Tasks.swift
//  Onderdeel van AppState — Hulpvraag-acties (oudere & buddy).
//  Puur verplaatst uit AppState.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import Foundation
import CoreLocation

extension AppState {

    // MARK: - Task actions

    func requestHelp(category: TaskCategory, timing: TaskTiming, note: String,
                     recurringSchedule: RecurringSchedule? = nil,
                     audience: HelpAudience = .pool) {
        // Naar het eigen zorg-team? Dan komen de bezoeken (sporadisch of het hele
        // periodieke rooster) in het inzetrooster van het team, niet in de pool.
        if audience == .team, let team = careTeam(for: elderlyUser) {
            let dates = Self.teamVisitDates(timing: timing, schedule: recurringSchedule)
            if !dates.isEmpty {
                requestTeamVisits(teamId: team.id, category: category, note: note, dates: dates)
                return
            }
        }
        // Live-modus: schrijf de hulpvraag echt naar Supabase (zie AppStateLive.swift).
        // recurringSchedule wordt in de live-versie nog niet ondersteund (TODO Fase 2+).
        if isLive {
            createTaskLive(category: category, timing: timing, note: note)
            return
        }
        var task = ServiceTask(
            id: UUID(),
            elderlyName: elderlyUser.firstName,
            elderlyAddress: elderlyUser.address,
            coordinate: elderlyUser.coordinate,
            category: category,
            timing: timing,
            note: note,
            status: .open,
            createdAt: Date(),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil,
            elderlyId: elderlyUser.id
        )
        task.recurringSchedule = recurringSchedule
        openTasks.insert(task, at: 0)
        activeTaskForElderly = task

        // Matching: vind buddies en stuur hen een notificatie
        let matches = matchingService.rankBuddies(for: task, from: allBuddies)
        lastMatches = matches
        matchingService.notifyMatchedBuddies(matches: matches, task: task)
    }

    func requestHelpOnBehalf(
        for elderly: ElderlyUser,
        category: TaskCategory,
        timing: TaskTiming,
        note: String,
        recurringSchedule: RecurringSchedule? = nil,
        audience: HelpAudience = .pool
    ) {
        // Naar het zorg-team van deze ouder? Dan in het inzetrooster van het team.
        if audience == .team, let team = careTeam(for: elderly) {
            let dates = Self.teamVisitDates(timing: timing, schedule: recurringSchedule)
            if !dates.isEmpty {
                requestTeamVisits(teamId: team.id, category: category, note: note, dates: dates)
                return
            }
        }
        // Live: schrijf de hulpvraag echt naar Supabase via de RPC
        // create_task_for_elderly (fase21). De locatie wordt server-side van de
        // cliënt genomen, dus de druppel staat op het adres van de hulpvrager.
        if isLive {
            createTaskOnBehalfLive(for: elderly, category: category, timing: timing, note: note)
            return
        }
        var task = ServiceTask(
            id: UUID(),
            elderlyName: "\(elderly.firstName) \(elderly.lastName)",
            elderlyAddress: elderly.address,
            coordinate: elderly.coordinate,
            category: category,
            timing: timing,
            note: note,
            status: .open,
            createdAt: Date(),
            assignedBuddyName: nil,
            assignedBuddyRating: nil,
            assignedBuddyEtaMinutes: nil,
            elderlyId: elderly.id
        )
        task.recurringSchedule = recurringSchedule
        openTasks.insert(task, at: 0)
        activeTaskForElderly = task
        showToast(text: "Aanvraag ingezet voor \(elderly.firstName)", icon: "phone.fill")

        // Matching: vind buddies en stuur hen een notificatie
        let matches = matchingService.rankBuddies(for: task, from: allBuddies)
        lastMatches = matches
        matchingService.notifyMatchedBuddies(matches: matches, task: task)
    }

    func buddyAcceptsTask(_ task: ServiceTask) {
        // Live-modus: accepteer de echte taak in Supabase (zie AppStateLive.swift).
        if isLive {
            Task { await self.buddyAcceptsTaskLive(task) }
            return
        }
        guard let idx = openTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updated = openTasks[idx]
        updated.status = .accepted
        updated.assignedBuddyName = buddyUser.firstName
        updated.assignedBuddyRating = buddyUser.ratingAverage
        updated.assignedBuddyEtaMinutes = Int.random(in: 6...15)
        updated.assignedBuddyPhone = buddyUser.phoneNumber
        openTasks[idx] = updated
        activeTaskForBuddy = updated
    }

    /// De toegewezen buddy annuleert vóór de check-in. De taak gaat terug
    /// naar 'open', wordt opnieuw gematcht en de andere buddies krijgen
    /// opnieuw een melding. De oudere wordt geïnformeerd.
    func buddyCancelsAcceptedTask() {
        guard var task = activeTaskForBuddy else { return }
        let cancellingBuddyName = task.assignedBuddyName ?? buddyUser.firstName

        // Taak terugzetten naar open
        task.status = .open
        task.assignedBuddyName = nil
        task.assignedBuddyRating = nil
        task.assignedBuddyEtaMinutes = nil
        task.checkInRecord = nil

        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) {
            openTasks[idx] = task
        } else {
            openTasks.insert(task, at: 0)
        }
        activeTaskForBuddy = nil
        if activeTaskForElderly?.id == task.id {
            activeTaskForElderly = task
        }

        // Live: zet de taak in Supabase terug op 'open' zodat andere buddies
        // hem via de poll weer zien. Geen mock-simulatie in live-modus.
        if isLive {
            let id = task.id
            let myId = realUserId
            Task {
                // Eerst echt heropenen, dán de meldingen versturen — de edge
                // function controleert dat de taak ook echt weer 'open' staat.
                try? await TaskService().reopenTask(taskId: id)
                try? await TaskService().notifyTaskReopened(taskId: id, cancelledBuddyId: myId)
            }
            showToast(text: "Taak geannuleerd. Andere buddies in de buurt zien hem nu weer.",
                      icon: "arrow.triangle.2.circlepath")
            return
        }

        // Demo: opnieuw matchen, exclusief de buddy die net annuleerde
        let remaining = allBuddies.filter { $0.firstName != cancellingBuddyName }
        let matches = matchingService.rankBuddies(for: task, from: remaining)
        lastMatches = matches
        matchingService.notifyMatchedBuddies(matches: matches, task: task)

        // Oudere informeren
        MockPushService().send(notification: .taskReassigned(elderlyName: task.elderlyName))
        MockSMSService().sendSMS(
            to: elderlyUser.phoneNumber ?? "",
            message: BuddieNotification.taskReassigned(elderlyName: task.elderlyName).title
        )
        showToast(text: "Taak geannuleerd, we zoeken een andere buddy", icon: "arrow.triangle.2.circlepath")
    }

    func buddyArrives(checkIn: CheckInRecord) {
        guard var task = activeTaskForBuddy else { return }
        // Live: leg de aankomst vast (status + tijdstip) in Supabase.
        if isLive {
            let id = task.id
            Task { try? await TaskService().markArrived(taskId: id) }
        }
        task.status = .arrived
        task.checkInRecord = checkIn
        activeTaskForBuddy = task
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) {
            openTasks[idx] = task
        }
        if activeTaskForElderly?.id == task.id {
            activeTaskForElderly = task
        }
        MockPushService().send(notification: .buddyArrived(buddyName: buddyUser.firstName))
        MockSMSService().sendSMS(
            to: elderlyUser.phoneNumber ?? "",
            message: BuddieNotification.buddyArrived(buddyName: buddyUser.firstName).title
        )
    }

    func buddyCompletes(notes: String) {
        guard var task = activeTaskForBuddy else { return }
        // Live: rond de echte taak af in Supabase.
        if isLive {
            let id = task.id
            Task { try? await TaskService().completeTask(taskId: id, note: notes) }
        }
        task.status = .completed
        task.completionNote = notes
        task.completedAt = Date()
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) {
            openTasks.remove(at: idx)
        }
        taskHistory.insert(task, at: 0)
        activeTaskForBuddy = nil

        // Verhoog ervaringsteller voor matching-rangschikking
        let current = buddyUser.completedTasksByCategory[task.category] ?? 0
        buddyUser.completedTasksByCategory[task.category] = current + 1
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyUser.id }) {
            allBuddies[idx].completedTasksByCategory[task.category] = current + 1
        }
        // Update elderly so they see the completed state and review prompt
        if activeTaskForElderly?.id == task.id {
            activeTaskForElderly = task
        }
        MockPushService().send(notification: .taskCompleted)
        // Simulate: after 24h without elderly review, remind family
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, self.taskRatings[task.id] == nil else { return }
            MockPushService().send(notification: .familyReviewReminder(elderlyName: self.elderlyUser.firstName))
        }
    }

    /// De hulpvrager trekt de lopende hulpvraag in. Werkt zolang er nog geen
    /// bezoek bezig is (open/onderweg/aangekomen). Zet de taak in Supabase op
    /// 'cancelled' zodat de buddy hem niet meer ziet, en keert terug naar home.
    func elderlyCancelsTask() {
        guard let task = activeTaskForElderly else { return }
        let hadBuddy = task.assignedBuddyId != nil || task.assignedBuddyName != nil
        if isLive {
            let id = task.id
            Task {
                try? await TaskService().cancelTask(taskId: id)
                // Was er al een buddy toegewezen? Stuur die dan een push.
                if hadBuddy { try? await TaskService().notifyTaskCancelled(taskId: id) }
            }
        }
        openTasks.removeAll { $0.id == task.id }
        if activeTaskForBuddy?.id == task.id { activeTaskForBuddy = nil }
        activeTaskForElderly = nil
        showToast(text: "Hulpvraag ingetrokken", icon: "xmark.circle.fill")
    }

    /// De hulpvrager stuurt zijn toegewezen buddy een persoonlijk bericht. Komt
    /// als push + inbox-melding bij de buddy binnen (live). In demo-modus tonen we
    /// alleen een bevestiging.
    func elderlySendsMessageToBuddy(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let task = activeTaskForElderly else { return }
        guard isLive else {
            showToast(text: "Bericht verstuurd naar je buddy.", icon: "paperplane.fill")
            return
        }
        let id = task.id
        Task {
            do {
                try await TaskService().sendMessageToBuddy(taskId: id, text: trimmed)
                await MainActor.run {
                    self.showToast(text: "Bericht verstuurd naar je buddy.", icon: "paperplane.fill")
                }
            } catch {
                await MainActor.run {
                    self.showToast(text: "Versturen mislukt, probeer het opnieuw.",
                                   icon: "exclamationmark.triangle.fill")
                }
            }
        }
    }

    func elderlySubmitsReview(stars: Int, body: String) {
        let task = activeTaskForElderly
        submitReview(for: task, stars: stars, body: body)
        activeTaskForElderly = nil
    }

    /// Eén gedeeld pad voor álle beoordelingen (direct na bezoek, uit de
    /// geschiedenis of door familie). Bewaart lokaal én — in live-modus —
    /// in Supabase, zodat de buddy de review echt ontvangt.
    func submitReview(for task: ServiceTask?, stars: Int, body: String) {
        let authorBase = task?.elderlyName ?? elderlyUser.firstName
        let author = elderlyUser.displayAge.map { "\(authorBase), \($0)" } ?? authorBase
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let review = Review(
            id: UUID(),
            stars: stars,
            body: trimmed.isEmpty ? "Fijne buddy, bedankt!" : trimmed,
            authorName: author,
            date: Date()
        )
        buddyReviews.insert(review, at: 0)

        // Live: schrijf de review naar Supabase (de DB-trigger werkt de
        // buddy-rating bij). Vereist de buddy-UUID van de beoordeelde taak.
        if isLive,
           let task,
           let buddyId = task.assignedBuddyId,
           let reviewerId = realUserId {
            let bodyToSend = review.body
            Task {
                try? await TaskService().submitReview(
                    taskId: task.id,
                    reviewerId: reviewerId,
                    revieweeId: buddyId,
                    stars: stars,
                    body: bodyToSend
                )
            }
        }

        showToast(text: "Bedankt voor uw beoordeling!", icon: "star.fill")
    }

    /// Demo: de oudere bevestigt de check-in (QR gescand of overgeslagen) → het bezoek start.
    func elderlyConfirmsCheckIn() {
        guard var task = activeTaskForElderly else { return }
        if isLive {
            let id = task.id
            Task { try? await TaskService().markInProgress(taskId: id) }
        }
        task.status = .inProgress
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) { openTasks[idx] = task }
        activeTaskForElderly = task
        if activeTaskForBuddy?.id == task.id { activeTaskForBuddy = task }
        showToast(text: "Bezoek gestart", icon: "checkmark.circle.fill")
    }

    /// Demo: de oudere bevestigt de uitcheck (QR gescand of overgeslagen) → het bezoek wordt voltooid.
    func elderlyConfirmsCheckOut() {
        guard var task = activeTaskForElderly else { return }
        if isLive {
            let id = task.id
            let note = task.completionNote ?? "Bezoek afgerond."
            Task { try? await TaskService().completeTask(taskId: id, note: note) }
        }
        task.status = .completed
        task.completedAt = Date()
        if task.completionNote == nil { task.completionNote = "Bezoek afgerond." }
        if let idx = openTasks.firstIndex(where: { $0.id == task.id }) { openTasks.remove(at: idx) }
        taskHistory.insert(task, at: 0)
        activeTaskForBuddy = nil
        activeTaskForElderly = task   // status .completed → cliëntscherm toont de beoordeling
    }
}
