import SwiftUI
import Combine
import AVFoundation
import EventKit
import Daily

// ============================================================
// Intake-videogesprek (Daily)
//
// De Daily REST-key blijft server-side; deze view haalt via de edge function
// `intake-video` een room-URL + kort geldig meeting token op en joint daarmee.
// Eén herbruikbaar scherm voor zowel de buddy als de admin.
// ============================================================

/// Houdt de Daily-call vast en publiceert de lokale + remote videotrack zodat
/// SwiftUI ze kan tonen. MainActor: CallClient is main-actor-gebonden.
@MainActor
final class DailyCallModel: NSObject, ObservableObject, CallClientDelegate {
    private let client = CallClient()

    @Published var localTrack: VideoTrack?
    @Published var remoteTrack: VideoTrack?
    @Published var remoteJoined = false
    @Published var micOn = true
    @Published var camOn = true
    @Published var errorText: String?

    override init() {
        super.init()
        client.delegate = self
    }

    func join(roomUrl: URL, token: String) async {
        // Camera + microfoon eerst regelen. Daily schakelt bij het joinen meteen
        // de inputs in; staat de toestemming nog op "niet bepaald", dan kan de
        // verbinding mislukken met een generieke CallClientError (error 0). Door
        // de toestemming hier af te wachten is dat opgelost vóór we joinen.
        await Self.ensureMediaPermissions()

        let meetingToken = MeetingToken(stringValue: token)
        do {
            _ = try await client.join(url: roomUrl, token: meetingToken)
            errorText = nil
            sync()
        } catch {
            // Eén korte herkansing: joinfouten zijn vaak van voorbijgaande aard
            // (netwerk/timing vlak nadat de room is aangemaakt).
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            do {
                _ = try await client.join(url: roomUrl, token: meetingToken)
                errorText = nil
                sync()
            } catch {
                errorText = "Verbinden mislukt: \(Self.describe(error))"
            }
        }
    }

    /// Vraagt (eenmalig) toestemming voor camera en microfoon. Doet niets als die
    /// al is gegeven of geweigerd — alleen bij "niet bepaald" verschijnt de prompt.
    static func ensureMediaPermissions() async {
        for type in [AVMediaType.video, AVMediaType.audio] {
            if AVCaptureDevice.authorizationStatus(for: type) == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: type)
            }
        }
    }

    /// Daily's `CallClientError` bridge't soms naar het nietszeggende
    /// "The operation couldn't be completed. (… error 0.)". Geef in dat geval een
    /// begrijpelijke melding terug.
    static func describe(_ error: any Swift.Error) -> String {
        let desc = (error as NSError).localizedDescription
        if desc.isEmpty || desc.contains("couldn’t be completed") || desc.contains("couldn't be completed") {
            return "kon geen verbinding maken. Controleer je internet en of camera/microfoon zijn toegestaan, en probeer het opnieuw."
        }
        return desc
    }

    func leave() async {
        try? await client.leave()
    }

    func setMic(_ on: Bool) {
        micOn = on
        Task { try? await client.setInputsEnabled([.microphone: on]) }
    }

    func setCam(_ on: Bool) {
        camOn = on
        Task { try? await client.setInputsEnabled([.camera: on]) }
    }

    /// Leidt de te tonen tracks af uit de huidige deelnemers (1-op-1 gesprek).
    private func sync() {
        let participants = client.participants
        localTrack = participants.local.media?.camera.track
        let remote = participants.remote.values.first
        remoteTrack = remote?.media?.camera.track
        remoteJoined = !participants.remote.isEmpty
    }

    // MARK: CallClientDelegate (overige methodes hebben default-implementaties)

    func callClient(_ callClient: CallClient, participantJoined participant: Participant) { sync() }
    func callClient(_ callClient: CallClient, participantUpdated participant: Participant) { sync() }
    func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) { sync() }
    func callClient(_ callClient: CallClient, callStateUpdated state: CallState) { sync() }
    func callClient(_ callClient: CallClient, error: CallClientError) {
        errorText = "Videofout: \(error.localizedDescription)"
    }
}

