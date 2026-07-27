//  AppStateLive+Sync.swift
//  Live-laag van AppState — live-synchronisatie van taken & taak accepteren.
//  Puur verplaatst uit AppStateLive.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import CoreLocation
import SwiftUI

extension AppState {

    // MARK: Open taken synchroniseren (buddy)

    /// Start het periodiek ophalen van open hulpvragen uit Supabase.
    /// (Eenvoudige poll van 5s; de échte directe melding komt via push in Fase 2.)
    func startBuddyTaskSync() {
        guard isLive, openTaskPollTask == nil else { return }
        openTaskPollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshOpenTasks()
                await self.refreshBuddyActiveTask()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    /// Controleert of de actieve taak van de buddy nog loopt. Is hij ingetrokken
    /// (cancelled) of niet meer aan déze buddy toegewezen, dan wissen we hem en
    /// tonen we een apart "hulpvraag ingetrokken"-scherm.
    func refreshBuddyActiveTask() async {
        guard isLive, let myId = realUserId else { return }
        // Niets in het geheugen? Haal een eventueel nog lopende toegewezen taak
        // terug (bv. na app-herstart) zodat de buddy 'm kan hervatten.
        guard let active = activeTaskForBuddy else {
            if let db = try? await TaskService().fetchMyAssignedActiveTask(buddyId: myId) {
                let restored = Self.serviceTask(from: db)
                await MainActor.run { self.activeTaskForBuddy = restored }
            }
            return
        }
        guard let db = try? await TaskService().fetchTask(id: active.id) else { return }
        let status = TaskStatus(dbValue: db.status)
        let stillMine = (db.assignedBuddyId == myId)
        let stillRunning = (status == .accepted || status == .arrived || status == .inProgress)
        guard !(stillMine && stillRunning) else { return }
        await MainActor.run {
            self.activeTaskForBuddy = nil
            self.openTasks.removeAll { $0.id == active.id }
            // Alleen een melding tonen als de taak echt is ingetrokken (niet als de
            // buddy zelf net heeft afgerond).
            if status == .cancelled || status == .open {
                self.buddyCancelledNotice = active.elderlyName
            }
        }
    }

    func stopBuddyTaskSync() {
        openTaskPollTask?.cancel()
        openTaskPollTask = nil
    }

    func refreshOpenTasks() async {
        guard let dbTasks = try? await TaskService().fetchOpenTasks() else { return }
        let mapped = dbTasks.map { Self.serviceTask(from: $0) }
        await MainActor.run { self.openTasks = mapped }
    }

    // MARK: Actieve hulpvraag van de oudere synchroniseren (live)

    /// Houdt de actieve hulpvraag van de oudere up-to-date met Supabase, zodat
    /// het scherm vanzelf meebeweegt met wat de buddy doet (aannemen → onderweg →
    /// ingecheckt → afgerond). Dit vervangt de oude demo-knoppen.
    func startElderlyTaskSync() {
        guard isLive, elderlyTaskPollTask == nil else { return }
        let elderlyId = elderlyUser.id

        // Realtime: reageer meteen op elke wijziging van de eigen taken (buddy
        // neemt aan, checkt in, of annuleert) zodat het cliëntscherm direct
        // meebeweegt — ook terwijl de oudere ernaar kijkt.
        elderlyTaskRealtimeTask = Task { [weak self] in
            await TaskService().subscribeToTaskUpdates(elderlyId: elderlyId) { _ in
                Task { await self?.refreshElderlyActiveTask() }
            }
        }

        // Poll als vangnet (als realtime even wegvalt). Snel genoeg om vlot bij
        // te werken, rustig genoeg voor het netwerk.
        elderlyTaskPollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshElderlyActiveTask()
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }

    func stopElderlyTaskSync() {
        elderlyTaskPollTask?.cancel()
        elderlyTaskPollTask = nil
        elderlyTaskRealtimeTask?.cancel()
        elderlyTaskRealtimeTask = nil
    }

    // MARK: Live locatie van de onderweg-zijnde buddy (voortgangsbalk + kaart)

    /// Houdt de positie van de toegewezen buddy bij terwijl die onderweg is, zodat
    /// de voortgangsbalk voller wordt naarmate hij dichterbij komt en de oudere de
    /// buddy live op de kaart kan volgen.
    func startBuddyLiveLocationSync() {
        guard isLive, buddyLiveLocationTask == nil else { return }
        buddyLiveLocationTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshBuddyLiveLocation()
                try? await Task.sleep(nanoseconds: 8_000_000_000) // elke 8 s
            }
        }
    }

    func stopBuddyLiveLocationSync() {
        buddyLiveLocationTask?.cancel()
        buddyLiveLocationTask = nil
        buddyLiveLatitude = nil
        buddyLiveLongitude = nil
        buddyRouteStartKm = nil
        buddyRouteProgress = 0
    }

    func refreshBuddyLiveLocation() async {
        // Alleen relevant als er een buddy is aangenomen en nog onderweg is.
        guard isLive,
              let task = activeTaskForElderly,
              task.status == .accepted,
              let buddyId = task.assignedBuddyId else {
            await MainActor.run {
                self.buddyLiveLatitude = nil
                self.buddyLiveLongitude = nil
                self.buddyRouteStartKm = nil
                self.buddyRouteProgress = 0
            }
            return
        }
        guard let loc = try? await ProfileService().fetchBuddyCurrentLocation(buddyId: buddyId),
              let lat = loc.currentLatitude, let lon = loc.currentLongitude else { return }

        let elderly = task.coordinate
        let meters = CLLocation(latitude: lat, longitude: lon)
            .distance(from: CLLocation(latitude: elderly.latitude, longitude: elderly.longitude))
        let distKm = meters / 1000

        await MainActor.run {
            self.buddyLiveLatitude = lat
            self.buddyLiveLongitude = lon
            // Baseline = de verste afstand die we tot nu toe zagen; daardoor groeit
            // de balk netjes naarmate de buddy dichterbij komt.
            let base = max(self.buddyRouteStartKm ?? distKm, distKm)
            self.buddyRouteStartKm = base
            let p = base > 0.02 ? (1 - distKm / base) : 1
            self.buddyRouteProgress = min(max(p, 0.04), 0.98)
        }
    }

    func refreshElderlyActiveTask() async {
        let elderlyId = elderlyUser.id
        guard let dbTasks = try? await TaskService().fetchTasksForElderly(elderlyId: elderlyId) else { return }
        // Meest recente nog lopende hulpvraag is de actieve.
        let active = dbTasks.first { db in
            let status = TaskStatus(dbValue: db.status)
            return status != .completed && status != .cancelled
        }

        // Geen lopende hulpvraag meer? Dan is een eerder actieve taak zojuist
        // afgerond of geannuleerd. Zonder deze afhandeling bleef het cliëntscherm
        // hangen op "we zoeken een buddy" (de oude code keerde hier vroeg terug en
        // werkte de status nooit bij naar .completed → geen beoordeling, geen
        // terugkeer naar home).
        guard let db = active else {
            await MainActor.run {
                guard let current = self.activeTaskForElderly, current.status != .completed else { return }
                guard let row = dbTasks.first(where: { $0.id == current.id }) else { return }
                switch TaskStatus(dbValue: row.status) {
                case .completed:
                    var done = Self.serviceTask(from: row)
                    done.assignedBuddyName = current.assignedBuddyName ?? done.assignedBuddyName
                    done.assignedBuddyRating = current.assignedBuddyRating ?? done.assignedBuddyRating
                    if done.completedAt == nil { done.completedAt = Date() }
                    if !self.taskHistory.contains(where: { $0.id == done.id }) {
                        self.taskHistory.insert(done, at: 0)
                    }
                    self.activeTaskForElderly = done   // status .completed → toont de beoordeling
                case .cancelled:
                    self.activeTaskForElderly = nil    // terug naar home, geen beoordeling
                default:
                    break
                }
            }
            return
        }

        var task = Self.serviceTask(from: db)
        let status = TaskStatus(dbValue: db.status)
        let hasBuddy = (status == .accepted || status == .arrived || status == .inProgress)
        // Naam + telefoonnummer van de toegewezen buddy ophalen (mapping levert die
        // niet mee). Het nummer geven we alleen door zolang de taak actief is, zodat
        // de oudere de juiste buddy kan bellen (punt 2) en het nummer niet daarbuiten
        // rondslingert.
        if let buddyId = db.assignedBuddyId,
           let profile = try? await ProfileService().fetchProfile(userId: buddyId) {
            task.assignedBuddyName = profile.firstName
            if hasBuddy { task.assignedBuddyPhone = profile.phoneNumber }
        }
        await MainActor.run {
            // Val alleen terug op een eerder bekende buddynaam zolang er ook echt
            // een buddy gekoppeld is. Bij heropenen (status 'open') NIET — anders
            // blijft de oude buddynaam hangen terwijl we juist weer zoeken.
            if task.assignedBuddyName == nil && hasBuddy {
                task.assignedBuddyName = self.activeTaskForElderly?.assignedBuddyName
            }
            // Overgang van "buddy gevonden/onderweg" terug naar "zoeken": de buddy
            // heeft geannuleerd. Toon dat meteen op het scherm (de pushmelding komt
            // er los van — dit is voor wie nét naar de app kijkt).
            if let prev = self.activeTaskForElderly, prev.id == task.id, !hasBuddy {
                let wasWithBuddy = (prev.status == .accepted || prev.status == .arrived || prev.status == .inProgress)
                if wasWithBuddy {
                    self.showToast(text: "Je buddy moest annuleren. We zoeken een nieuwe buddy voor je.",
                                   icon: "arrow.triangle.2.circlepath")
                }
            }
            self.activeTaskForElderly = task
        }
    }

    // MARK: Taak accepteren (live)

    func buddyAcceptsTaskLive(_ task: ServiceTask) async {
        guard let buddyId = realUserId else { return }
        let eta = Int.random(in: 6...15)
        do {
            // Atomische claim: alleen als déze buddy 'm echt pakt gaan we door.
            let claimed = try await TaskService().acceptTask(taskId: task.id, etaMinutes: eta)
            guard claimed else {
                // Een andere buddy was net eerder — pin weghalen en netjes melden.
                await MainActor.run {
                    self.openTasks.removeAll { $0.id == task.id }
                    self.showToast(text: "Iemand was je net voor. Deze hulpvraag is al aangenomen.",
                                   icon: "exclamationmark.triangle.fill")
                }
                await refreshOpenTasks()
                return
            }
            var updated = task
            updated.status = .accepted
            updated.assignedBuddyName = buddyUser.firstName
            updated.assignedBuddyRating = buddyUser.ratingAverage
            updated.assignedBuddyEtaMinutes = eta
            updated.assignedBuddyId = buddyId
            updated.assignedBuddyPhone = buddyUser.phoneNumber
            await MainActor.run {
                self.openTasks.removeAll { $0.id == task.id }
                self.activeTaskForBuddy = updated
                self.trackEvent(.taskAccepted, category: task.category)
                // Locatie nu zeker volgen, zodat de oudere de buddy onderweg live ziet.
                self.startBuddyLocationTrackingIfNeeded()
                BuddyLocationManager.shared.requestOneShot()
            }
            // Direct verversen zodat de pin meteen weg is bij deze buddy; andere
            // buddies volgen via hun eigen poll (RLS toont 'm niet meer).
            await refreshOpenTasks()
        } catch {
            await MainActor.run {
                self.showToast(text: "Accepteren mislukt, probeer het opnieuw.", icon: "exclamationmark.triangle.fill")
            }
            print("[Live] acceptTask faalde: \(error)")
        }
    }
}
