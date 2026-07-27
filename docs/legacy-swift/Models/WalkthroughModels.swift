import SwiftUI

// ============================================================
// Walkthrough — "Hoe het werkt"-rondleiding per rol (punt 9, feedback batch 2)
//
// Een korte carrousel die na de registratie 1 keer verschijnt. Elke stap toont
// een nagebootste knop met een pijltje ernaartoe en een korte uitleg van wat die
// knop doet. Per rol een eigen variant (buddy, ouderen, familie).
// ============================================================

/// Richting waarin het callout-pijltje wijst (naar de knop toe).
enum WalkthroughArrow {
    case down   // pijl staat boven de knop en wijst omlaag
    case up     // pijl staat onder de knop en wijst omhoog
}

struct WalkthroughStep: Identifiable {
    let id = UUID()
    /// Icoon van de bedoelde knop (SF Symbol of asset-naam).
    let icon: String
    let iconIsAsset: Bool
    /// Kort label onder de nagebootste knop.
    let buttonLabel: String
    /// Accentkleur van de nagebootste knop.
    let tint: Color
    let arrow: WalkthroughArrow
    let title: String
    let text: String
}

enum RoleWalkthrough {
    static func steps(for role: UserRole) -> [WalkthroughStep] {
        switch role {
        case .buddy:   return buddy
        case .elderly: return elderly
        case .family:  return family
        case .admin:   return []
        }
    }

    // Buddy: je (informeel).
    static let buddy: [WalkthroughStep] = [
        .init(icon: "checkmark.circle.fill", iconIsAsset: false, buttonLabel: "Beschikbaar",
              tint: BCColors.accentDark, arrow: .down,
              title: "Zet jezelf op beschikbaar",
              text: "Met deze knop bovenin de kaart geef je aan dat je hulpvragen in de buurt wilt ontvangen. Zet 'm uit als je even geen tijd hebt."),
        .init(icon: "mappin.circle.fill", iconIsAsset: false, buttonLabel: "Hulpvraag",
              tint: BCColors.primary, arrow: .down,
              title: "Bekijk hulpvragen op de kaart",
              text: "Elke pin op de kaart is iemand die gezelschap of hulp zoekt. Tik op een pin om de vraag te bekijken en aan te nemen."),
        .init(icon: "envelope.fill", iconIsAsset: false, buttonLabel: "Berichten",
              tint: BCColors.primary, arrow: .down,
              title: "Je berichten",
              text: "Hier komen uitnodigingen en berichten binnen. Tik op een bericht om meteen naar de juiste pagina of naar het gesprek te gaan."),
        .init(icon: "tv-beker", iconIsAsset: true, buttonLabel: "Competitie & teams",
              tint: BCColors.primary, arrow: .up,
              title: "Sparen en samen doen",
              text: "Via de spelknoppen op de kaart bekijk je de competitie, je teams en je verdiende medailles."),
        .init(icon: "person.crop.circle", iconIsAsset: false, buttonLabel: "Profiel",
              tint: BCColors.primary, arrow: .up,
              title: "Jouw profiel",
              text: "Op je profiel vul je je gegevens aan, rond je de verificatie af en bepaal je zelf wat zichtbaar is voor anderen."),
    ]

    // Ouderen: u (formeel).
    static let elderly: [WalkthroughStep] = [
        .init(icon: "hand.raised.fill", iconIsAsset: false, buttonLabel: "Hulp vragen",
              tint: BCColors.primary, arrow: .down,
              title: "Vraag gezelschap of hulp",
              text: "Met de grote knop op het beginscherm vraagt u gezelschap of hulp in de buurt. U kiest zelf waarmee en wanneer."),
        .init(icon: "heart.fill", iconIsAsset: false, buttonLabel: "Mijn buddies",
              tint: BCColors.danger, arrow: .up,
              title: "Uw vaste buddies",
              text: "Hier ziet u de mensen die u eerder hebben geholpen. Vaste buddies krijgen voorrang als u hulp vraagt."),
        .init(icon: "exclamationmark.triangle.fill", iconIsAsset: false, buttonLabel: "SOS",
              tint: BCColors.danger, arrow: .up,
              title: "Hulp bij nood",
              text: "In geval van nood tikt u op de SOS-knop. Dan waarschuwen we direct de juiste mensen."),
        .init(icon: "person.crop.circle", iconIsAsset: false, buttonLabel: "Profiel",
              tint: BCColors.primary, arrow: .up,
              title: "Uw gegevens",
              text: "Bij uw profiel past u uw gegevens aan en bepaalt u zelf wat wel en niet zichtbaar is voor anderen."),
    ]

    // Familie: u (formeel).
    static let family: [WalkthroughStep] = [
        .init(icon: "square.grid.2x2.fill", iconIsAsset: false, buttonLabel: "Overzicht",
              tint: BCColors.primary, arrow: .down,
              title: "Volg hoe het gaat",
              text: "Op het overzicht ziet u in één oogopslag hoe het met uw naaste gaat en welke hulp er is geweest."),
        .init(icon: "clock.fill", iconIsAsset: false, buttonLabel: "Tijdlijn",
              tint: BCColors.primary, arrow: .up,
              title: "De tijdlijn",
              text: "In de tijdlijn ziet u alle bezoeken en activiteiten netjes op een rij."),
        .init(icon: "person.2.badge.plus", iconIsAsset: false, buttonLabel: "Koppelen",
              tint: BCColors.accentDark, arrow: .up,
              title: "Naasten koppelen",
              text: "Met een koppelcode koppelt u meerdere naasten, bijvoorbeeld vader én moeder, aan uw account."),
        .init(icon: "person.crop.circle", iconIsAsset: false, buttonLabel: "Profiel",
              tint: BCColors.primary, arrow: .up,
              title: "Uw profiel",
              text: "Bij uw profiel beheert u uw eigen gegevens en instellingen."),
    ]
}