/// Toont één Daily-videotrack (UIKit `VideoView`) in SwiftUI.
///
/// `mirror` spiegelt de view horizontaal. Zet dit alléén aan voor de eigen lokale
/// preview (front-camera), zodat je jezelf ziet zoals in een normale selfie. De
/// remote deelnemer wordt nooit gespiegeld.
struct DailyVideoView: UIViewRepresentable {
    let track: VideoTrack?
    var scaleMode: Daily.VideoView.VideoScaleMode = .fill
    var mirror: Bool = false

    func makeUIView(context: Context) -> Daily.VideoView {
        let view = Daily.VideoView()
        view.videoScaleMode = scaleMode
        applyMirror(to: view)
        return view
    }

    func updateUIView(_ uiView: Daily.VideoView, context: Context) {
        uiView.videoScaleMode = scaleMode
        if uiView.track != track { uiView.track = track }
        applyMirror(to: uiView)
    }

    /// Horizontale flip via een affiene transform op precies deze view. Zo raakt
    /// alleen de lokale preview gespiegeld en nooit per ongeluk de remote view.
    private func applyMirror(to view: Daily.VideoView) {
        let target: CGAffineTransform = mirror ? CGAffineTransform(scaleX: -1, y: 1) : .identity
        if view.transform != target { view.transform = target }
    }
}

/// Volledig intake-videoscherm. `isAdmin` bepaalt of de goedkeur-/afwijs-knoppen
/// getoond worden; de buddy ziet alleen ophangen.
struct IntakeVideoView: View {
    let callId: UUID
    var isAdmin: Bool = false
    var onApprove: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil
    let onEnd: () -> Void

    @StateObject private var model = DailyCallModel()
    @State private var loading = true
    @State private var setupError: String?

    var body: some View {
        ZStack {
            BCColors.navy900.ignoresSafeArea()

            // Remote (grote) video, of een wachtstand.
            if model.remoteJoined, model.remoteTrack != nil {
                DailyVideoView(track: model.remoteTrack).ignoresSafeArea()
            } else {
                waitingState
            }

            // Eigen beeld als kleine tegel rechtsboven.
            if model.camOn, model.localTrack != nil {
                VStack {
                    HStack {
                        Spacer()
                        DailyVideoView(track: model.localTrack, mirror: true)
                            .frame(width: 104, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: BCRadius.md, style: .continuous)
                                .stroke(.white.opacity(0.6), lineWidth: 1))
                            .padding(.top, 60)
                            .padding(.trailing, BCSpacing.md)
                    }
                    Spacer()
                }
            }

            VStack {
                if let err = setupError ?? model.errorText {
                    Text(err)
                        .font(BCTypography.caption)
                        .foregroundStyle(.white)
                        .padding(BCSpacing.sm)
                        .background(Capsule().fill(BCColors.danger))
                        .padding(.top, 60)
                }
                Spacer()
                controls
            }
        }
        .task {
            await connect()
        }
    }

    private var waitingState: some View {
        VStack(spacing: BCSpacing.md) {
            if loading {
                BCLoadingDots(onDark: true)
                Text("Verbinden met het gesprek…")
            } else {
                Image(systemName: "video.fill").font(.system(size: 44)).foregroundStyle(.white.opacity(0.8))
                Text(isAdmin ? "Wachten tot de buddy in beeld komt…" : "Wachten tot de medewerker opneemt…")
            }
        }
        .font(BCTypography.headline)
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, BCSpacing.xl)
    }

    private var controls: some View {
        VStack(spacing: BCSpacing.md) {
            HStack(spacing: BCSpacing.lg) {
                circleButton(model.micOn ? "mic.fill" : "mic.slash.fill",
                             active: model.micOn) { model.setMic(!model.micOn) }
                circleButton(model.camOn ? "video.fill" : "video.slash.fill",
                             active: model.camOn) { model.setCam(!model.camOn) }
                // Ophangen
                Button {
                    Task { await model.leave(); onEnd() }
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(BCColors.danger))
                }
                .buttonStyle(.plain)
            }

            if isAdmin {
                HStack(spacing: BCSpacing.sm) {
                    Button {
                        Task { await model.leave(); onApprove?() }
                    } label: {
                        Label("Keur intake goed", systemImage: "checkmark.seal.fill")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Capsule().fill(BCColors.success))
                    }
                    .buttonStyle(.plain)
                    Button {
                        Task { await model.leave(); onReject?() }
                    } label: {
                        Label("Afwijzen", systemImage: "xmark")
                            .font(BCTypography.bodyEmphasized)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Capsule().fill(BCColors.danger))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, BCSpacing.lg)
            }
        }
        .padding(.bottom, BCSpacing.xl)
    }

    private func circleButton(_ icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(active ? .white : BCColors.navy900)
                .frame(width: 56, height: 56)
                .background(Circle().fill(active ? .white.opacity(0.18) : .white))
        }
        .buttonStyle(.plain)
    }

    private func connect() async {
        do {
            let creds = try await ProfileService().fetchIntakeVideoCredentials(callId: callId)
            guard let url = URL(string: creds.roomUrl) else {
                setupError = "Ongeldige video-URL ontvangen."; loading = false; return
            }
            await model.join(roomUrl: url, token: creds.token)
            loading = false
        } catch {
            setupError = "Kon het videogesprek niet starten: \(AppState.shortError(error))"
            loading = false
        }
    }
}

