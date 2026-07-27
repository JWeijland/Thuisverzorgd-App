//  AppStateLive+CreateTask.swift
//  Live-laag van AppState — hulpvraag aanmaken (live).
//  Puur verplaatst uit AppStateLive.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import CoreLocation
import SwiftUI

extension AppState {

    // MARK: Hulpvraag aanmaken (live)

    /// Schrijft een echte hulpvraag naar Supabase. De DB-insert is meteen de
    /// trigger waarop (in Fase 2) de pushnotificatie naar beschikbare buddies hangt.
    func createTaskLive(category: TaskCategory, timing: TaskTiming, note: String) {
        guard let elderlyId = realUserId else { return }
        let elderly = elderlyUser
        let (type, scheduledAt) = Self.dbTiming(timing)

        Task { [weak self] in
            guard let self else { return }
            // Gebruik bij voorkeur de al-opgeslagen (bij profiel-opslag geocodeerde)
            // coördinaat van de hulpvrager — die is precies. Alleen wanneer die nog
            // ontbreekt (default Amsterdam-centrum) én er een adres is, geocoderen
            // we alsnog en bewaren we het resultaat. Zo komt de druppel op het echte
            // adres en "drijft" een precieze coördinaat niet weg door per hulpvraag
            // opnieuw te geocoderen.
            var coordinate = elderly.coordinate
            if !Self.isResolvedCoordinate(coordinate),
               !elderly.address.trimmingCharacters(in: .whitespaces).isEmpty,
               let geo = await AddressGeocoder.coordinate(for: elderly.address) {
                coordinate = geo
                try? await ProfileService().updateElderlyLocation(
                    elderlyId: elderlyId, address: elderly.address,
                    latitude: geo.latitude, longitude: geo.longitude
                )
                await MainActor.run { self.elderlyUser.coordinate = geo }
            }
            do {
                let db = try await TaskService().createTask(
                    elderlyId: elderlyId,
                    category: category.dbValue,
                    timingType: type,
                    scheduledAt: scheduledAt,
                    note: note,
                    elderlyFirstName: elderly.firstName,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                let task = Self.serviceTask(from: db)
                await MainActor.run {
                    self.activeTaskForElderly = task
                    self.showToast(text: "Je hulpvraag is verstuurd", icon: "paperplane.fill")
                    self.trackEvent(.helpRequested, category: category)
                }
            } catch {
                await MainActor.run {
                    self.showToast(text: "Versturen mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill")
                }
                print("[Live] createTask faalde: \(error)")
            }
        }
    }

    /// Live-variant van requestHelpOnBehalf: familie/admin maakt een hulpvraag
    /// voor een gekoppelde cliënt via de RPC. De locatie komt server-side van de
    /// cliënt, dus de druppel staat op het adres van de hulpvrager.
    func createTaskOnBehalfLive(for elderly: ElderlyUser, category: TaskCategory,
                                timing: TaskTiming, note: String) {
        let (type, scheduledAt) = Self.dbTiming(timing)
        let elderlyId = elderly.id
        let first = elderly.firstName
        Task { [weak self] in
            guard let self else { return }
            do {
                let db = try await TaskService().createTaskForElderly(
                    elderlyId: elderlyId, category: category.dbValue,
                    timingType: type, scheduledAt: scheduledAt, note: note
                )
                let task = Self.serviceTask(from: db)
                await MainActor.run {
                    self.activeTaskForElderly = task
                    self.showToast(text: "Aanvraag ingezet voor \(first)", icon: "phone.fill")
                }
            } catch {
                await MainActor.run {
                    self.showToast(text: "Versturen mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill")
                }
                print("[Live] createTaskForElderly faalde: \(error)")
            }
        }
    }
}
