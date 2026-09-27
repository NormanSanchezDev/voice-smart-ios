import Foundation
import Testing
@testable import NoteSmartDomain

// MARK: - Fakes

actor InMemoryNoteRepository: NoteRepository {
    private var storage: [String: Note] = [:]
    private var counter = 0

    func seed(_ note: Note) {
        storage[note.relativePath] = note
    }

    func allNotes() async throws -> [Note] {
        Array(storage.values)
    }

    func note(id: NoteID) async throws -> Note? {
        storage.values.first { $0.id == id }
    }

    func note(atRelativePath path: String) async throws -> Note? {
        storage[path]
    }

    func save(_ note: Note) async throws -> Note {
        var stored = note
        if stored.fileName.isEmpty {
            stored.fileName = "note-\(counter).md"
            counter += 1
        }
        storage[stored.relativePath] = stored
        return stored
    }

    func delete(id: NoteID) async throws {
        storage = storage.filter { $0.value.id != id }
    }

    func delete(atRelativePath path: String) async throws {
        storage.removeValue(forKey: path)
    }

    func move(_ note: Note, to folder: VaultPath) async throws -> Note {
        var moved = note
        moved.folder = folder
        storage.removeValue(forKey: note.relativePath)
        storage[moved.relativePath] = moved
        return moved
    }

    func availableFileName(for title: String, in folder: VaultPath, excluding id: NoteID?) async throws -> String {
        let taken = Set(storage.values.map(\.fileName))
        let base = title.isEmpty ? "Untitled" : title
        var candidate = "\(base).md"
        var n = 2
        while taken.contains(candidate) {
            candidate = "\(base) \(n).md"
            n += 1
        }
        return candidate
    }

    func folders() async throws -> [VaultPath] {
        Set(storage.values.map(\.folder)).sorted { $0.description < $1.description }
    }
}

struct StubTranscriber: Transcriber {
    var available = true
    var segments: [TranscriptSegment] = [
        TranscriptSegment(text: "Buy milk", range: TimeRange(start: 0, end: 2))
    ]
    var installProgress: [ModelInstallProgress] = [
        ModelInstallProgress(fractionCompleted: 1, isFinished: true)
    ]
    var intermediateProgress: [TranscriptionProgress] = [
        TranscriptionProgress(volatileText: "Buy", finalized: [], isFinal: false)
    ]

    func isAvailable(locale: Locale) async -> Bool { available }

    func installModel(for locale: Locale) async -> AsyncThrowingStream<ModelInstallProgress, Error> {
        let values = installProgress
        return AsyncThrowingStream { continuation in
            for value in values { continuation.yield(value) }
            continuation.finish()
        }
    }

    func transcribe(_ audio: AudioFileRef) async -> AsyncThrowingStream<TranscriptionProgress, Error> {
        let middles = intermediateProgress
        let finals = segments
        return AsyncThrowingStream { continuation in
            for value in middles { continuation.yield(value) }
            continuation.yield(TranscriptionProgress(finalized: finals, isFinal: true))
            continuation.finish()
        }
    }
}

struct StubEnricher: NoteEnricher {
    var availability: AIAvailability
    var progress: [EnrichmentProgress]

    init(availability: AIAvailability, progress: [EnrichmentProgress]) {
        self.availability = availability
        self.progress = progress
    }

    func enrich(
        transcript: String,
        suggestedTags: [VaultTag],
        locale: Locale
    ) async -> AsyncThrowingStream<EnrichmentProgress, Error> {
        let values = progress
        return AsyncThrowingStream { continuation in
            for value in values { continuation.yield(value) }
            continuation.finish()
        }
    }
}

struct FailingEnricher: NoteEnricher {
    var availability: AIAvailability = .available

    func enrich(
        transcript: String,
        suggestedTags: [VaultTag],
        locale: Locale
    ) async -> AsyncThrowingStream<EnrichmentProgress, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: EnrichmentError.guardrailViolation)
        }
    }
}

// MARK: - Tests

@Suite("CreateNoteFromRecording")
struct CreateNoteFromRecordingTests {

    private func makeUseCase(
        transcriber: StubTranscriber = StubTranscriber(),
        enricher: any NoteEnricher,
        fallback: any NoteEnricher,
        repository: InMemoryNoteRepository
    ) -> CreateNoteFromRecording {
        CreateNoteFromRecording(
            transcriber: transcriber,
            enricher: enricher,
            fallbackEnricher: fallback,
            repository: repository,
            date: FixedDateProvider(now: Date(timeIntervalSince1970: 1_700_000_000))
        )
    }

