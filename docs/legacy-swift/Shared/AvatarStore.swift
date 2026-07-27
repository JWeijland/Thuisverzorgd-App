//  AvatarStore.swift
//  Verplaatst uit BuddyPoolView.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import UIKit
import Combine
import Supabase

/// Bewaart de profielfoto van de ingelogde buddy.
///
/// PRIVACY — belangrijk: de foto wordt **per gebruiker** bewaard (sleutel met de
/// user-UUID) en bij het wisselen/uitloggen van een account uit het geheugen
/// gewist. Zo kan de foto van de ene gebruiker nooit bij een andere gebruiker op
/// hetzelfde apparaat verschijnen. (De vroegere versie gebruikte één globale
/// sleutel en lekte daardoor de foto naar elk volgend account — zie `configure`.)
///
/// De foto wordt lokaal gecachet voor directe weergave en offline gebruik, en in
/// live-modus ook naar Supabase geüpload (buckets `avatars`, pad `<uid>.jpg`).
/// Bij inloggen op een nieuw apparaat wordt de eigen foto uit Supabase hersteld.
@MainActor
final class AvatarStore: ObservableObject {
    static let shared = AvatarStore()

    @Published var image: UIImage?

    /// De gebruiker van wie de foto nu in `image` staat. nil = niemand ingelogd.
    /// Wordt gebruikt als bewaking tegen races (gebruiker wisselt tijdens download)
    /// en om te voorkomen dat zonder ingelogde gebruiker iets wordt bewaard.
    private(set) var userId: UUID?

    /// Oude, onveilige globale sleutel. Wordt bij het opstarten verwijderd zodat de
    /// gelekte foto van een vorige gebruiker definitief van het apparaat verdwijnt.
    private static let legacyGlobalKey = "buddy.avatar.v1"

    nonisolated init() {
        // Privacy-migratie: wis de oude globale sleutel onherroepelijk.
        UserDefaults.standard.removeObject(forKey: Self.legacyGlobalKey)
    }

    private func key(for userId: UUID) -> String { "buddy.avatar.v2.\(userId.uuidString)" }

    /// Koppelt de store aan de ingelogde gebruiker en laadt diens eigen, lokaal
    /// bewaarde foto (of leeg). Wist altijd eerst de huidige foto, zodat er nooit
    /// een foto van een ander account zichtbaar blijft.
    func configure(for userId: UUID?) {
        self.userId = userId
        guard let userId else { image = nil; return }
        if let data = UserDefaults.standard.data(forKey: key(for: userId)) {
            image = UIImage(data: data)
        } else {
            image = nil
        }
    }

    /// Wist de in-memory foto bij uitloggen. De per-gebruiker cache op schijf blijft
    /// staan (zodat de eigen foto bij opnieuw inloggen direct terug is) maar wordt
    /// nooit aan een ander getoond, omdat de sleutel de user-UUID bevat.
    func clearForSignOut() {
        userId = nil
        image = nil
    }

    /// Bewaart een nieuwe foto voor de huidige gebruiker (lokaal + in-memory).
    /// Zonder bekende gebruiker (bijv. demo) wordt alleen in-memory getoond, niet
    /// op schijf bewaard.
    func set(_ data: Data?) {
        guard let userId else {
            image = data.flatMap(UIImage.init(data:))
            return
        }
        let k = key(for: userId)
        if let data {
            UserDefaults.standard.set(data, forKey: k)
            image = UIImage(data: data)
        } else {
            UserDefaults.standard.removeObject(forKey: k)
            image = nil
        }
    }

    /// Herstelt bij inloggen de eigen foto uit Supabase als we lokaal nog niets
    /// hebben (bijv. op een nieuw apparaat). Faalt stil — de fallback-avatar blijft.
    func loadFromServerIfNeeded(buddyId: UUID, hasServerAvatar: Bool) async {
        guard hasServerAvatar, userId == buddyId, image == nil else { return }
        let path = "\(buddyId.uuidString.lowercased()).jpg"
        guard let data = try? await supabase.storage.from("avatars").download(path: path) else { return }
        // Gebruiker kan tijdens de download zijn gewisseld → opnieuw controleren.
        guard userId == buddyId else { return }
        UserDefaults.standard.set(data, forKey: key(for: buddyId))
        image = UIImage(data: data)
    }
}

/// Tijdelijke (signed) foto-URL's van ándere gebruikers, voor de druppels op
/// de kaart en de teamleden-avatars. De avatars-bucket is privé; per gebruiker
/// halen we een signed URL (1 uur geldig) op en cachen die ~50 minuten.
/// Bestaat er geen foto, dan onthouden we dat ook (geen herhaalde requests).
@MainActor
final class BuddyPhotoCache: ObservableObject {
    static let shared = BuddyPhotoCache()

    @Published private(set) var urls: [UUID: URL] = [:]
    private var fetchedAt: [UUID: Date] = [:]
    private var inflight: Set<UUID> = []

    func url(for userId: UUID) -> URL? { urls[userId] }

    /// Zorgt dat er (op den duur) een signed URL voor deze gebruiker is.
    /// Faalt stil: zonder foto blijft de initiaal-terugval staan.
    func ensure(_ userId: UUID) {
        let maxAge: TimeInterval = 50 * 60
        if let stamp = fetchedAt[userId], Date().timeIntervalSince(stamp) < maxAge { return }
        guard !inflight.contains(userId) else { return }
        inflight.insert(userId)
        Task {
            let url = try? await ProfileService().avatarSignedURL(buddyId: userId)
            self.fetchedAt[userId] = Date()
            self.inflight.remove(userId)
            if let url { self.urls[userId] = url }
        }
    }

    /// Privacy: cache leegmaken bij uitloggen/accountwissel.
    func clearForSignOut() {
        urls = [:]
        fetchedAt = [:]
        inflight = []
    }
}

/// Toont de foto van een lid: eigen foto (AvatarStore) of een opgeslagen
/// photoURL (andere buddies), met een SF-avatar als terugval.
struct MemberAvatar: View {
    let member: PoolMember
    var size: CGFloat = 40
    var tint: Color = BCColors.textTertiary
    @ObservedObject private var avatars = AvatarStore.shared

    var body: some View {
        Group {
            if member.isCurrentUser, let img = avatars.image {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let urlString = member.photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image { img.resizable().scaledToFill() }
                    else { fallback }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallback: some View {
        ZStack {
            Color.clear
            Image(systemName: member.avatar)
                .font(.system(size: size * 0.62))
                .foregroundStyle(member.isCurrentUser ? tint : BCColors.textTertiary)
        }
    }
}
