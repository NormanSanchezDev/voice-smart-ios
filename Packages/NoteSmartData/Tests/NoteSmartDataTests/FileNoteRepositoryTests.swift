import Foundation
import NoteSmartDomain
import Testing

@testable import NoteSmartData

/// Records what the repository told the index to do, so tests can assert the
/// index never drifts from the files.
private actor RecordingIndexSpy: NoteIndexWriting {
    private(set) var indexed: [NoteID] = []
    private(set) var removed: [NoteID] = []

    func index(_ note: Note) async throws { indexed.append(note.id) }
    func removeFromIndex(noteID: NoteID) async throws { removed.append(noteID) }

    var lastIndexed: NoteID? { indexed.last }
    var lastRemoved: NoteID? { removed.last }
}

@Suite("File note repository")
struct FileNoteRepositoryTests {
    /// A throwaway vault per test, so nothing leaks between them.
    private struct Sandbox {
        let root: URL
        let recordings: URL

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appendingPathComponent("vault-\(UUID().uuidString)", isDirectory: true)
            recordings = root.appendingPathComponent("Recordings", isDirectory: true)
            try FileManager.default.createDirectory(at: recordings, withIntermediateDirectories: true)
        }

        var locator: DocumentsVaultLocator {
            DocumentsVaultLocator(rootURL: root, recordingsURL: recordings)
        }