// ============================================================
// Agenda-koppeling voor een ingepland intakegesprek
//
// Apple: via EventKit (write-only toegang, iOS 17+). Google: via een Google
// Calendar template-URL die in de browser/app opent. Zo werkt "zet in agenda"
// voor beide platformen. De videocall zelf opent in de app; de afspraak bevat
// de datum, tijd en (indien bekend) de link.
// ============================================================

enum IntakeAgenda {
    static let title = "Intakegesprek Thuisverzorgd"
    static let defaultDurationMinutes = 30

    static func notes(link: String?) -> String {
        var lines = ["Kort intake-videogesprek met een medewerker van Thuisverzorgd.",
                     "Open de Thuisverzorgd-app op het afgesproken moment om deel te nemen."]
        if let link, !link.isEmpty { lines.append("Videolink: \(link)") }
        return lines.joined(separator: "\n")
    }

    /// Voegt het gesprek toe aan de Apple Agenda. Vraagt write-only toegang (iOS 17+).
    /// Geeft `nil` terug bij succes, of een leesbare foutmelding.
    @MainActor
    static func addToAppleCalendar(start: Date, durationMinutes: Int = defaultDurationMinutes,
                                   link: String?) async -> String? {
        let store = EKEventStore()
        do {
            let granted = try await store.requestWriteOnlyAccessToEvents()
            guard granted else {
                return "Geen toegang tot je agenda. Sta dit toe via Instellingen."
            }
            let event = EKEvent(eventStore: store)
            event.title = title
            event.startDate = start
            event.endDate = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
            event.notes = notes(link: link)
            event.calendar = store.defaultCalendarForNewEvents
            guard event.calendar != nil else {
                return "Er is geen standaardagenda ingesteld op dit toestel."
            }
            try store.save(event, span: .thisEvent)
            return nil
        } catch {
            return "Toevoegen mislukt: \(error.localizedDescription)"
        }
    }

    /// Google Calendar template-URL (opent in de browser of Google Agenda-app).
    static func googleCalendarURL(start: Date, durationMinutes: Int = defaultDurationMinutes,
                                  link: String?) -> URL? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let s = fmt.string(from: start)
        let e = fmt.string(from: start.addingTimeInterval(TimeInterval(durationMinutes * 60)))
        var c = URLComponents(string: "https://calendar.google.com/calendar/render")
        c?.queryItems = [
            URLQueryItem(name: "action", value: "TEMPLATE"),
            URLQueryItem(name: "text", value: title),
            URLQueryItem(name: "dates", value: "\(s)/\(e)"),
            URLQueryItem(name: "details", value: notes(link: link))
        ]
        return c?.url
    }
}
