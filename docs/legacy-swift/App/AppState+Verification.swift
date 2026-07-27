//  AppState+Verification.swift
//  Onderdeel van AppState — VOG, intakegesprek & admin-moderatie (gebruikersbeheer).
//  Puur verplaatst uit AppState.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import Foundation
import CoreLocation

extension AppState {

    /// Demo: markeer de buddy als geverifieerd (VOG + intake) zonder de echte
    /// stappen te doorlopen. In live-modus wordt het ook in de database gezet.
    func demoVerifyBuddy() {
        buddyUser.vogValid = true
        buddyUser.vogStatus = .geldig
        buddyUser.intakeCompleted = true
        if let idx = allBuddies.firstIndex(where: { $0.id == buddyUser.id }) {
            allBuddies[idx].vogValid = true
            allBuddies[idx].intakeCompleted = true
        }
        showToast(text: "Demo: je bent geverifieerd", icon: "checkmark.seal.fill")
        if isLive, let userId = realUserId {
            Task {
                try? await profileService.updateBuddyVerification(
                    buddyId: userId, vogValid: true, intakeCompleted: true
                )
            }
        }
    }

    // MARK: - VOG-flow

    /// Model B: buddy heeft al een VOG en uploadt het document.
    /// Status → in behandeling; in live-modus naar de privé-bucket + DB.
    func buddyUploadsVOG(data: Data, fileExtension: String, contentType: String) {
        guard isLive, let userId = realUserId else {
            // Demo / niet ingelogd: alleen lokaal tonen, geen serveractie.
            buddyUser.vogStatus = .inBehandeling
            showToast(text: "VOG geüpload. We controleren 'm even.", icon: "doc.badge.arrow.up")
            return
        }
        showToast(text: "VOG uploaden…", icon: "arrow.up.circle")
        Task {
            // Stap 1: document naar de privé-bucket.
            let path: String
            do {
                path = try await profileService.uploadVOGDocument(
                    buddyId: userId, data: data, fileExtension: fileExtension, contentType: contentType
                )
            } catch {
                await MainActor.run {
                    self.showToast(text: "Upload mislukt (bestand): \(Self.shortError(error))",
                                   icon: "exclamationmark.triangle.fill")
                }
                return
            }
            // Stap 2: status + documentpad op het profiel zetten.
            do {
                try await profileService.submitVOGUpload(buddyId: userId, documentPath: path)
            } catch {
                await MainActor.run {
                    self.showToast(text: "Upload mislukt (status): \(Self.shortError(error))",
                                   icon: "exclamationmark.triangle.fill")
                }
                return
            }
            await MainActor.run {
                self.buddyUser.vogStatus = .inBehandeling
                self.buddyUser.vogDocumentUrl = path
                self.showToast(text: "VOG geüpload. We controleren 'm even.", icon: "doc.badge.arrow.up")
            }
        }
    }

    /// Korte, leesbare foutomschrijving voor in een toast (helpt bij diagnose).
    static func shortError(_ error: Error) -> String {
        let raw = (error as NSError).localizedDescription
        return raw.count > 120 ? String(raw.prefix(120)) + "…" : raw
    }

    /// Model A: buddy vraagt de VOG aan via Thuisverzorgd (org start de aanvraag).
    func buddyRequestsVOG() {
        buddyUser.vogStatus = .aangevraagd
        showToast(text: "VOG-aanvraag gestart. Je krijgt bericht via Justis of e-mail.", icon: "shield.lefthalf.filled")
        guard isLive, let userId = realUserId else { return }
        Task { try? await profileService.requestVOG(buddyId: userId) }
    }

    /// Admin: laad de openstaande VOG's (alleen live).
    func adminLoadPendingVOGs() {
        guard isLive else { return }
        Task {
            do {
                let pending = try await profileService.fetchPendingVOGs()
                await MainActor.run { self.pendingVOGs = pending }
            } catch {
                // Niet stil falen: een lege lijst zou ten onrechte "geen aanvragen"
                // suggereren terwijl het ophalen mislukte.
                await MainActor.run {
                    self.showToast(text: "VOG-lijst laden mislukt. Trek omlaag om te verversen.",
                                   icon: "exclamationmark.triangle.fill")
                }
            }
        }
    }

    /// Admin: keur een VOG goed (status geldig + vog_valid). Verloopdatum = nu + renewal-jaren.
    func adminApproveVOG(buddyId: UUID) {
        let expires = Calendar.current.date(byAdding: .year, value: Config.vogRenewalYears, to: Date()) ?? Date()
        pendingVOGs.removeAll { $0.id == buddyId }
        showToast(text: "VOG goedgekeurd.", icon: "checkmark.seal.fill")
        guard isLive else { return }
        Task { try? await profileService.approveVOG(buddyId: buddyId, expiresAt: expires) }
    }

    /// Admin: wijs een VOG af.
    func adminRejectVOG(buddyId: UUID) {
        pendingVOGs.removeAll { $0.id == buddyId }
        showToast(text: "VOG afgewezen.", icon: "xmark.circle.fill")
        guard isLive else { return }
        Task { try? await profileService.rejectVOG(buddyId: buddyId) }
    }