    @Test("Audio becomes a saved note with frontmatter and a transcript section")
    func happyPath() async throws {
        let repo = InMemoryNoteRepository()
        let useCase = makeUseCase(
            enricher: StubEnricher(
                availability: .available,
                progress: [
                    EnrichmentProgress(title: "Shopping list", isFinal: true),
                    EnrichmentProgress(
                        summary: "Two items to pick up",
                        tags: [VaultTag("errand")!],
                        actionItems: ["Buy milk"],
                        cleanedMarkdown: "Remember to buy milk.",
                        isFinal: true
                    ),
                ]
            ),
            fallback: StubEnricher(availability: .available, progress: []),
            repository: repo
        )

        let audio = AudioFileRef(
            url: URL(fileURLWithPath: "/tmp/rec.m4a"),
            locale: Locale(identifier: "en_US")
        )

        var stages: [CreateNoteFromRecording.Stage] = []
        for try await stage in await useCase(audio, folder: VaultPath(components: ["Notes"])) {
            stages.append(stage)
        }

        guard case .saved(let note) = stages.last else {
            Issue.record("expected the pipeline to end with a saved note")
            return
        }

        #expect(note.title == "Shopping list")
        #expect(note.folder == VaultPath(components: ["Notes"]))
        #expect(note.frontmatter.source == .voice)
        #expect(note.frontmatter.enriched == true)
        #expect(note.frontmatter.tags == [VaultTag("errand")!])
        #expect(note.frontmatter.audio?.fileName == "rec.m4a")
        #expect(note.body.contains("> Two items to pick up"))
        #expect(note.body.contains("- [ ] Buy milk"))
        #expect(note.body.contains("## Transcript"))
        #expect(note.body.contains("- [0:00] Buy milk"))
        #expect(try await repo.allNotes().count == 1, "the note reached storage")
    }

    @Test("Emits install, transcribe and enrich stages in order")
    func stageOrder() async throws {
        let repo = InMemoryNoteRepository()
        var transcriber = StubTranscriber()
        transcriber.installProgress = [
            ModelInstallProgress(fractionCompleted: 0.3, isFinished: false),
            ModelInstallProgress(fractionCompleted: 0.9, isFinished: false),
            ModelInstallProgress(fractionCompleted: 1, isFinished: true),
        ]
        let useCase = makeUseCase(
            transcriber: transcriber,
            enricher: StubEnricher(
                availability: .available,
                progress: [EnrichmentProgress(title: "T", isFinal: true)]
            ),
            fallback: StubEnricher(availability: .available, progress: []),
            repository: repo
        )

        var kinds: [String] = []
        for try await stage in await useCase(
            AudioFileRef(url: URL(fileURLWithPath: "/tmp/a.m4a"), locale: Locale(identifier: "en_US"))
        ) {
            switch stage {
            case .installingModel: kinds.append("install")
            case .transcribing: kinds.append("transcribe")
            case .enriching: kinds.append("enrich")
            case .saved: kinds.append("saved")
            }
        }
        #expect(kinds == ["install", "install", "install", "transcribe", "transcribe", "enrich", "saved"])
    }

    @Test("Fails when the device cannot transcribe")
    func unavailableTranscriber() async throws {
        let repo = InMemoryNoteRepository()
        var transcriber = StubTranscriber()
        transcriber.available = false
        let useCase = makeUseCase(
            transcriber: transcriber,
            enricher: StubEnricher(availability: .available, progress: []),
            fallback: StubEnricher(availability: .available, progress: []),
            repository: repo
        )

        await #expect(throws: TranscriptionError.unavailableOnDevice) {
            for try await _ in await useCase(
                AudioFileRef(url: URL(fileURLWithPath: "/tmp/a.m4a"), locale: Locale(identifier: "en_US"))
            ) {}
        }
        let savedCount = try await repo.allNotes().count
        #expect(savedCount == 0, "nothing may be written when transcription cannot start")
    }

    @Test("Fails on an empty recording rather than saving a blank note")
    func emptyRecording() async {
        let repo = InMemoryNoteRepository()
        var transcriber = StubTranscriber()
        transcriber.segments = []
        transcriber.intermediateProgress = []
        let useCase = makeUseCase(
            transcriber: transcriber,
            enricher: StubEnricher(availability: .available, progress: []),
            fallback: StubEnricher(availability: .available, progress: []),
            repository: repo
        )

        await #expect(throws: TranscriptionError.emptyRecording) {
            for try await _ in await useCase(
                AudioFileRef(url: URL(fileURLWithPath: "/tmp/a.m4a"), locale: Locale(identifier: "en_US"))
            ) {}
        }
    }

    @Test("Uses the fallback enricher and marks the note as not AI-edited")
    func unavailableAI() async throws {
        let repo = InMemoryNoteRepository()
        let useCase = makeUseCase(
            enricher: StubEnricher(availability: .unavailable(.deviceNotEligible), progress: []),
            fallback: StubEnricher(
                availability: .available,
                progress: [EnrichmentProgress(title: "Heuristic title", isFinal: true)]
            ),
            repository: repo
        )

        var saved: Note?
        for try await stage in await useCase(
            AudioFileRef(url: URL(fileURLWithPath: "/tmp/a.m4a"), locale: Locale(identifier: "en_US"))
        ) {
            if case .saved(let note) = stage { saved = note }
        }

        #expect(saved?.title == "Heuristic title")
        #expect(saved?.isEditedByAI == false, "no AI ran, so do not claim it did")
    }

    @Test("Recovers with the fallback when AI fails mid-flight")
    func aiFailsMidFlight() async throws {
        let repo = InMemoryNoteRepository()
        let useCase = makeUseCase(
            enricher: FailingEnricher(),
            fallback: StubEnricher(
                availability: .available,
                progress: [EnrichmentProgress(title: "Salvaged title", isFinal: true)]
            ),
            repository: repo
        )

        var saved: Note?
        for try await stage in await useCase(
            AudioFileRef(url: URL(fileURLWithPath: "/tmp/a.m4a"), locale: Locale(identifier: "en_US"))
        ) {
            if case .saved(let note) = stage { saved = note }
        }
        #expect(saved?.title == "Salvaged title")
    }
}

