//  AppStateLive+BuddyProfile.swift
//  Live-laag van AppState — buddy-profiel opslaan & locatie volgen.
//  Puur verplaatst uit AppStateLive.swift bij de herstructurering (geen gedragswijziging).

import Foundation
import CoreLocation
import SwiftUI

extension AppState {

    /// Bewaart de "Over mij"-tekst (bio) van de buddy — lokaal én, live, in de DB.
    func saveBuddyBio(_ bio: String) {
        let trimmed = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        buddyUser.bio = trimmed
        guard isLive, currentRole == .buddy, let id = realUserId else {
            showToast(text: "Opgeslagen", icon: "checkmark.circle.fill")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await ProfileService().updateBuddyBio(buddyId: id, bio: trimmed)
                await MainActor.run { self.showToast(text: "Opgeslagen", icon: "checkmark.circle.fill") }
            } catch {
                await MainActor.run { self.showToast(text: "Opslaan mislukt, probeer opnieuw", icon: "exclamationmark.triangle.fill") }
            }
        }
    }

    /// Bewaart het thuisadres van de buddy: geocodeert het en slaat adres +
    /// coördinaat op (lokaal én, live, in buddy_profiles). Zo kan de server
    /// "hulpvraag in je buurt"-pushes op afstand filteren (fase22).
    func saveBuddyAddress(_ address: String, coordinate: CLLocationCoordinate2D? = nil) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        buddyUser.address = trimmed
        let isLiveNow = isLive
        let id = realUserId
        Task { [weak self] in
            guard let self else { return }
            // Voorkeur: exacte coördinaat uit de adres-autocomplete; anders geocoderen.
            let coord: CLLocationCoordinate2D?
            if let coordinate {
                coord = coordinate
            } else {
                coord = await AddressGeocoder.coordinate(for: trimmed)
            }
            if let coord {
                await MainActor.run { self.buddyUser.coordinate = coord }
            }
            if isLiveNow, let id {
                try? await ProfileService().updateBuddyLocation(
                    buddyId: id, address: trimmed,
                    latitude: coord?.latitude, longitude: coord?.longitude
                )
            }
            await MainActor.run {
                self.showToast(
                    text: coord != nil ? "Adres opgeslagen" : "Adres opgeslagen, maar de locatie is niet gevonden. Controleer 'm",
                    icon: coord != nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
            }
        }
    }

    /// Zet bij registratie de buddy-locatie op basis van de postcode (geocode →
    /// coördinaat), zodat hulpvragen in de buurt meteen kloppen. Stil (geen toast);
    /// de buddy kan z'n adres later op het profiel verfijnen.
    func saveBuddyLocationFromPostcode(_ postcode: String) {
        let trimmed = postcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        buddyUser.address = trimmed
        let isLiveNow = isLive
        let id = realUserId
        Task { [weak self] in
            guard let self else { return }
            let coord = await AddressGeocoder.coordinate(for: "\(trimmed), Nederland")
            if let coord {
                await MainActor.run { self.buddyUser.coordinate = coord }
            }
            if isLiveNow, let id {
                try? await ProfileService().updateBuddyLocation(
                    buddyId: id, address: trimmed,
                    latitude: coord?.latitude, longitude: coord?.longitude
                )
            }
        }
    }

    /// Bewaart de volledige geboortedatum van de buddy (lokaal + in live-modus in
    /// buddy_profiles). Houdt het geboortejaar in sync voor de analytics.
    func saveBuddyDateOfBirth(_ date: Date) {
        buddyUser.dateOfBirth = date
        buddyUser.birthYear = Calendar.current.component(.year, from: date)
        guard isLive, let id = realUserId else { return }
        Task {
            try? await ProfileService().updateBuddyDateOfBirth(buddyId: id, date: date)
        }
    }

    /// Punt 13: regelt per gegeven of het zichtbaar is voor anderen. Werkt de
    /// vlaggen lokaal bij en (live) in buddy_profiles.
    func setBuddyFieldVisibility(bio: Bool? = nil, neighborhood: Bool? = nil, birthDate: Bool? = nil) {
        if let bio { buddyUser.showsBio = bio }
        if let neighborhood { buddyUser.showsNeighborhood = neighborhood }
        if let birthDate { buddyUser.showsBirthDate = birthDate }
        guard isLive, currentRole == .buddy, let id = realUserId else { return }
        let b = buddyUser.showsBio, n = buddyUser.showsNeighborhood, bd = buddyUser.showsBirthDate
        Task { try? await ProfileService().updateBuddyVisibility(
            buddyId: id, showsBio: b, showsNeighborhood: n, showsBirthdate: bd) }
    }

    /// Punt 13: idem voor de oudere (elderly_profiles).
    func setElderlyFieldVisibility(phone: Bool? = nil, address: Bool? = nil, birthDate: Bool? = nil) {
        if let phone { elderlyUser.showsPhone = phone }
        if let address { elderlyUser.showsAddress = address }
        if let birthDate { elderlyUser.showsBirthDate = birthDate }
        guard isLive, currentRole == .elderly, let id = realUserId else { return }
        let p = elderlyUser.showsPhone, a = elderlyUser.showsAddress, bd = elderlyUser.showsBirthDate
        Task { try? await ProfileService().updateElderlyVisibility(
            elderlyId: id, showsPhone: p, showsAddress: a, showsBirthdate: bd) }
    }

    // MARK: Live locatie buddy (500m-meldingen onderweg)

    /// Begint de huidige locatie van de buddy bij te houden, mits live + buddy +
    /// beschikbaar. De positie wordt (afgeknepen) naar Supabase geschreven.
    func startBuddyLocationTrackingIfNeeded() {
        // Volg de locatie zolang de buddy beschikbaar is óf een taak onderweg heeft
        // (zodat de oudere de buddy live kan volgen). Bewust grof (~100 m,
        // significante wijzigingen) om de batterij te sparen.
        guard isLive, currentRole == .buddy, let id = realUserId,
              isAvailableNow || activeTaskForBuddy != nil else { return }
        BuddyLocationManager.shared.onLocationUpdate = { coord in
            Task { try? await ProfileService().updateBuddyCurrentLocation(
                buddyId: id, latitude: coord.latitude, longitude: coord.longitude) }
        }
        BuddyLocationManager.shared.start()
        BuddyLocationManager.shared.requestOneShot()
    }

    func stopBuddyLocationTracking() {
        BuddyLocationManager.shared.stop()
        BuddyLocationManager.shared.onLocationUpdate = nil
    }
}
