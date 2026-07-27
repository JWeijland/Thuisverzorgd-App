import Foundation
import AVFoundation
import Speech
import Observation

/// On-device Nederlandse speech-to-text voor ouderen.
///
/// - Tap-to-start, tap-to-stop interactie
/// - Auto-stop bij 3 seconden stilte (geduldig, maar niet eindeloos)
/// - Live transcript-updates voor visuele feedback tijdens spreken
///
/// TODO[real-integration]: voor productie eventueel vervangen door
/// OpenAI Whisper API of Azure Speech voor betere accuratesse bij
/// zachte stemmen en regionale dialecten.
@Observable
final class SpeechService {

    enum State: Equatable {
        case idle
        case authorizing
        case listening
        case processing
        case done
        case denied(reason: String)
        case unavailable(reason: String)
        case error(message: String)
    }

    private(set) var state: State = .idle
    private(set) var transcript: String = ""
    /// Volume-niveau 0...1 voor visuele waveform animatie tijdens opname.
    private(set) var inputLevel: Float = 0

    private let silenceTimeout: TimeInterval = 3.0
    private let maxRecordingDuration: TimeInterval = 60.0

    private let audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var silenceTimer: Timer?
    private var maxDurationTimer: Timer?
    private var lastTranscriptHash: Int = 0

    init() {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "nl_NL"))
    }

    // MARK: - Public API

    func reset() {
        transcript = ""
        state = .idle
        inputLevel = 0
    }

    /// Start luisteren. Vraagt permissies indien nodig.
    func start() {
        guard state != .listening else { return }
        transcript = ""
        state = .authorizing

        requestPermissions { [weak self] granted, reason in
            guard let self else { return }
            DispatchQueue.main.async {
                guard granted else {
                    self.state = .denied(reason: reason)
                    return
                }
                self.beginListening()
            }
        }
    }

    /// Stop handmatig (gebruiker tikt nogmaals op de knop).
    func stop() {
        guard state == .listening else { return }
        state = .processing
        finalize()
    }

    // MARK: - Permissions

    private func requestPermissions(completion: @escaping (Bool, String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            switch speechStatus {
            case .authorized:
                AVAudioApplication.requestRecordPermission { micGranted in
                    if micGranted {
                        completion(true, "")
                    } else {
                        completion(false, "Thuisverzorgd heeft geen toegang tot de microfoon. Ga naar Instellingen om dit aan te zetten.")
                    }
                }
            case .denied:
                completion(false, "Spraakherkenning staat uit. Ga naar Instellingen om dit aan te zetten.")
            case .restricted:
                completion(false, "Spraakherkenning is niet beschikbaar op dit apparaat.")
            case .notDetermined:
                completion(false, "Permissie nog niet bepaald. Probeer opnieuw.")
            @unknown default:
                completion(false, "Onbekende fout bij spraakherkenning.")
            }
        }
    }

    // MARK: - Recording

    private func beginListening() {
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable(reason: "Nederlandse spraakherkenning is op dit moment niet beschikbaar.")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error(message: "Kon audio niet starten: \(error.localizedDescription)")
            return
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = false
        self.request = req

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Voorkom dubbele tap als er nog een hing
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
            self?.updateInputLevel(buffer: buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            state = .error(message: "Kon opname niet starten: \(error.localizedDescription)")
            return
        }

        state = .listening
        scheduleMaxDurationTimer()

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let result {
                    let newTranscript = result.bestTranscription.formattedString
                    self.transcript = newTranscript
                    // Reset stilte-timer wanneer de transcriptie verandert
                    let hash = newTranscript.hashValue
                    if hash != self.lastTranscriptHash {
                        self.lastTranscriptHash = hash
                        self.resetSilenceTimer()
                    }
                    if result.isFinal {
                        self.cleanupAfterFinalize()
                        self.state = .done
                    }
                }
                if let error {
                    let ns = error as NSError
                    // kSAFAssistantErrorDomain code 1101 (no speech detected) is geen echte fout voor de gebruiker
                    if ns.code == 203 || ns.code == 1110 || ns.code == 1101 {
                        self.cleanupAfterFinalize()
                        self.state = self.transcript.isEmpty ? .error(message: "Ik heb niets gehoord. Probeer het nogmaals.") : .done
                        return
                    }
                    self.cleanupAfterFinalize()
                    self.state = .error(message: "Spraakherkenning mislukt. Probeer het nogmaals.")
                }
            }
        }
    }

    private func updateInputLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        let level = min(max(rms * 8, 0), 1)
        DispatchQueue.main.async { [weak self] in
            self?.inputLevel = level
        }
    }

    // MARK: - Timers

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            self?.handleSilenceTimeout()
        }
    }

    private func scheduleMaxDurationTimer() {
        maxDurationTimer?.invalidate()
        maxDurationTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { [weak self] _ in
            self?.finalize()
        }
    }

    private func handleSilenceTimeout() {
        guard state == .listening else { return }
        state = .processing
        finalize()
    }

    // MARK: - Finalize / cleanup

    private func finalize() {
        request?.endAudio()
        // task callback ontvangt nog isFinal=true en doet cleanup
        // Maar als er geen audio binnenkwam, forceer cleanup na korte delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            if self.state == .processing {
                self.cleanupAfterFinalize()
                self.state = self.transcript.isEmpty
                    ? .error(message: "Ik heb niets gehoord. Probeer het nogmaals.")
                    : .done
            }
        }
    }

    private func cleanupAfterFinalize() {
        silenceTimer?.invalidate(); silenceTimer = nil
        maxDurationTimer?.invalidate(); maxDurationTimer = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request = nil
        task?.cancel()
        task = nil
        inputLevel = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    deinit {
        silenceTimer?.invalidate()
        maxDurationTimer?.invalidate()
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }
}