@Suite("EnrichTranscript")
struct EnrichTranscriptTests {

    @Test("Reports the on-device AI as the source when it is available")
    func aiSource() async throws {
        let useCase = EnrichTranscript(
            enricher: StubEnricher(
                availability: .available,
                progress: [
                    EnrichmentProgress(title: "First guess"),
                    EnrichmentProgress(title: "Final title", summary: "Sum", isFinal: true),
                ]
            ),
            fallback: StubEnricher(availability: .available, progress: [])
        )
        let result = try await useCase.enrichment(for: "some words")
        #expect(result.source == .onDeviceAI)
        #expect(result.enrichment.title == "Final title", "later snapshots overwrite earlier ones")
        #expect(result.enrichment.summary == "Sum")
    }

    @Test("Reports the rule-based source when AI is unavailable")
    func fallbackSource() async throws {
        let useCase = EnrichTranscript(
            enricher: StubEnricher(availability: .unavailable(.regionNotSupported), progress: []),
            fallback: StubEnricher(
                availability: .available,
                progress: [EnrichmentProgress(title: "Heuristic", isFinal: true)]
            )
        )
        let result = try await useCase.enrichment(for: "some words")
        #expect(result.source == .ruleBasedFallback)
        #expect(result.enrichment.title == "Heuristic")
    }

    @Test("Partial snapshots keep previously produced fields")
    func partialSnapshots() {
        let base = NoteEnrichment(title: "Base", summary: "Kept", cleanedMarkdown: "Body")
        let merged = EnrichmentProgress(title: "New").applied(to: base)
        #expect(merged.title == "New")
        #expect(merged.summary == "Kept")
        #expect(merged.cleanedMarkdown == "Body")
    }
}

@Suite("TranscribeRecording")
struct TranscribeRecordingTests {

    @Test("Returns segments from the blocking convenience")
    func segments() async throws {
        let useCase = TranscribeRecording(transcriber: StubTranscriber())
        let segments = try await useCase.segments(
            for: AudioFileRef(url: URL(fileURLWithPath: "/tmp/a.m4a"), locale: Locale(identifier: "en_US"))
        )
        #expect(segments.count == 1)
        #expect(segments.first?.text == "Buy milk")
    }

    @Test("Propagates an unavailable device")
    func unavailable() async {
        var stub = StubTranscriber()
        stub.available = false
        let useCase = TranscribeRecording(transcriber: stub)
        await #expect(throws: TranscriptionError.unavailableOnDevice) {
            try await useCase.segments(
                for: AudioFileRef(url: URL(fileURLWithPath: "/tmp/a.m4a"), locale: Locale(identifier: "en_US"))
            )
        }
    }
}

@Suite("Note entity")
struct NoteTests {

    @Test("Finds the segment active at a playback time")
    func segmentLookup() {
        let note = Note(
            fileName: "a.md",
            frontmatter: NoteFrontmatter(title: "A", created: .now, modified: .now),
            transcript: [
                TranscriptSegment(text: "one", range: TimeRange(start: 0, end: 5)),
                TranscriptSegment(text: "two", range: TimeRange(start: 5, end: 10)),
            ]
        )
        #expect(note.segment(at: 0)?.text == "one")
        #expect(note.segment(at: 7)?.text == "two")
        #expect(note.segment(at: 99) == nil)
    }

    @Test("Relative path joins folder and file name")
    func relativePath() {
        var note = Note(
            fileName: "a.md",
            frontmatter: NoteFrontmatter(title: "A", created: .now, modified: .now)
        )
        #expect(note.relativePath == "a.md")
        note.folder = VaultPath(components: ["Work"])
        #expect(note.relativePath == "Work/a.md")
    }

    @Test("Transcript text is space joined")
    func transcriptText() {
        let note = Note(
            fileName: "a.md",
            frontmatter: NoteFrontmatter(title: "A", created: .now, modified: .now),
            transcript: [
                TranscriptSegment(text: "one", range: TimeRange(duration: 1)),
                TranscriptSegment(text: "two", range: TimeRange(start: 1, end: 2)),
            ]
        )
        #expect(note.transcriptText == "one two")
    }
}

@Suite("TranscriptionProgress")
struct TranscriptionProgressTests {

    @Test("Display text appends the volatile guess after the stable text")
    func displayText() {
        let progress = TranscriptionProgress(
            volatileText: "maybe",
            finalized: [TranscriptSegment(text: "sure", range: TimeRange(duration: 1))]
        )
        #expect(progress.displayText == "sure maybe")
        #expect(TranscriptionProgress.empty.displayText.isEmpty)
    }
}
