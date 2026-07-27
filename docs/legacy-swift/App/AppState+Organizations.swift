//  AppState+Organizations.swift
//  Onderdeel van AppState — Organisatie-lidmaatschap & koppelcodes.
//  Puur verplaatst uit AppState.swift bij de herstructurering (geen gedragswijziging).

import SwiftUI
import Foundation
import CoreLocation

extension AppState {

    // MARK: - Organisatie methoden

    func submitMembershipRequest(organization: Organization, proofNote: String) {
        let role = pendingRole ?? currentRole ?? .buddy
        let name = role == .buddy ? buddyUser.fullName : elderlyUser.fullName
        let membership = OrganizationMembership(
            id: UUID(),
            userId: realUserId ?? UUID(),
            userName: name,
            userRole: role,
            organizationId: organization.id,
            status: .pending,
            proofNote: proofNote,
            submittedAt: Date()
        )
        currentUserMembership = membership
        allMemberships.append(membership)
        selectedOrganization = organization
        // Onthoud de herkomst: de naam van de organisatie komt op het profiel te
        // staan. De huisstijl blijft de standaard Thuisverzorgd-stijl.
        organizationName = organization.name
    }

    func approveMembership(id: UUID) {
        guard let idx = allMemberships.firstIndex(where: { $0.id == id }) else { return }
        allMemberships[idx].status = .approved
        allMemberships[idx].reviewedAt = Date()
        if currentUserMembership?.id == id {
            currentUserMembership = allMemberships[idx]
        }
        showToast(text: "Aanvraag goedgekeurd", icon: "checkmark.seal.fill")
    }

    func rejectMembership(id: UUID, reason: String = "") {
        guard let idx = allMemberships.firstIndex(where: { $0.id == id }) else { return }
        allMemberships[idx].status = .rejected
        allMemberships[idx].reviewedAt = Date()
        allMemberships[idx].adminNote = reason.isEmpty ? nil : reason
        if currentUserMembership?.id == id {
            currentUserMembership = allMemberships[idx]
        }
        showToast(text: "Aanvraag afgewezen", icon: "xmark.circle.fill")
    }

    // MARK: - Koppelcode-methoden

    /// Zoekt een geldige koppelcode (hoofdletterongevoelig). Geeft nil als onbekend/ongeldig.
    func validatePartnerCode(_ raw: String) -> PartnerCode? {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return nil }
        return partnerCodes.first { $0.code.uppercased() == code && $0.isValid }
    }

    /// Wisselt een koppelcode in voor de cliënt: verhoogt de teller en geeft toegang.
    @discardableResult
    func redeemPartnerCode(_ raw: String) -> PartnerCode? {
        guard let match = validatePartnerCode(raw) else { return nil }
        if let idx = partnerCodes.firstIndex(where: { $0.id == match.id }) {
            partnerCodes[idx].usedCount += 1
        }
        passElderlyLinkingCodeGate()
        return match
    }

    /// Admin: genereer een nieuwe koppelcode voor een partner.
    @discardableResult
    func generatePartnerCode(partnerName: String, partnerType: PartnerType,
                             maxUses: Int?, expiresAt: Date?) -> PartnerCode {
        let code = Self.makeCode(for: partnerName)
        let pc = PartnerCode(
            id: UUID(),
            code: code,
            partnerName: partnerName.isEmpty ? partnerType.displayName : partnerName,
            partnerType: partnerType,
            maxUses: maxUses,
            usedCount: 0,
            isActive: true,
            createdAt: Date(),
            expiresAt: expiresAt
        )
        partnerCodes.insert(pc, at: 0)
        // Live: bewaar de koppelcode in Supabase zodat cliënten 'm echt kunnen inwisselen.
        if isLive {
            Task {
                try? await TaskService().createPartnerCode(
                    code: code,
                    partnerName: pc.partnerName,
                    partnerType: partnerType.rawValue,
                    maxUses: maxUses,
                    expiresAt: expiresAt
                )
            }
        }
        showToast(text: "Koppelcode \(code) aangemaakt", icon: "qrcode")
        return pc
    }

    func deactivatePartnerCode(id: UUID) {
        guard let idx = partnerCodes.firstIndex(where: { $0.id == id }) else { return }
        partnerCodes[idx].isActive = false
        showToast(text: "Koppelcode ingetrokken", icon: "xmark.circle.fill")
    }

    /// Maakt een korte, leesbare code op basis van de partnernaam + willekeurig achtervoegsel.
    private static func makeCode(for partnerName: String) -> String {
        let letters = partnerName.uppercased().filter { $0.isLetter }
        let prefix = letters.isEmpty ? "TVZ" : String(letters.prefix(5))
        let digits = String(format: "%03d", Int.random(in: 0...999))
        return "\(prefix)\(digits)"
    }
}
