//
//  AppEnvironment.swift
//  NoteSmart
//

import Foundation
import NoteSmartData
import NoteSmartDomain
import Observation
import SwiftData

/// Composition root: the only place that knows which concrete type satisfies each
/// domain protocol. Everything below `Presentation` receives its dependencies
/// already built, and only ever sees them as domain protocols, which is what keeps
/// the dependency rule in ADR 0001 true in the compiler rather than in a convention.
///
/// The graph has exactly one cycle. `FileNoteRepository` refreshes the search index
/// on every write, and `VaultIndexer` needs the repository to rescan. Neither can be
/// constructed first with the other in hand, so both are built here and linked with
/// `attachIndex` once, before anything reads or writes a note.
@Observable
final class AppEnvironment {

    enum State: Equatable, Sendable {
        case preparing
        case ready
        case failed(String)
    }

    let modelContainer: ModelContainer

    // What the features are allowed to see.
    let vault: any VaultLocator
    let repository: any NoteRepository
    let search: any NoteSearch
    let recorder: any AudioRecorder
    let transcriber: any Transcriber
    let aiEnricher: any NoteEnricher
    let ruleEnricher: any NoteEnricher
    let clock: any DateProvider

    let createNoteFromRecording: CreateNoteFromRecording
    let transcribeRecording: TranscribeRecording
    let renameNote: MarkdownEditing.RenameNote
    let moveNote: MarkdownEditing.MoveNote

    private(set) var state: State = .preparing

    /// `true` while the vault is closed behind the splash.
    ///
    /// NoteSmart has no account and no server, so "signing out" cannot mean ending a
    /// remote session. What it can honestly mean is locking local data until the user
    /// asks for it again, which is what this flag drives. See
    /// `documentation/decisions/0005-local-first-sin-autenticacion.md`.
    private(set) var isLocked = false

    // The concrete pair, kept only to link the cycle and to sync the index at launch.
    private let fileRepository: FileNoteRepository
    private let fileIndexer: VaultIndexer

    init(
        modelContainer: ModelContainer,
        vault: any VaultLocator,
        repository: FileNoteRepository,
        indexer: VaultIndexer,
        recorder: AudioEngineRecorder,
        transcriber: OnDeviceTranscriber,
        aiEnricher: OnDeviceNoteEnricher,
        ruleEnricher: RuleBasedNoteEnricher,
        clock: any DateProvider
    ) {
        self.modelContainer = modelContainer
        self.vault = vault
        self.fileRepository = repository
        self.fileIndexer = indexer
        self.repository = repository
        self.search = indexer
        self.recorder = recorder
        self.transcriber = transcriber
        self.aiEnricher = aiEnricher
        self.ruleEnricher = ruleEnricher
        self.clock = clock

        self.createNoteFromRecording = CreateNoteFromRecording(
            transcriber: transcriber,
            enricher: aiEnricher,
            fallbackEnricher: ruleEnricher,
            repository: repository,
            date: clock
        )
        self.transcribeRecording = TranscribeRecording(transcriber: transcriber)
        self.renameNote = MarkdownEditing.RenameNote(repository: repository, date: clock)
        self.moveNote = MarkdownEditing.MoveNote(repository: repository, date: clock)
    }

    /// Production graph.
    ///
    /// The index is a rebuildable projection, not the source of truth, so it goes to
    /// the default container location instead of inside the vault: a user who clears
    /// it from Files only pays for a rescan.
    static func live() throws -> AppEnvironment {
        let container = try ModelContainer(for: Schema([NoteIndexRecord.self]))
        let vault = try DocumentsVaultLocator.documentsDefault()
        let repository = FileNoteRepository(locator: vault)
        let indexer = VaultIndexer(container: container, repository: repository)

        return AppEnvironment(
            modelContainer: container,
            vault: vault,
            repository: repository,
            indexer: indexer,
            recorder: AudioEngineRecorder(),
            transcriber: OnDeviceTranscriber(),
            aiEnricher: OnDeviceNoteEnricher(),
            ruleEnricher: RuleBasedNoteEnricher(),
            clock: SystemDateProvider()
        )
    }

    /// A graph backed by an in-memory vault, for previews and UI tests.
    static func inMemory() throws -> AppEnvironment {
        let schema = Schema([NoteIndexRecord.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("PreviewVault-\(UUID().uuidString.prefix(8))", isDirectory: true)
        let vault = DocumentsVaultLocator(
            rootURL: root,
            recordingsURL: root.appendingPathComponent("Recordings", isDirectory: true)
        )
        let repository = FileNoteRepository(locator: vault)
        let indexer = VaultIndexer(container: container, repository: repository)

        return AppEnvironment(
            modelContainer: container,
            vault: vault,
            repository: repository,
            indexer: indexer,
            recorder: AudioEngineRecorder(),
            transcriber: OnDeviceTranscriber(),
            aiEnricher: OnDeviceNoteEnricher(),
            ruleEnricher: RuleBasedNoteEnricher(),
            clock: SystemDateProvider()
        )
    }

    /// Creates the vault, links the index to the repository and syncs it.
    ///
    /// Idempotent, so a re-attach after a scene phase change costs one count query
    /// rather than a rescan.
    func prepare() async {
        do {
            try await vault.ensureVaultExists()
            await fileRepository.attachIndex(fileIndexer)
            try await fileIndexer.synchronize()
            state = .ready
        } catch {
            state = .failed(AppErrorMessage.text(for: error))
        }
    }

    /// Closes the vault. The environment is kept, not rebuilt, so re-opening does not
    /// pay for a new container or a new recorder.
    func lock() {
        isLocked = true
    }

    func unlock() {
        isLocked = false
    }

    /// Resolves a finished recording to a full URL.
    ///
    /// The recorder hands back a bare file name, and only whoever knows the vault
    /// layout can turn that into something Speech can open. The domain deliberately
    /// stops at the name.
    func audioFile(for recording: AudioRecording) -> AudioFileRef {
        audioFile(named: recording.fileName, format: recording.format)
    }

    /// Destination for a capture that does not exist yet. The id is random rather
    /// than timestamp-based so two recordings started in the same second cannot
    /// overwrite each other.
    func newRecordingDestination() -> AudioFileRef {
        audioFile(named: "\(UUID().uuidString).m4a", format: .m4a)
    }

    private func audioFile(named fileName: String, format: AudioFormat) -> AudioFileRef {
        AudioFileRef(
            url: vault.recordingsURL.appendingPathComponent(fileName, isDirectory: false),
            locale: .current,
            format: format
        )
    }
}
