import SwiftUI

// ============================================================
// TeamChatView — groepschat van een zorgkring (fase36)
//
// Twee duidelijk gescheiden kanalen:
//   • "Met hulpvrager & familie" — het hele team, inclusief de hulpvrager
//     en gekoppelde familie.
//   • "Alleen vrijwilligers"     — de buddies onderling (hulpvrager en
//     familie zien dit kanaal niet).
//
// Buddies zien bovenin een schakelaar tussen beide kanalen; de hulpvrager
// en familie zien alléén het gezamenlijke kanaal. Berichten worden live
// gepersisteerd (care_team_messages) en rustig gepolld; de rest van het
// team krijgt push + inbox via notify-team-event.
// ============================================================

struct TeamChatView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let teamId: UUID
    let teamName: String
    /// Welke kanalen deze kijker mag zien (buddy: beide; hulpvrager/familie:
    /// alleen .all).
    var channels: [TeamChatChannel] = [.all]
    var initialChannel: TeamChatChannel = .all

    @State private var channel: TeamChatChannel = .all
    @State private var messages: [TeamChatMessage] = []
    @State private var draft: String = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if channels.count > 1 {
                    channelPicker
                }
                channelBanner
                if messages.isEmpty && loaded {
                    emptyState
                } else {
                    messageList
                }
                inputBar
            }
            .background(BCColors.background)
            .navigationTitle(teamName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sluit") { dismiss() }.tint(BCColors.primary)
                }
            }
        }
        .task(id: channel) {
            loaded = false
            messages = await appState.loadTeamChat(teamId: teamId, channel: channel)
            loaded = true
            // Live: rustig pollen zodat nieuwe berichten vanzelf binnenkomen.
            while !Task.isCancelled && appState.isLive {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                messages = await appState.loadTeamChat(teamId: teamId, channel: channel)
            }
        }
        .onAppear {
            channel = channels.contains(initialChannel) ? initialChannel : (channels.first ?? .all)
        }
    }

    // MARK: Kanaal-keuze (alleen voor buddies)

    private var channelPicker: some View {
        Picker("Kanaal", selection: $channel) {
            ForEach(channels) { ch in
                Label(ch.label, systemImage: ch.icon).tag(ch)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, BCSpacing.lg)
        .padding(.top, BCSpacing.sm)
    }

    /// Maakt in één oogopslag duidelijk wie dit kanaal kan meelezen.
    private var channelBanner: some View {
        HStack(spacing: BCSpacing.xs) {
            Image(systemName: channel == .buddies ? "lock.fill" : "person.3.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(channel == .buddies
                 ? "Alleen de vrijwilligers van dit team lezen mee"
                 : "Het hele team leest mee, ook de hulpvrager en familie")
                .font(BCTypography.caption)
        }
        .foregroundStyle(channel == .buddies ? BCColors.accentDark : BCColors.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background((channel == .buddies ? BCColors.accent.opacity(0.14) : BCColors.surfaceMuted))
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

    private func bubble(_ msg: TeamChatMessage) -> some View {
        HStack {
            if msg.isMine { Spacer(minLength: 40) }
            VStack(alignment: msg.isMine ? .trailing : .leading, spacing: 2) {
                if !msg.isMine {
                    Text(msg.senderName)
                        .font(BCTypography.captionEmphasized)
                        .foregroundStyle(BCColors.primary)
                }
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
            Text(channel == .buddies
                 ? "Stem hier met je mede-vrijwilligers af wie wanneer gaat."
                 : "Stuur het team een berichtje om het gesprek te beginnen.")
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
        let currentChannel = channel
        Task {
            messages = await appState.sendTeamChat(teamId: teamId, channel: currentChannel, body: body)
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
    TeamChatView(teamId: UUID(), teamName: "Team Riet",
                 channels: [.all, .buddies])
        .environment(AppState())
}