    // MARK: - Intake-videogesprek

    /// Buddy start een intake-videogesprek → in de wachtrij (of demo: direct verbonden).
    func startIntakeCall() {
        if !isLive {
            // Demo: meteen "verbonden" met een nep-gesprek (geen echte wachtrij).
            myIntakeCall = ProfileService.DBIntakeCall(
                id: UUID(), buddyId: buddyUser.id, status: "in_progress",
                roomName: "demo", adminId: nil, createdAt: "",
                scheduledAt: nil, meetingUrl: nil, profile: nil
            )
            intakeQueuePosition = 0
            intakeQueueTotal = 0
            return
        }
        guard let userId = realUserId else { return }
        let room = UUID().uuidString
        Task {
            if let call = try? await profileService.requestIntakeCall(buddyId: userId, roomName: room) {
                await MainActor.run { self.myIntakeCall = call }
                await refreshMyIntakeCall()
            }
        }
    }

    /// Buddy plant zelf een intakegesprek op een gekozen moment. Zo hoeft niemand
    /// te gokken of hij aan de beurt komt. Het geplande gesprek verschijnt als
    /// afspraak op het profiel en in de admin-planning.
    func scheduleIntakeCall(at date: Date) {
        let room = UUID().uuidString
        if !isLive {
            // Demo: alleen lokaal tonen, geen serveractie.
            let iso = ISO8601DateFormatter().string(from: date)
            myScheduledCall = ProfileService.DBIntakeCall(
                id: UUID(), buddyId: buddyUser.id, status: "scheduled",
                roomName: room, adminId: nil, createdAt: "",
                scheduledAt: iso, meetingUrl: nil, profile: nil
            )
            showToast(text: "Intakegesprek ingepland.", icon: "calendar.badge.checkmark")
            return
        }
        guard let userId = realUserId else { return }
        Task {
            do {
                let call = try await profileService.scheduleIntakeCall(
                    buddyId: userId, roomName: room, scheduledAt: date, meetingUrl: nil
                )
                await MainActor.run {
                    self.myScheduledCall = call
                    self.showToast(text: "Intakegesprek ingepland.", icon: "calendar.badge.checkmark")
                }
            } catch {
                await MainActor.run {
                    self.showToast(text: "Inplannen mislukt, probeer opnieuw.",
                                   icon: "exclamationmark.triangle.fill")
                }
            }
        }
    }

    /// Ververs het eigen geplande gesprek (voor het profielscherm).
    func refreshMyScheduledCall() async {
        guard isLive, let userId = realUserId else { return }
        let call = try? await profileService.fetchMyScheduledCall(buddyId: userId)
        await MainActor.run { self.myScheduledCall = call }
    }

    /// Buddy annuleert zijn geplande intakegesprek.
    func cancelScheduledIntakeCall() {
        let call = myScheduledCall
        myScheduledCall = nil
        showToast(text: "Afspraak geannuleerd.", icon: "calendar.badge.minus")
        if isLive, let id = call?.id {
            Task { try? await profileService.cancelIntakeCall(callId: id) }
        }
    }

    /// Ververs status + wachtrijpositie van het eigen gesprek (poll vanuit het belscherm).
    func refreshMyIntakeCall() async {
        guard isLive, let userId = realUserId else { return }
        let previous = await MainActor.run { self.myIntakeCall }
        let active = try? await profileService.fetchMyActiveCall(buddyId: userId)
        var pos = 0, total = 0
        if let call = active, let status = try? await profileService.fetchQueueStatus(callId: call.id) {
            pos = status.position; total = status.totalWaiting
        }
        await MainActor.run {
            self.myIntakeCall = active
            self.intakeQueuePosition = pos
            self.intakeQueueTotal = total
        }
        // Gesprek nét afgelopen (in_progress → weg): de admin heeft mogelijk
        // goedgekeurd. Ververs meteen de verificatiestatus, zodat de buddy direct
        // "geverifieerd" ziet zonder op de poll van 30s te hoeven wachten.
        if previous != nil && active == nil {
            await refreshBuddyVerification()
        }
    }

