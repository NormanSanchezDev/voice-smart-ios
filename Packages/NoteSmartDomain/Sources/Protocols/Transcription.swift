import Foundation

/// Microphone capture. The recording is written to a file *and* metered, so the
/// app can show a live waveform while guaranteeing a durable artefact.
public protocol AudioRecorder: Sendable {
    /// Current microphone authorisation. `.notDetermined` means we have not asked.
    func authorizationStatus() async -> AudioAuthorizationStatus

    /// Triggers the system permission prompt if needed. Returns the resulting
    /// status; `false` means the user declined.
    @discardableResult
    func requestAuthorization() async -> Bool

    func start(destination: AudioFileRef) async throws
    func pause() async throws
    func resume() async throws

    /// Finishes and returns the recording. Safe to call when not recording.
    func stop() async throws -> AudioRecording

    /// Discards in-progress audio. Never throws.
    func cancel() async

    /// Normalised levels for the live waveform.
    func meter() async -> AsyncStream<AudioMeterReading>
}

public enum AudioAuthorizationStatus: Hashable, Sendable {
    case notDetermined
    case authorized
    case denied
}

/// Model download progress. The on-device speech model is hundreds of
/// megabytes, so this must be shown and cancellable.
public struct ModelInstallProgress: Hashable, Sendable {
    public let fractionCompleted: Double
    public let isFinished: Bool

    public init(fractionCompleted: Double, isFinished: Bool) {
        self.fractionCompleted = fractionCompleted
        self.isFinished = isFinished
    }

    public static let notStarted = ModelInstallProgress(fractionCompleted: 0, isFinished: false)
}

/// Speech-to-text boundary. Streaming rather than blocking so the UI can show
/// words as they are recognised.
public protocol Transcriber: Sendable {
    /// `false` when this device or locale cannot transcribe on-device.
    func isAvailable(locale: Locale) async -> Bool

    /// Ensures the model asset is present, streaming progress while it
    /// downloads. Yields exactly one element with `isFinished == true` when done.
    func installModel(for locale: Locale) async -> AsyncThrowingStream<ModelInstallProgress, Error>

    /// Streams live transcription of a recorded file. Emits provisional results
    /// while speaking and a final element with `isFinal == true`.
    func transcribe(_ audio: AudioFileRef) async -> AsyncThrowingStream<TranscriptionProgress, Error>
}
