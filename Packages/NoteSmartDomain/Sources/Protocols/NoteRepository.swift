import Foundation

/// Storage boundary for notes. Implemented in Data by a plain-file vault, so the
/// markdown stays readable and syncable outside the app.
public protocol NoteRepository: Sendable {
    func allNotes() async throws -> [Note]
    func note(id: NoteID) async throws -> Note?
    func note(atRelativePath path: String) async throws -> Note?

    /// Writes atomically and refreshes the search index. Returns the note as
    /// stored, which may have a new `fileName` on a first save.
    @discardableResult
    func save(_ note: Note) async throws -> Note

    func delete(id: NoteID) async throws
    func delete(atRelativePath path: String) async throws

    /// Moves the file to another folder, keeping its identity.
    @discardableResult
    func move(_ note: Note, to folder: VaultPath) async throws -> Note

    /// A free file name for a title inside a folder, appending ` 2`, ` 3`… on
    /// collision. Used so a duplicate title never silently overwrites a note.
    func availableFileName(for title: String, in folder: VaultPath, excluding id: NoteID?) async throws -> String

    /// Every folder present in the vault, including empty ones.
    func folders() async throws -> [VaultPath]
}