        func cleanUp() {
            try? FileManager.default.removeItem(at: root)
        }
    }

    private func makeNote(
        title: String,
        folder: VaultPath = VaultPath(),
        fileName: String = "",
        tags: [VaultTag] = [],
        body: String = "Body"
    ) -> Note {
        Note(
            folder: folder,
            fileName: fileName,
            frontmatter: NoteFrontmatter(
                title: title,
                created: Date(timeIntervalSince1970: 1_700_000_000),
                modified: Date(timeIntervalSince1970: 1_700_000_000),
                tags: tags,
                source: .voice
            ),
            body: body
        )
    }

    @Test("Saving a new note creates the file and returns the chosen name")
    func saveCreatesFile() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        let stored = try await repository.save(makeNote(title: "Weekly review"))

        #expect(stored.fileName == "weekly-review.md")
        let url = sandbox.root.appendingPathComponent("weekly-review.md")
        #expect(FileManager.default.fileExists(atPath: url.path))

        let readBack = try await repository.note(id: stored.id)
        #expect(readBack?.title == "Weekly review")
    }

    @Test("Re-saving the same note overwrites it instead of creating a copy")
    func reSaveOverwrites() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        let first = try await repository.save(makeNote(title: "Notes"))
        var edited = first
        edited.body = "Rewritten prose"
        let second = try await repository.save(edited)

        #expect(second.fileName == first.fileName)
        let all = try await repository.allNotes()
        #expect(all.count == 1)
        #expect(all.first?.body == "Rewritten prose")
    }

    @Test("A different note with the same title gets a suffixed file name")
    func sameTitleGetsSuffix() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        let first = try await repository.save(makeNote(title: "Ideas"))
        let second = try await repository.save(makeNote(title: "Ideas"))
        let third = try await repository.save(makeNote(title: "Ideas"))

        #expect(first.fileName == "ideas.md")
        #expect(second.fileName == "ideas 2.md")
        #expect(third.fileName == "ideas 3.md")
        #expect(Set([first.fileName, second.fileName, third.fileName]).count == 3)
    }

    @Test("Renaming a note does not collide with its own file")
    func renameDoesNotCollideWithItself() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        var note = try await repository.save(makeNote(title: "Old name"))
        note.frontmatter.title = "New name"
        let renamed = try await repository.save(note)

        #expect(renamed.fileName == "new-name.md")
        #expect(renamed.id == note.id)
        let all = try await repository.allNotes()
        #expect(all.count == 1)
    }

    @Test("Notes in subfolders are found recursively with their folder preserved")
    func nestedFolders() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        let deep = VaultPath(components: ["work", "2026"])
        let stored = try await repository.save(
            makeNote(title: "Nested", folder: deep, fileName: "nested.md")
        )

        #expect(stored.folder == deep)
        #expect(
            FileManager.default.fileExists(
                atPath: sandbox.root.appendingPathComponent("work/2026/nested.md").path
            )
        )
        #expect(try await repository.note(id: stored.id)?.folder == deep)
        #expect(try await repository.note(atRelativePath: "work/2026/nested.md")?.title == "Nested")
    }

    @Test("Folders are listed, and Recordings is not one of them")
    func folderListing() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        _ = try await repository.save(makeNote(title: "In folder", folder: VaultPath(components: ["work"])))
        _ = try await repository.save(makeNote(title: "In nested", folder: VaultPath(components: ["work", "deep"])))

        let folders = try await repository.folders()
        #expect(folders.contains(VaultPath(components: ["work"])))
        #expect(folders.contains(VaultPath(components: ["work", "deep"])))
        #expect(!folders.contains(VaultPath(components: ["Recordings"])))
    }

    @Test("The Recordings folder is skipped when listing notes")
    func recordingsAreNotNotes() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        // A stray markdown file where audio should be must not become a note.
        try "Audio transcript leftover".write(
            to: sandbox.recordings.appendingPathComponent("stray.md"),
            atomically: true,
            encoding: .utf8
        )
        _ = try await repository.save(makeNote(title: "Real note"))

        let all = try await repository.allNotes()
        #expect(all.count == 1)
        #expect(all.first?.title == "Real note")
    }

    @Test("Deleting a note removes the file and tells the index")
    func deleteRemoves() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let spy = RecordingIndexSpy()
        let repository = FileNoteRepository(locator: sandbox.locator, index: spy)

        let stored = try await repository.save(makeNote(title: "Doomed"))
        try await repository.delete(id: stored.id)

        #expect(try await repository.allNotes().isEmpty)
        #expect(await spy.lastRemoved == stored.id)
        #expect(FileManager.default.fileExists(atPath: sandbox.root.appendingPathComponent("doomed.md").path) == false)
    }

    @Test("Deleting a note that is not there is an error, not a silent success")
    func deleteMissingThrows() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        await #expect(throws: NoteError.self) {
            try await repository.delete(id: NoteID())
        }
        await #expect(throws: NoteError.self) {
            try await repository.delete(atRelativePath: "nope.md")
        }
    }

    @Test("Moving a note relocates the file and updates the index")
    func moveRelocates() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let spy = RecordingIndexSpy()
        let repository = FileNoteRepository(locator: sandbox.locator, index: spy)

        let stored = try await repository.save(makeNote(title: "Movable"))
        let moved = try await repository.move(stored, to: VaultPath(components: ["archive"]))

        #expect(moved.folder == VaultPath(components: ["archive"]))
        #expect(FileManager.default.fileExists(atPath: sandbox.root.appendingPathComponent("archive/movable.md").path))
        #expect(FileManager.default.fileExists(atPath: sandbox.root.appendingPathComponent("movable.md").path) == false)
        #expect(await spy.lastIndexed == stored.id)
        #expect(await spy.lastRemoved == stored.id)
        #expect(try await repository.note(id: stored.id)?.folder == VaultPath(components: ["archive"]))
    }

    @Test("Moving onto an occupied name suffixes rather than overwriting")
    func moveCollisionSuffixes() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        // The same file name can exist in two different folders.
        let a = try await repository.save(makeNote(title: "A", fileName: "same.md"))
        _ = try await repository.save(makeNote(title: "B", folder: VaultPath(components: ["dest"]), fileName: "same.md"))

        let moved = try await repository.move(a, to: VaultPath(components: ["dest"]))

        #expect(moved.fileName == "same 2.md")
        #expect(
            FileManager.default.fileExists(
                atPath: sandbox.root.appendingPathComponent("dest/same.md").path
            ),
            "The note already in the destination must survive the move"
        )
        #expect(try await repository.note(id: a.id)?.body == "Body")
    }

    @Test("Moving a note that is not on disk is an error")
    func moveMissingThrows() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        let ghost = makeNote(title: "Ghost", fileName: "ghost.md")
        await #expect(throws: NoteError.self) {
            try await repository.move(ghost, to: VaultPath(components: ["x"]))
        }
    }

    @Test("A missing vault directory reports that the vault is unavailable")
    func missingVault() async throws {
        let locator = DocumentsVaultLocator(
            rootURL: FileManager.default.temporaryDirectory.appendingPathComponent("absent-\(UUID().uuidString)"),
            recordingsURL: FileManager.default.temporaryDirectory.appendingPathComponent("absent-recordings")
        )
        let repository = FileNoteRepository(locator: locator)

        await #expect(throws: NoteError.self) {
            _ = try await repository.allNotes()
        }
    }

    @Test("A file without frontmatter is skipped by listing, not surfaced as a broken note")
    func malformedFileIsSkipped() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        try "no frontmatter here".write(
            to: sandbox.root.appendingPathComponent("broken.md"),
            atomically: true,
            encoding: .utf8
        )
        let stored = try await repository.save(makeNote(title: "Good note"))

        let all = try await repository.allNotes()
        #expect(all.count == 1)
        #expect(all.first?.id == stored.id)
    }

    @Test("A fresh file name is offered without needing the folder to exist yet")
    func availableFileNameInMissingFolder() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        let name = try await repository.availableFileName(
            for: "Brand new",
            in: VaultPath(components: ["not", "created"]),
            excluding: nil
        )
        #expect(name == "brand-new.md")
    }

    @Test("Concurrent saves of the same title never pick the same file name")
    func concurrentSavesAreSerialised() async throws {
        let sandbox = try Sandbox()
        defer { sandbox.cleanUp() }
        let repository = FileNoteRepository(locator: sandbox.locator)

        let results = try await withThrowingTaskGroup(of: String.self) { group in
            for index in 0..<8 {
                group.addTask {
                    let stored = try await repository.save(
                        makeNote(title: "Race", body: "body \(index)")
                    )
                    return stored.fileName
                }
            }
            var names: [String] = []
            for try await name in group { names.append(name) }
            return names
        }

        #expect(results.count == 8)
        #expect(Set(results).count == 8, "Every parallel save must claim a distinct file name")
        #expect(try await repository.allNotes().count == 8)
    }
}
