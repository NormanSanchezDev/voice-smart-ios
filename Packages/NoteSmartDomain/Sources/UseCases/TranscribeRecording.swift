import Foundation

/// Installs the speech model if needed, then transcribes a recording.
/// Split out of `CreateNoteFromRecording` so the app can transcribe without
/// writing a note, and so model download is its own testable step.
public struct TranscribeRecording: Sendable {
    public enum Stage: Hashable, Sendable {
        case installing(ModelInstallProgress)
        case transcribing(TranscriptionProgress)
        case finished([TranscriptSegment])
    }

    private let transcriber: any Transcriber

    public init(transcriber: any Transcriber) {
        self.transcriber = transcriber
    }

    public func callAsFunction(_ audio: AudioFileRef) async -> AsyncThrowingStream<Stage, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard await transcriber.isAvailable(locale: audio.locale) else {
                        throw TranscriptionError.unavailableOnDevice
                    }

                    for try await progress in await transcriber.installModel(for: audio.locale) {
                        continuation.yield(.installing(progress))
                        if progress.isFinished { break }
                    }

                    var segments: [TranscriptSegment] = []
                    for try await progress in await transcriber.transcribe(audio) {
                        segments = progress.finalized
                        continuation.yield(.transcribing(progress))
                    }

                    guard !segments.isEmpty else { throw TranscriptionError.emptyRecording }
                    continuation.yield(.finished(segments))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Blocking convenience for callers that do not need progress.
    public func segments(for audio: AudioFileRef) async throws -> [TranscriptSegment] {
        for try await stage in await callAsFunction(audio) {
            if case .finished(let segments) = stage { return segments }
        }
        throw TranscriptionError.emptyRecording
    }
}
