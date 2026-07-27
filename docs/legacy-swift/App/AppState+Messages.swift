//  AppState+Messages.swift
//  Punt 10 (feedback batch 2): 1-op-1 gesprekken tussen buddy en hulpvrager.
//  Live via Supabase (direct_messages); demo lokaal in demoConversations.

import Foundation

extension AppState {

    /// Sleutel waaronder een demo-gesprek wordt bewaard: partner-id of anders naam.
    func conversationKey(partnerId: UUID?, partnerName: String) -> String {
        partnerId?.uuidString ?? partnerName
    }

    /// Laadt een gesprek. Live: uit Supabase (en markeert ontvangen berichten als
    /// gelezen). Demo: uit de lokale store, met een vriendelijk startbericht als het
    /// gesprek nog leeg is.
    @discardableResult
    func loadConversation(partnerId: UUID?, partnerName: String) async -> [ChatMessage] {
        if isLive, let me = realUserId, let other = partnerId {
            try? await MessageService().markConversationRead(with: other, me: me)
            guard let rows = try? await MessageService().fetchConversation(with: other, me: me) else { return [] }
            return rows.map {
                ChatMessage(id: $0.id, isMine: $0.senderId == me, body: $0.body,
                            date: Self.parseISO($0.createdAt) ?? Date())
            }
        } else {
            let key = conversationKey(partnerId: partnerId, partnerName: partnerName)
            if demoConversations[key] == nil {
                demoConversations[key] = [
                    ChatMessage(id: UUID(), isMine: false,
                                body: "Hoi! Fijn dat we contact hebben. Tot binnenkort.",
                                date: Date().addingTimeInterval(-3600))
                ]
            }
            return demoConversations[key] ?? []
        }
    }

    /// Verstuurt een bericht en geeft het bijgewerkte gesprek terug. Live: via de RPC
    /// (die ook een inbox-melding voor de ontvanger aanmaakt). Demo: lokaal toevoegen.
    @discardableResult
    func sendMessage(to partnerId: UUID?, partnerName: String, body: String) async -> [ChatMessage] {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return await loadConversation(partnerId: partnerId, partnerName: partnerName)
        }
        if isLive, let other = partnerId {
            try? await MessageService().send(to: other, body: trimmed)
            return await loadConversation(partnerId: partnerId, partnerName: partnerName)
        } else {
            let key = conversationKey(partnerId: partnerId, partnerName: partnerName)
            var list = demoConversations[key] ?? []
            list.append(ChatMessage(id: UUID(), isMine: true, body: trimmed, date: Date()))
            demoConversations[key] = list
            return list
        }
    }
}