    /// Realtime-ish: haalt de eigen VOG- en intakestatus op en neemt die over.
    /// Toont een melding zodra die net is veranderd (goedgekeurd/afgewezen) — zo
    /// ziet de buddy het ook als de app openstaat (push dekt de achtergrond).
    /// Wordt periodiek aangeroepen ("om de zoveel tijd checken") + bij terugkeer
    /// in de app + direct na een intakegesprek.
    func refreshBuddyVerification() async {
        guard isLive, let userId = realUserId else { return }
        guard let bp = try? await profileService.fetchBuddyProfile(userId: userId) else { return }
        let newVogValid = bp.vogValid ?? false
        let newVogStatus = VOGStatus(rawValue: bp.vogStatus ?? "") ?? .nietAangevraagd
        let newIntake = bp.intakeCompleted ?? false

        await MainActor.run {
            let wasVogValid  = self.buddyUser.vogValid
            let wasVogStatus = self.buddyUser.vogStatus
            let wasIntake    = self.buddyUser.intakeCompleted

            self.buddyUser.vogValid = newVogValid
            self.buddyUser.vogStatus = newVogStatus
            self.buddyUser.intakeCompleted = newIntake
            if let idx = self.allBuddies.firstIndex(where: { $0.id == self.buddyUser.id }) {
                self.allBuddies[idx].vogValid = newVogValid
                self.allBuddies[idx].intakeCompleted = newIntake
            }

            // In-app meldingen bij een échte overgang.
            if !wasVogValid && newVogValid {
                self.showToast(text: "Je VOG is goedgekeurd 🎉", icon: "checkmark.seal.fill")
            } else if wasVogStatus != .afgewezen && newVogStatus == .afgewezen {
                self.showToast(text: "Je VOG is afgewezen. Bekijk je profiel.", icon: "xmark.seal.fill")
            }
            if !wasIntake && newIntake {
                self.showToast(text: "Je intake is goedgekeurd 🎉", icon: "checkmark.seal.fill")
            }
        }
    }

    /// Buddy annuleert / verlaat het gesprek.
    func leaveIntakeCall() {
        let call = myIntakeCall
        myIntakeCall = nil
        intakeQueuePosition = 0
        intakeQueueTotal = 0
        if isLive, let id = call?.id {
            Task { try? await profileService.cancelIntakeCall(callId: id) }
        }
    }

    /// Geschatte wachttijd in minuten (≈ 4 min per gesprek vóór je).
    var intakeEtaMinutes: Int { max(0, (intakeQueuePosition - 1)) * 4 }

    // MARK: Admin-kant

    func adminRefreshWaitingCalls() {
        guard isLive else { return }
        Task {
            let calls = (try? await profileService.fetchWaitingCalls()) ?? []
            await MainActor.run { self.waitingCalls = calls }
        }
    }

    /// Admin: ververs de planning met de zelf-ingeplande intakegesprekken.
    func adminRefreshScheduledCalls() {
        guard isLive else { return }
        Task {
            let calls = (try? await profileService.fetchScheduledCalls()) ?? []
            await MainActor.run { self.scheduledCalls = calls }
        }
    }

    func adminAnswerCall(_ call: ProfileService.DBIntakeCall) {
        guard isLive, let adminId = realUserId else { return }
        Task {
            try? await profileService.answerIntakeCall(callId: call.id, adminId: adminId)
            await MainActor.run { self.adminRefreshWaitingCalls() }
        }
    }

    /// Admin keurt de intake goed tijdens/na het gesprek en sluit het af.
    func adminApproveIntakeAndEndCall(_ call: ProfileService.DBIntakeCall) {
        waitingCalls.removeAll { $0.id == call.id }
        showToast(text: "Intake goedgekeurd.", icon: "checkmark.seal.fill")
        guard isLive else { return }
        Task {
            try? await profileService.approveIntake(buddyId: call.buddyId)
            try? await profileService.endIntakeCall(callId: call.id)
            await MainActor.run { self.adminRefreshWaitingCalls() }
        }
    }

    func adminEndCall(_ call: ProfileService.DBIntakeCall) {
        waitingCalls.removeAll { $0.id == call.id }
        guard isLive else { return }
        Task {
            try? await profileService.endIntakeCall(callId: call.id)
            await MainActor.run { self.adminRefreshWaitingCalls() }
        }
    }

    /// Admin wijst de buddy af (niet vertrouwd): VOG → afgewezen + vog_valid false
    /// (buddy kan geen taken aannemen) en het gesprek wordt afgesloten.
    func adminRejectBuddyAndEndCall(_ call: ProfileService.DBIntakeCall) {
        waitingCalls.removeAll { $0.id == call.id }
        showToast(text: "Buddy afgewezen.", icon: "xmark.octagon.fill")
        guard isLive else { return }
        Task {
            try? await profileService.rejectVOG(buddyId: call.buddyId)
            try? await profileService.endIntakeCall(callId: call.id)
            await MainActor.run { self.adminRefreshWaitingCalls() }
        }
    }

    // MARK: - Gebruikersbeheer (admin)

    func adminLoadUsers() {
        guard isLive else { return }
        Task {
            let users = (try? await profileService.fetchAllProfiles()) ?? []
            await MainActor.run { self.allUsers = users }
        }
    }

    /// Wijzig de rol van een gebruiker (promoveren/degraderen).
    func adminSetUserRole(userId: UUID, role: UserRole) {
        if let idx = allUsers.firstIndex(where: { $0.id == userId }) {
            let u = allUsers[idx]
            allUsers[idx] = DBProfile(
                id: u.id, role: role.rawValue, firstName: u.firstName,
                lastName: u.lastName, phoneNumber: u.phoneNumber, createdAt: u.createdAt,
                organizationKey: u.organizationKey
            )
        }
        showToast(text: "Rol gewijzigd naar \(role.displayName).", icon: "person.badge.shield.checkmark")
        guard isLive else { return }
        Task {
            try? await profileService.setUserRole(userId: userId, role: role.rawValue)
            await MainActor.run { self.adminLoadUsers() }
        }
    }
}
