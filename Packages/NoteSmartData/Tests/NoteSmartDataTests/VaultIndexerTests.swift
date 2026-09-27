import Foundation
import NoteSmartDomain
import SwiftData
import Testing

@testable import NoteSmartData

/// Matches titles only, so a test can prove a hit came from the title.
private extension SearchScope {
    static let titlesOnly = SearchScope(includeBody: false)
}

@Suite("Vault indexer")
struct VaultIndexerTests {
    // MARK: - Fixtures

    private struct Sandbox {
        let root: URL
        let recordings: URL

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appendingPathComponent("index-\(UUID().uuidString)", isDirectory: true)
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

    /// One indexer over an in-memory store, wired to a real file repository, so
    /// tests exercise the same wiring the app uses.
    private func makeStack() async throws -> (sandbox: Sandbox, repository: FileNoteRepository, indexer: VaultIndexer) {
        let sandbox = try Sandbox()
        let repository = FileNoteRepository(locator: sandbox.locator)
        let container = try ModelContainer(
            for: NoteIndexRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let indexer = VaultIndexer(container: container, repository: repository)
        await repository.attachIndex(indexer)
        return (sandbox, repository, indexer)
    }

    private func note(
        title: String,
        body: String = "",
        tags: [VaultTag] = [],
        folder: VaultPath = VaultPath(),
        modified: TimeInterval = 1_700_000_000
    ) -> Note {
        Note(
            folder: folder,
            fileName: NoteFileNaming.fileName(for: title),
            frontmatter: NoteFrontmatter(
                title: title,
                created: Date(timeIntervalSince1970: 1_700_000_000),
                modified: Date(timeIntervalSince1970: modified),
                tags: tags
            ),
            body: body
        )
    }

    // MARK: - Index maintenance

    @Test("An empty vault with notes on disk is indexed by synchronising")
    func synchronizeFillsEmptyIndex() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        let stored = try await repository.save(note(title: "Groceries", body: "Buy milk"))
        try await indexer.synchronize()

        let results = try await indexer.search("groceries", scope: .everything)
        #expect(results.count == 1)
        #expect(results.first?.noteID == stored.id)
    }

