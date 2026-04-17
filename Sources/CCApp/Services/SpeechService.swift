import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false

    private let recognizer: SFSpeechRecognizer?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        recognizer = SFSpeechRecognizer(locale: Locale.current)
        super.init()
        recognizer?.delegate = self
    }

    func startRecording() async throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""

        let authStatus = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard authStatus == .authorized else { throw SpeechError.notAuthorized }

        #if os(iOS)
        let micGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
        }
        guard micGranted else { throw SpeechError.microphoneNotAuthorized }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        guard let recognizer, recognizer.isAvailable else { throw SpeechError.recognizerUnavailable }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor [weak self] in
                    self?.transcript = text
                }
            }
            if error != nil || result?.isFinal == true {
                Task { @MainActor [weak self] in
                    self?.stopEngine()
                }
            }
        }
    }

    @discardableResult
    func stopRecording() -> String {
        let final = transcript
        stopEngine()
        return final
    }

    private func stopEngine() {
        guard isRecording else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
}

extension SpeechService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {}
}

enum SpeechError: LocalizedError {
    case notAuthorized
    case microphoneNotAuthorized
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Speech recognition permission was not granted."
        case .microphoneNotAuthorized: return "Microphone permission was not granted."
        case .recognizerUnavailable: return "Speech recognizer is not available."
        }
    }
}
