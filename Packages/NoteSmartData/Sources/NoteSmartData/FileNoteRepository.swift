import Foundation
import NoteSmartDomain

/// Narrow seam the repository uses to keep the search index fresh, so it does not
/// depend on a particular search implementation.
public protocol NoteIndexWriting: Sendable {
    func index(_ note: Note) async throws
    func removeFromIndex(noteID: NoteID) async throws
}

/// The vault's source of truth: plain `.md` files on disk.
///
/// An actor because every operation here is read-modify-write against the file
/// system, and two concurrent saves must not race to pick the same free name.
/// Every write is atomic, so a crash mid-save leaves the previous version intact
/// rather than a half-written note.
public actor FileNoteRepository: NoteRepository {
    private let locator: any VaultLocator
    private let fileManager: FileManager
    private var index: (any NoteIndexWriting)?

    public init(
        locator: any VaultLocator,
        fileManager: FileManager = .default,
        index: (any NoteIndexWriting)? = nil
    ) {
        self.locator = locator
        self.fileManager = fileManager
        self.index = index
    }

    /// The indexer needs this repository to rescan, and this repository needs the
    /// indexer to stay fresh, so neither can be built first with the other in
    /// hand. Attaching the index once both objects exist breaks that cycle; the
    /// composition root calls this before any note is read or written.
    public func attachIndex(_ index: any NoteIndexWriting) {
        self.index = index
    }

    nonisolated public var rootURL: URL { locator.rootURL }

    // MARK: - Reading

    public func allNotes() async throws -> [Note] {
        try ensureAvailable()
        return Self.markdownFiles(in: locator.rootURL, fileManager: fileManager).compactMap { url in
            try? readNote(at: url)
        }
    }

    public func note(id: NoteID) async throws -> Note? {
        try await allNotes().first { $0.id == id }
    }

    public func note(atRelativePath path: String) async throws -> Note? {
        try ensureAvailable()
        let url = locator.rootURL.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try readNote(at: url)
    }

    public func folders() async throws -> [VaultPath] {
        try ensureAvailable()
        return Self.folderPaths(in: locator.rootURL, fileManager: fileManager)
    }

    // MARK: - Writing

    @discardableResult
    public func save(_ note: Note) async throws -> Note {
        try ensureAvailable()

        var stored = note
        let folderURL = note.folder.url(relativeTo: locator.rootURL)
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let destination = stored.url(relativeTo: locator.rootURL)
        var needsNewName = stored.fileName.isEmpty
        var staleURL: URL?

        // The title drives the file name, so a title change renames the file on
        // disk. Wikilinks resolve by title in the index, so the old name is safe
        // to drop once the new one is written.
        if !needsNewName {
            let desired = NoteFileNaming.fileName(for: note.frontmatter.title)
            if desired != stored.fileName, let existing = try? readNote(at: destination), existing.id == stored.id {
                staleURL = destination
                needsNewName = true
            }
        }

        if !needsNewName, fileManager.fileExists(atPath: destination.path) {
            // The name is taken. Overwriting is only correct when the file on disk
            // is this very note, which is what happens on an ordinary re-save.
            let existingID = try? readNote(at: destination).id
            needsNewName = existingID != stored.id
        }

        if needsNewName {
            stored.fileName = try await availableFileName(
                for: note.title,
                in: note.folder,
                excluding: note.id
            )
        }

        let data = Data(NoteMarkdown.encode(stored).utf8)
        let newURL = stored.url(relativeTo: locator.rootURL)
        try data.write(to: newURL, options: [.atomic])

        // Only drop the old file after the new one landed, so a failed write
        // never loses the note.
        if let staleURL, staleURL != newURL {
            try? fileManager.removeItem(at: staleURL)
        }

        try? await index?.index(stored)
        return stored
    }

    public func delete(id: NoteID) async throws {
        guard let note = try await note(id: id) else {
            throw NoteError.noteNotFound(id)
        }
        try await delete(atRelativePath: note.relativePath)
    }

    public func delete(atRelativePath path: String) async throws {
        let url = locator.rootURL.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else {
            throw NoteError.noteNotFoundAtPath(path)
        }
        // Read the id before the file is gone, otherwise the index keeps a ghost.
        let removedID = try? readNote(at: url).id
        try fileManager.removeItem(at: url)

        if let removedID {
            try? await index?.removeFromIndex(noteID: removedID)
        }
    }

    @discardableResult
    public func move(_ note: Note, to folder: VaultPath) async throws -> Note {
        try ensureAvailable()
        let source = note.url(relativeTo: locator.rootURL)
        guard fileManager.fileExists(atPath: source.path) else {
            throw NoteError.noteNotFound(note.id)
        }

        let destinationFolder = folder.url(relativeTo: locator.rootURL)
        try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        var moved = note
        moved.folder = folder

        // The old name may already exist in the destination folder.
        let taken = Set(try fileNames(in: destinationFolder))
        if taken.contains(moved.fileName) {
            moved.fileName = NoteFileNaming.uniqueFileName(base: moved.fileName) { taken.contains($0) }
        }

        try fileManager.moveItem(at: source, to: moved.url(relativeTo: locator.rootURL))

        try? await index?.removeFromIndex(noteID: note.id)
        try? await index?.index(moved)
        return moved
    }

    public func availableFileName(
        for title: String,
        in folder: VaultPath,
        excluding id: NoteID?
    ) async throws -> String {
        let folderURL = folder.url(relativeTo: locator.rootURL)
        var taken: Set<String> = []
        if fileManager.fileExists(atPath: folderURL.path) {
            taken = Set(try fileNames(in: folderURL))
        }
        // The note being renamed must not block its own new name.
        if let id, let existing = try? await note(id: id) {
            taken.remove(existing.fileName)
        }

        let base = NoteFileNaming.fileName(for: title)
        return NoteFileNaming.uniqueFileName(base: base, isTaken: { taken.contains($0) })
    }

    // MARK: - File system helpers

    private func ensureAvailable() throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: locator.rootURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw NoteError.vaultUnavailable(reason: "missing \(locator.rootURL.lastPathComponent) directory")
        }
    }

    private func fileNames(in folder: URL) throws -> [String] {
        try fileManager.contentsOfDirectory(atPath: folder.path)
            .filter { $0.lowercased().hasSuffix(NoteFileNaming.extensionSuffix) }
    }

    private func readNote(at url: URL) throws -> Note {
        let text = try String(contentsOf: url, encoding: .utf8)
        return try NoteMarkdown.decode(
            text,
            fileName: url.lastPathComponent,
            folder: Self.folderPath(for: url.deletingLastPathComponent(), root: locator.rootURL)
        )
    }

    // MARK: - Pure enumeration helpers

    /// Directory enumeration runs in a synchronous function on purpose:
    /// `FileManager.DirectoryEnumerator` cannot be iterated from an async context.
    nonisolated static func markdownFiles(in directory: URL, fileManager: FileManager) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var files: [URL] = []
        for case let url as URL in enumerator {
            if url.lastPathComponent == Self.recordingsFolderName {
                enumerator.skipDescendants()
                continue
            }
            guard url.pathExtension.lowercased() == "md" else { continue }
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
            files.append(url)
        }
        return files
    }

    nonisolated static func folderPaths(in root: URL, fileManager: FileManager) -> [VaultPath] {
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var found: [VaultPath] = []
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }
            // Recordings hold audio, not notes; it is not a user-facing folder.
            if url.lastPathComponent == recordingsFolderName {
                enumerator.skipDescendants()
                continue
            }
            found.append(folderPath(for: url, root: root))
        }
        return found.sorted { $0.description < $1.description }
    }

    /// Maps a directory URL to its vault-relative `VaultPath`.
    /// Passing a file URL would swallow the file name as a folder component.
    nonisolated static func folderPath(for directory: URL, root: URL) -> VaultPath {
        let rootPath = root.standardizedFileURL.path
        var relative = directory.standardizedFileURL.path
        if relative.hasPrefix(rootPath) {
            relative = String(relative.dropFirst(rootPath.count))
        }
        while relative.hasPrefix("/") { relative.removeFirst() }
        return VaultPath(components: relative.split(separator: "/").map(String.init))
    }

    nonisolated static let recordingsFolderName = "Recordings"
}
