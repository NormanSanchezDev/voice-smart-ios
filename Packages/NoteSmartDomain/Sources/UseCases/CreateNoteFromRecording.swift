import Foundation

/// The headline flow: a finished recording becomes a saved note.
///
/// Transcription and enrichment are the fallible parts, so the raw transcript is
/// always returned alongside the note. The editor shows both so a user can
/// compare what was said with what the model did to it.
public struct CreateNoteFromRecording: Sendable {
    public enum Stage: Hashable, Sendable {
        case installingModel(ModelInstallProgress)
        case transcribing(TranscriptionProgress)
        case enriching(EnrichmentProgress)
        case saved(Note)
    }

    public struct Output: Hashable, Sendable {
        public let note: Note
        public let rawTranscript: String
        public let enrichment: NoteEnrichment
        public let source: EnrichmentSource
    }

    private let transcriber: any Transcriber
    private let enricher: any NoteEnricher
    private let fallbackEnricher: any NoteEnricher
    private let repository: any NoteRepository
    private let date: any DateProvider

    public init(
        transcriber: any Transcriber,
        enricher: any NoteEnricher,
        fallbackEnricher: any NoteEnricher,
        repository: any NoteRepository,
        date: any DateProvider
    ) {
        self.transcriber = transcriber
        self.enricher = enricher
        self.fallbackEnricher = fallbackEnricher
        self.repository = repository
        self.date = date
    }

    public func callAsFunction(
        _ audio: AudioFileRef,
        folder: VaultPath = VaultPath()
    ) async -> AsyncThrowingStream<Stage, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // 1. Transcribe
                    guard await transcriber.isAvailable(locale: audio.locale) else {
                        throw TranscriptionError.unavailableOnDevice
                    }
                    for try await progress in await transcriber.installModel(for: audio.locale) {
                        continuation.yield(.installingModel(progress))
                        if progress.isFinished { break }
                    }

                    var segments: [TranscriptSegment] = []
                    for try await progress in await transcriber.transcribe(audio) {
                        segments = progress.finalized
                        continuation.yield(.transcribing(progress))
                    }
                    guard !segments.isEmpty else { throw TranscriptionError.emptyRecording }

                    let rawTranscript = segments.map(\.text).joined(separator: " ")

                    // 2. Enrich. EnrichTranscript owns the AI-or-heuristics
                    // decision and the mid-flight degradation, so there is
                    // exactly one place that decides what happens without AI.
                    let availability = await enricher.availability
                    let aiSource: EnrichmentSource = availability.isAvailable ? .onDeviceAI : .ruleBasedFallback

                    let enrichTranscript = EnrichTranscript(
                        enricher: enricher,
                        fallback: fallbackEnricher
                    )
                    var enrichment = NoteEnrichment.empty()
                    for try await progress in await enrichTranscript(
                        rawTranscript,
                        suggestedTags: [],
                        locale: audio.locale
                    ) {
                        enrichment = progress.applied(to: enrichment)
                        continuation.yield(.enriching(progress))
                    }

                    // 3. Persist as markdown
                    let now = date.now
                    var note = Note(
                        folder: folder,
                        fileName: "",
                        frontmatter: NoteFrontmatter(
                            title: enrichment.title.isEmpty ? "Untitled note" : enrichment.title,
                            created: now,
                            modified: now,
                            tags: enrichment.tags,
                            audio: AudioRef(
                                fileName: audio.url.lastPathComponent,
                                duration: segments.last?.range.end ?? 0
                            ),
                            source: .voice,
                            enriched: aiSource.isAI
                        ),
                        body: Self.composeBody(enrichment: enrichment, transcript: segments),
                        transcript: segments
                    )
                    note.fileName = try await repository.availableFileName(
                        for: note.title,
                        in: folder,
                        excluding: note.id
                    )
                    let saved = try await repository.save(note)
                    continuation.yield(.saved(saved))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Renders the note body: cleaned prose on top, time-indexed transcript
    /// below, so nothing the user said is lost to editing.
    static func composeBody(enrichment: NoteEnrichment, transcript: [TranscriptSegment]) -> String {
        var sections: [String] = []

        if !enrichment.summary.isEmpty {
            sections.append("> \(enrichment.summary)")
        }
        if !enrichment.cleanedMarkdown.isEmpty {
            sections.append(enrichment.cleanedMarkdown)
        }
        if !enrichment.actionItems.isEmpty {
            let items = enrichment.actionItems.map { "- [ ] \($0)" }.joined(separator: "\n")
            sections.append("## Action items\n\n\(items)")
        }
        if !transcript.isEmpty {
            let lines = transcript.map { "- [\($0.range.timestampText())] \($0.text)" }
            sections.append("## Transcript\n\n" + lines.joined(separator: "\n"))
        }
        return sections.joined(separator: "\n\n")
    }
}
