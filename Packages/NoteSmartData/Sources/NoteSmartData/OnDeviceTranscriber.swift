import AVFAudio
import Foundation
import NoteSmartDomain
import Speech

/// On-device speech-to-text using the Speech framework.
///
/// Everything is on device: no audio leaves the phone, which is the whole point of
/// a local-first notes app. The model is downloaded once per locale and its install
/// is surfaced to the user, because it is hundreds of megabytes.
public actor OnDeviceTranscriber: Transcriber {
    public init() {}

    // MARK: - Availability

    public func isAvailable(locale: Locale) async -> Bool {
        guard SpeechTranscriber.isAvailable else { return false }
        return await Self.resolvedLocale(for: locale) != nil
    }

    public func installModel(for locale: Locale) async -> AsyncThrowingStream<ModelInstallProgress, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let resolved = await Self.resolvedLocale(for: locale) else {
                        throw TranscriptionError.unsupportedLocale(locale.identifier)
                    }

                    let transcriber = Self.makeTranscriber(locale: resolved)
                    let status = await AssetInventory.status(forModules: [transcriber])
                    guard status != .installed else {
                        continuation.yield(ModelInstallProgress(fractionCompleted: 1, isFinished: true))
                        continuation.finish()
                        return
                    }

                    guard let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) else {
                        throw TranscriptionError.modelInstallFailed(reason: "no request for \(resolved.identifier)")
                    }

                    // `Progress` is not an AsyncSequence; polling it keeps this free of
                    // KVO callbacks crossing concurrency domains.
                    let progressTask = Task {
                        while !Task.isCancelled {
                            let fraction = request.progress.fractionCompleted
                            if fraction > 0 {
                                continuation.yield(ModelInstallProgress(fractionCompleted: fraction, isFinished: false))
                            }
                            if fraction >= 1 { break }
                            try? await Task.sleep(for: .milliseconds(200))
                        }
                    }

                    try await request.downloadAndInstall()
                    progressTask.cancel()

                    continuation.yield(ModelInstallProgress(fractionCompleted: 1, isFinished: true))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Transcription

    public func transcribe(_ audio: AudioFileRef) async -> AsyncThrowingStream<TranscriptionProgress, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let resolved = await Self.resolvedLocale(for: audio.locale) else {
                        throw TranscriptionError.unsupportedLocale(audio.locale.identifier)
                    }

                    let file = try AVAudioFile(forReading: audio.url)
                    let transcriber = Self.makeTranscriber(locale: resolved)
                    let analyzer = SpeechAnalyzer(modules: [transcriber])

                    var segments: [TranscriptSegment] = []
                    let consumer = Task {
                        for try await result in transcriber.results {
                            let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { continue }

                            segments.append(
                                TranscriptSegment(
                                    text: text,
                                    range: TimeRange(
                                        start: result.range.start.seconds,
                                        end: result.range.end.seconds
                                    )
                                )
                            )
                            continuation.yield(
                                TranscriptionProgress(
                                    volatileText: text,
                                    finalized: segments,
                                    isFinal: false
                                )
                            )
                        }
                        return segments
                    }

                    try await analyzer.start(inputAudioFile: file, finishAfterFile: true)
                    let finalSegments = try await consumer.value

                    // The analyzer finishes before the last result is necessarily
                    // finalised, so the tail is emitted once more as the final element.
                    continuation.yield(
                        TranscriptionProgress(volatileText: "", finalized: finalSegments, isFinal: true)
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Helpers

    /// Time-indexed progressive transcription: playback highlighting needs the
    /// audio time range on every segment.
    ///
    /// The framework has no `preset:attributeOptions:` overload, so the preset's
    /// options are read off it and passed to the full initialiser.
    nonisolated static func makeTranscriber(locale: Locale) -> SpeechTranscriber {
        let preset = SpeechTranscriber.Preset.timeIndexedProgressiveTranscription
        return SpeechTranscriber(
            locale: locale,
            transcriptionOptions: preset.transcriptionOptions,
            reportingOptions: preset.reportingOptions,
            attributeOptions: [.audioTimeRange, .transcriptionConfidence]
        )
    }

    nonisolated static func resolvedLocale(for locale: Locale) async -> Locale? {
        await SpeechTranscriber.supportedLocale(equivalentTo: locale)
    }
}