    @Test("Indexing a note makes it findable by title")
    func indexThenSearch() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "Dentist appointment", body: "Bring the card"))
        try await indexer.synchronize()

        let results = try await indexer.search("dentist", scope: .everything)
        #expect(results.count == 1)
        #expect(results.first?.title == "Dentist appointment")
    }

    @Test("Re-indexing the same note updates it instead of duplicating it")
    func reindexUpdates() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        var original = try await repository.save(note(title: "Draft", body: "First version"))
        try await indexer.index(original)

        original.frontmatter.title = "Final"
        original.body = "Second version"
        try await repository.save(original)
        try await indexer.index(original)

        let results = try await indexer.search("final", scope: .everything)
        #expect(results.count == 1)
        #expect(results.first?.title == "Final")
        #expect(try await indexer.search("draft", scope: .everything).isEmpty)
    }

    @Test("A note removed from disk leaves the index on a rebuild")
    func rebuildDropsDeletedNotes() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        let keeper = try await repository.save(note(title: "Keeper", body: "stays"))
        let doomed = try await repository.save(note(title: "Doomed", body: "goes"))
        try await indexer.synchronize()
        #expect(try await indexer.search("doomed", scope: .everything).count == 1)

        try await repository.delete(id: doomed.id)
        try await indexer.synchronize()

        #expect(try await indexer.search("doomed", scope: .everything).isEmpty)
        #expect(try await indexer.search("keeper", scope: .everything).first?.noteID == keeper.id)
    }

    @Test("A file added outside the app is picked up by the next synchronise")
    func synchronizePicksUpExternalFiles() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "From app"))
        try await indexer.synchronize()

        // Written straight to the vault, as if the user edited it in Obsidian.
        let outside = Note(
            fileName: "from-obsidian.md",
            frontmatter: NoteFrontmatter(
                title: "From Obsidian",
                created: Date(timeIntervalSince1970: 1_700_000_000),
                modified: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            body: "Edited elsewhere"
        )
        try Data(NoteMarkdown.encode(outside).utf8)
            .write(to: sandbox.root.appendingPathComponent("from-obsidian.md"))

        try await indexer.synchronize()

        let results = try await indexer.search("obsidian", scope: .everything)
        #expect(results.count == 1)
        #expect(results.first?.title == "From Obsidian")
    }

    @Test("Deleting through the repository removes the note from the index")
    func deleteThroughRepositoryUpdatesIndex() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        let stored = try await repository.save(note(title: "Temporary", body: "here"))
        try await indexer.index(stored)
        #expect(try await indexer.search("temporary", scope: .everything).count == 1)

        try await repository.delete(id: stored.id)

        #expect(try await indexer.search("temporary", scope: .everything).isEmpty)
    }

    // MARK: - Search

    @Test("A multi-word query needs every term to match")
    func allTermsRequired() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "Weekly review", body: "budget and hiring"))
        try await repository.save(note(title: "Weekly sync", body: "hiring only"))
        try await indexer.synchronize()

        let both = try await indexer.search("weekly budget", scope: .everything)
        #expect(both.count == 1)
        #expect(both.first?.title == "Weekly review")
    }

    @Test("A title-only scope ignores body text")
    func bodySearchIsOptIn() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "Untitled thought", body: "penguins are birds"))
        try await indexer.synchronize()

        #expect(try await indexer.search("penguins", scope: .everything).count == 1)
        #expect(try await indexer.search("penguins", scope: .titlesOnly).isEmpty)
    }

    @Test("A title match outranks a body-only match")
    func titleMatchRanksHigher() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "Budget", body: "nothing else"))
        try await repository.save(note(title: "Shopping", body: "a long note that mentions budget once"))
        try await indexer.synchronize()

        let results = try await indexer.search("budget", scope: .everything)
        #expect(results.first?.title == "Budget")
    }

    @Test("Search is scoped to a folder when one is given")
    func folderScope() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "Budget home", folder: VaultPath(components: ["personal"])))
        try await repository.save(note(title: "Budget work", folder: VaultPath(components: ["work"])))
        try await indexer.synchronize()

        let work = try await indexer.search(
            "budget",
            scope: SearchScope(folder: VaultPath(components: ["work"]), includeBody: false)
        )
        #expect(work.count == 1)
        #expect(work.first?.title == "Budget work")
    }

    @Test("Search can require a set of tags")
    func tagScope() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "One", tags: [VaultTag("work")!, VaultTag("tax")!]))
        try await repository.save(note(title: "Two", tags: [VaultTag("work")!]))
        try await indexer.synchronize()

        let results = try await indexer.search(
            "one",
            scope: SearchScope(tags: [VaultTag("work")!, VaultTag("tax")!], includeBody: true)
        )
        #expect(results.count == 1)
        #expect(results.first?.title == "One")
    }

    @Test("Punctuation-only and single-letter queries return nothing instead of everything")
    func noiseQueries() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "Something", body: "content"))
        try await indexer.synchronize()

        #expect(try await indexer.search("!!!", scope: .everything).isEmpty)
        #expect(try await indexer.search("a", scope: .everything).isEmpty)
        #expect(try await indexer.search("", scope: .everything).isEmpty)
    }

    @Test("Results carry a snippet around the match")
    func snippet() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        let filler = (1..<60).map { "filler\($0)" }.joined(separator: " ")
        try await repository.save(note(title: "Note", body: "\(filler) the needle is here"))
        try await indexer.synchronize()

        let results = try await indexer.search("needle", scope: .everything)
        #expect(results.count == 1)
        #expect(results.first?.snippet.contains("needle") == true)
    }

    @Test("Tags across the vault are collected and de-duplicated")
    func allTags() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "A", tags: [VaultTag("work")!, VaultTag("tax")!]))
        try await repository.save(note(title: "B", tags: [VaultTag("work")!]))
        try await indexer.synchronize()

        #expect(try await indexer.allTags().map(\.name) == ["tax", "work"])
    }

    // MARK: - Graph

    @Test("Wikilinks become graph edges between notes that exist")
    func graphEdges() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        let search = try await repository.save(note(title: "Search design"))
        let record = try await repository.save(note(title: "Recording", body: "See [[Search design]] for the plan."))
        try await indexer.synchronize()

        let graph = try await indexer.graph()

        #expect(graph.nodes.count == 2)
        #expect(graph.edges.count == 1)
        #expect(graph.edges.first?.source == record.id)
        #expect(graph.edges.first?.target == search.id)
    }

    @Test("A wikilink to a note that does not exist produces no edge")
    func danglingLink() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        try await repository.save(note(title: "Orphan", body: "Points at [[Nothing Here]]."))
        try await indexer.synchronize()

        let graph = try await indexer.graph()

        #expect(graph.nodes.count == 1)
        #expect(graph.edges.isEmpty)
    }

    @Test("Wikilink targets resolve case-insensitively, like Obsidian")
    func linkCaseInsensitive() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        _ = try await repository.save(note(title: "Kitchen Renovation"))
        try await repository.save(note(title: "Ideas", body: "About [[kitchen renovation]]."))
        try await indexer.synchronize()

        #expect(try await indexer.graph().edges.count == 1)
    }

    @Test("Node link counts reflect outgoing links")
    func linkCounts() async throws {
        let (sandbox, repository, indexer) = try await makeStack()
        defer { sandbox.cleanUp() }

        _ = try await repository.save(note(title: "Target"))
        try await repository.save(note(title: "Hub", body: "[[Target]] and [[Target]] again"))
        try await indexer.synchronize()

        let graph = try await indexer.graph()
        let hub = try #require(graph.nodes.first { $0.title == "Hub" })

        #expect(hub.linkCount == 1)
    }
}
