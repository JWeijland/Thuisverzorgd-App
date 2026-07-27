import Foundation

// ============================================================
// Berichten & navigatie-bestemmingen (punt 10, feedback batch 2)
// ============================================================

/// Eén bericht in een 1-op-1 gesprek, klaar voor weergave in ConversationView.
/// `isMine` bepaalt of de bel links (ander) of rechts (ik) staat.
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let isMine: Bool
    let body: String
    let date: Date
}

/// Bestemming waar een inbox-bericht naartoe navigeert. Wordt vanuit de inbox
/// gezet en door BuddyMapView opgepakt om de juiste pagina te openen.
enum InboxDestination: Equatable {
    /// De teams-pagina; met een teamId opent hij meteen dat specifieke team.
    case teams(teamId: UUID?)
    /// De competitie-pagina; opent zo mogelijk direct de eigen actieve competitie.
    case competition
    /// De kaart met hulpvragen (het huidige scherm) — sluit alleen de inbox.
    case map
    /// Een specifiek hulpverzoek openen om aan te nemen (id nil = val terug op de
    /// lijst met open hulpvragen).
    case task(id: UUID?)
    /// Een 1-op-1 gesprek met de betreffende persoon.
    case conversation(partnerId: UUID?, partnerName: String)
    /// Zorgkring-pivot (fase35): een specifieke zorgkring openen (schema,
    /// leden, join-verzoeken).
    case careTeam(careTeamId: UUID?)
    /// Een openstaande team-uitnodiging voor deze buddy openen.
    case teamInvite(careTeamId: UUID?)
}

/// Doel van een gesprek, geschikt voor `.sheet(item:)`.
struct ConversationTarget: Identifiable, Equatable {
    let partnerId: UUID?
    let partnerName: String
    /// Sheet-identiteit: op partner-id, of op naam als er (nog) geen id is.
    var id: String { partnerId?.uuidString ?? partnerName }
}
