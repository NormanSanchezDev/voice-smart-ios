//
//  NoteEditorViewModel.swift
//  NoteSmart
//

import Foundation
import NoteSmartDomain
import Observation

/// Backs reading and editing one note.
///
/// Every mutation goes through a domain use case — `RenameNote`, `MoveNote`,
/// `toggleTask` — and only then through the repository, so the file on disk is always
/// the thing that changed. The drafts are separate from `note` so a half-typed title
/// never reaches the vault.
@MainActor
@Observable
final class NoteEditorViewModel {

    enum Mode: Equatable {
        case reading
        case editing
    }

    private(set) var note: Note?
    private(set) var mode: Mode = .reading
    private(set) var folders: [VaultPath] = []
    private(set) var isSaving = false
    private(set) var isMissing = false
    private(set) var errorMessage: String?

    var draftTitle = ""
    var draftBody = ""

    let player = AudioPlaybackController()

    /// The list behind this screen reloads when the note changes.
    var onNoteChanged: (() -> Void)?
    /// The note is gone; the screen should pop.
    var onDeleted: (() -> Void)?

    private let noteID: NoteID
    private let environment: AppEnvironment

    init(noteID: NoteID, environment: AppEnvironment) {
        self.noteID = noteID
        self.environment = environment
    }

    // MARK: - Derived state

    /// The body without the sections the editor draws itself.
    ///
    /// The transcript comes from `note.transcript` so each segment can highlight as
    /// the audio plays and be tapped to seek, and the action items come from
    /// `MarkdownEditing.tasks` so they can be ticked. Both still go to disk in the
    /// body; they are only cut out of what is displayed.
    var prose: String {
        guard let note else { return draftBody }
        return NoteBody.prose(from: note.body)
    }

    var tasks: [MarkdownEditing.Task] {
        MarkdownEditing.tasks(in: draftBody)
    }

    var hasTranscript: Bool { !(note?.transcript.isEmpty ?? true) }

    /// Segment under the playhead, for highlight-as-you-listen.
    var activeSegmentID: TranscriptSegment.ID? {
        note?.segment(at: player.currentTime)?.id
    }

    var canSave: Bool {
        guard let note else { return false }
        let titleChanged = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines) != note.title
        return mode == .editing && (titleChanged || draftBody != note.body)
    }

    // MARK: - Lifecycle

    func load() async {
        do {
            guard let loaded = try await environment.repository.note(id: noteID) else {
                isMissing = true
                return
            }
            note = loaded
            draftTitle = loaded.title
            draftBody = loaded.body
            folders = try await environment.repository.folders()

            if let audio = loaded.frontmatter.audio {
                player.load(
                    url: environment.vault.recordingsURL.appendingPathComponent(audio.fileName),
                    fallbackDuration: audio.duration
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
        }
    }

    // MARK: - Commands

    func beginEditing() {
        guard let note else { return }
        draftTitle = note.title
        draftBody = note.body
        mode = .editing
    }

    func cancelEditing() {
        guard let note else { return }
        draftTitle = note.title
        draftBody = note.body
        mode = .reading
    }

    /// Writes the drafts. The title goes through `RenameNote` because a new title
    /// means a new file name, and that decision belongs to the vault, not the screen.
    func save() async {
        guard let note, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            var updated = note
            let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTitle.isEmpty, trimmedTitle != note.title {
                updated = try await environment.renameNote(note, to: trimmedTitle)
            }
            if draftBody != updated.body {
                updated.body = draftBody
                updated.frontmatter.modified = environment.clock.now
                updated = try await environment.repository.save(updated)
            }

            self.note = updated
            draftTitle = updated.title
            draftBody = updated.body
            mode = .reading
            errorMessage = nil
            onNoteChanged?()
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
        }
    }

    /// Ticks a task and persists immediately: a checklist that only saves on demand
    /// loses the one thing people use checklists for.
    func toggleTask(_ task: MarkdownEditing.Task) async {
        do {
            draftBody = try MarkdownEditing.toggleTask(in: draftBody, at: task.index)
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
            return
        }
        await save()
    }

    func move(to folder: VaultPath) async {
        guard let note, note.folder != folder else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let moved = try await environment.moveNote(note, to: folder)
            self.note = moved
            folders = try await environment.repository.folders()
            errorMessage = nil
            onNoteChanged?()
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
        }
    }

    func removeTag(_ tag: VaultTag) async {
        guard var note else { return }
        note.tags.removeAll { $0 == tag }
        await persist(note)
    }

    /// Adds a tag typed by the user. Junk is rejected by `VaultTag` itself, so an
    /// empty chip simply does not appear.
    func addTag(_ raw: String) async {
        guard var note, let tag = VaultTag(raw), !note.tags.contains(tag) else { return }
        note.tags.append(tag)
        note.tags.sort()
        await persist(note)
    }

    func delete() async {
        do {
            try await environment.repository.delete(id: noteID)
            player.unload()
            onNoteChanged?()
            onDeleted?()
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    // MARK: - Internals

    private func persist(_ note: Note) async {
        isSaving = true
        defer { isSaving = false }

        var updated = note
        updated.frontmatter.modified = environment.clock.now
        do {
            let saved = try await environment.repository.save(updated)
            self.note = saved
            draftTitle = saved.title
            draftBody = saved.body
            errorMessage = nil
            onNoteChanged?()
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
        }
    }
}
