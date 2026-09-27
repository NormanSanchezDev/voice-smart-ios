//
//  RecordingsListViewModel.swift
//  NoteSmart
//

import Foundation
import NoteSmartDomain
import Observation

/// Backs the previous-recordings list.
///
/// Reads the vault through the repository rather than the index: the markdown files
/// are the source of truth, and the index is a projection that can be stale by a few
/// milliseconds right after a write. Ordering is by `modified` because the most
/// recently touched note is almost always the one being looked for.
@MainActor
@Observable
final class RecordingsListViewModel {

    private(set) var notes: [Note] = []
    private(set) var folders: [VaultPath] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var cards: [NoteCardModel] { notes.map(NoteCardModel.init) }

    /// Reloads after a write. Called on appear, on pull to refresh and after the
    /// recorder saves, so the list never has to guess when the vault changed.
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loaded = try await environment.repository.allNotes()
            notes = loaded.sorted { lhs, rhs in
                lhs.frontmatter.modified == rhs.frontmatter.modified
                    ? lhs.fileName < rhs.fileName
                    : lhs.frontmatter.modified > rhs.frontmatter.modified
            }
            folders = try await environment.repository.folders()
            errorMessage = nil
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
        }
    }

    func note(for id: NoteID) -> Note? {
        notes.first { $0.id == id }
    }

    func delete(_ note: Note) async {
        do {
            try await environment.repository.delete(id: note.id)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = AppErrorMessage.text(for: error)
        }
    }
}
