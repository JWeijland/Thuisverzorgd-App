import SwiftUI

// ============================================================
// ConversationView — 1-op-1 gesprek buddy <-> hulpvrager (punt 10, fase30)
//
// Minimale v1: berichtenlijst + invoerveld. Live gepersisteerd in Supabase
// (direct_messages); in demo-modus lokaal bewaard in AppState.demoConversations.
// Bruikbaar door beide rollen (de "mine"-kant is altijd de ingelogde gebruiker).
// ============================================================

struct ConversationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let partnerId: UUID?
    let partnerName: String

    @State private var messages: [ChatMessage] = []
    @State private var draft: String = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty && loaded {
                    emptyState
                } else {
                    messageList
                }
                inputBar
            }
            .background(BCColors.background)
            .navigationTitle(partnerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sluit") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .task {
            messages = await appState.loadConversation(partnerId: partnerId, partnerName: partnerName)
            loaded = true
            // Live: rustig pollen zodat nieuwe berichten vanzelf binnenkomen.
            while !Task.isCancelled && appState.isLive && partnerId != nil {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                messages = await appState.loadConversation(partnerId: partnerId, partnerName: partnerName)
            }
        }
    }

    // MARK: Berichtenlijst

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: BCSpacing.sm) {
                    ForEach(messages) { msg in
                        bubble(msg).id(msg.id)
                    }
                }
                .padding(.horizontal, BCSpacing.lg)
                .padding(.vertical, BCSpacing.md)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
            .onAppear {
                if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.isMine { Spacer(minLength: 40) }
            VStack(alignment: msg.isMine ? .trailing : .leading, spacing: 2) {
                Text(msg.body)
                    .font(BCTypography.body)
                    .foregroundStyle(msg.isMine ? .white : BCColors.textPrimary)
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BCRadius.lg, style: .continuous)
                            .fill(msg.isMine ? AnyShapeStyle(BCColors.primary) : AnyShapeStyle(BCColors.surface))
                    )
                Text(timeLabel(msg.date))
                    .font(BCTypography.caption)
                    .foregroundStyle(BCColors.textTertiary)
            }
            if !msg.isMine { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: msg.isMine ? .trailing : .leading)
    }

    private var emptyState: some View {
        VStack(spacing: BCSpacing.sm) {
            Image("tv-chat")
                .resizable().scaledToFit().frame(width: 48, height: 48)
                .opacity(0.7)
            Text("Nog geen berichten")
                .font(BCTypography.headline)
                .foregroundStyle(BCColors.textPrimary)
            Text("Stuur \(partnerName) een berichtje om het gesprek te beginnen.")
                .font(BCTypography.subheadline)
                .foregroundStyle(BCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, BCSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Invoerbalk

    private var inputBar: some View {
        HStack(spacing: BCSpacing.sm) {
            TextField("Bericht", text: $draft, axis: .vertical)
                .font(BCTypography.body)
                .lineLimit(1...4)
                .padding(.horizontal, BCSpacing.md)
                .padding(.vertical, 10)
                .background(Capsule(style: .continuous).fill(BCColors.surface))
                .overlay(Capsule(style: .continuous).stroke(BCColors.border, lineWidth: 1))

            Button { send() } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(canSend ? BCColors.primary : BCColors.textTertiary))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, BCSpacing.md)
        .padding(.vertical, BCSpacing.sm)
        .background(BCColors.background)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        let body = draft
        draft = ""
        Task {
            messages = await appState.sendMessage(to: partnerId, partnerName: partnerName, body: body)
        }
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        if Calendar.current.isDateInToday(date) {
            f.dateFormat = "HH:mm"
        } else {
            f.dateFormat = "d MMM HH:mm"
        }
        return f.string(from: date)
    }
}

#Preview {
    ConversationView(partnerId: nil, partnerName: "Riet").environment(AppState())
}
