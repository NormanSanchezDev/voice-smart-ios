import Foundation
import NoteSmartDomain
import SwiftData

/// Search and link graph over the vault, backed by SwiftData.
///
/// Scoring is an in-memory BM25-flavoured scan of the index rather than an FTS5
/// table. A personal vault holds hundreds of notes, which scans in milliseconds,
/// and it keeps the schema portable. If vaults ever reach thousands of notes, this
/// is the seam where FTS5 should replace the scan.
public actor VaultIndexer: NoteSearch, NoteIndexWriting, GraphBuilding {
    private let context: ModelContext
    private let repository: any NoteRepository

    /// Takes the container, not a context: `ModelContext` is not `Sendable`, so an
    /// indexer that borrowed one from the main actor would be a data race waiting to
    /// happen. Building the context inside the actor gives search its own queue,
    /// which is also what keeps typing in the search field smooth.
    public init(container: ModelContainer, repository: any NoteRepository) {
        self.context = ModelContext(container)
        self.repository = repository
    }

    // MARK: - Index maintenance

    public func index(_ note: Note) async throws {
        let record = try record(for: note.id) ?? NoteIndexRecord()
        record.apply(note)
        if record.modelContext == nil {
            context.insert(record)
        }
        try context.save()
    }

    public func removeFromIndex(noteID: NoteID) async throws {
        guard let record = try record(for: noteID) else { return }
        context.delete(record)
        try context.save()
    }

    public func rebuildIndex() async throws {
        // Replace wholesale: a rescan is the recovery path for a bad index, and
        // patching leaves behind rows for files that no longer exist.
        try context.delete(model: NoteIndexRecord.self)

        for note in try await repository.allNotes() {
            let record = NoteIndexRecord()
            record.apply(note)
            context.insert(record)
        }
        try context.save()
    }

    /// Ensures the index matches the vault, rescanning only when it is empty or
    /// stale. Cheap enough to call on every launch.
    public func synchronize() async throws {
        let indexed = try context.fetchCount(FetchDescriptor<NoteIndexRecord>())
        let files = try await repository.allNotes().count
        if indexed == 0 && files > 0 {
            try await rebuildIndex()
            return
        }
        if indexed != files {
            try await rebuildIndex()
        }
    }

    // MARK: - Search

    public func search(_ query: String, scope: SearchScope) async throws -> [NoteSearchResult] {
        let terms = Self.tokenize(query)
        guard !terms.isEmpty else { return [] }

        let records = try context.fetch(FetchDescriptor<NoteIndexRecord>())
        let candidates = records.filter { record in
            if let folder = scope.folder, !folder.isRoot || record.folderPath != "/" {
                let recordFolder = VaultPath(components: record.folderPath.split(separator: "/").map(String.init))
                guard recordFolder.isDescendant(of: folder) else { return false }
            }
            if !scope.tags.isEmpty {
                let noteTags = Set(record.tagValues)
                guard scope.tags.isSubset(of: noteTags) else { return false }
            }
            return true
        }

        let scored: [(NoteIndexRecord, Double)] = candidates.compactMap { record in
            guard let score = Self.score(record: record, terms: terms, includeBody: scope.includeBody) else {
                return nil
            }
            return (record, score)
        }

        let best = scored.map(\.1).max() ?? 1
        return scored
            .sorted { lhs, rhs in
                lhs.1 == rhs.1 ? lhs.0.modified > rhs.0.modified : lhs.1 > rhs.1
            }
            .prefix(50)
            .map { record, score in
                NoteSearchResult(
                    noteID: record.noteID,
                    relativePath: record.relativePath,
                    title: record.title,
                    snippet: Self.snippet(for: record, terms: terms),
                    tags: record.tagValues,
                    score: best > 0 ? score / best : 0
                )
            }
    }

    public func allTags() async throws -> [VaultTag] {
        let records = try context.fetch(FetchDescriptor<NoteIndexRecord>())
        let names = records.flatMap(\.tags)
        return Array(Set(names.compactMap(VaultTag.init))).sorted()
    }

    // MARK: - Graph

    public func graph() async throws -> NoteGraph {
        let records = try context.fetch(FetchDescriptor<NoteIndexRecord>())
        let byTitle = Dictionary(records.map { (NoteTitleKey($0.title), $0.noteID) }, uniquingKeysWith: { first, _ in first })

        let nodes = records.map { record in
            NoteGraph.Node(
                id: record.noteID,
                title: record.title,
                linkCount: record.links.count
            )
        }

        var edges: [NoteGraph.Edge] = []
        var seen: Set<String> = []
        for record in records {
            for target in record.links {
                guard let targetID = byTitle[NoteTitleKey(target)] else { continue }
                let key = "\(record.noteID.description)->\(targetID.description)"
                guard seen.insert(key).inserted else { continue }
                edges.append(NoteGraph.Edge(source: record.noteID, target: targetID))
            }
        }

        return NoteGraph(nodes: nodes, edges: edges)
    }

    // MARK: - Helpers

    private func record(for id: NoteID) throws -> NoteIndexRecord? {
        var descriptor = FetchDescriptor<NoteIndexRecord>(
            predicate: #Predicate { $0.id == id.rawValue }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count > 1 }
    }

    /// `nil` when the record does not match at all. Title hits count triple, and
    /// requiring every term keeps multi-word queries from matching noise.
    static func score(record: NoteIndexRecord, terms: [String], includeBody: Bool) -> Double? {
        let title = record.title.lowercased()
        let haystack = includeBody ? record.searchText : title

        var total = 0.0
        var matched = 0

        for term in terms {
            let inTitle = title.contains(term)
            let inBody = includeBody && haystack.contains(term)
            guard inTitle || inBody else { continue }
            matched += 1
            total += inTitle ? 3.0 : 1.0
        }

        guard matched == terms.count else { return nil }
        // Shorter notes that match every term are usually the better answer.
        let lengthBoost = 1 / (1 + Double(record.wordCount) / 400)
        return total * lengthBoost
    }

    /// Text around the first match, so the user can judge relevance without opening.
    static func snippet(for record: NoteIndexRecord, terms: [String]) -> String {
        let body = record.searchText
        guard let term = terms.first(where: { body.contains($0) }),
              let range = body.range(of: term) else {
            return String(body.prefix(120))
        }

        let start = body.index(range.lowerBound, offsetBy: -40, limitedBy: body.startIndex) ?? body.startIndex
        let end = body.index(range.upperBound, offsetBy: 80, limitedBy: body.endIndex) ?? body.endIndex

        var snippet = String(body[start..<end]).replacingOccurrences(of: "\n", with: " ")
        if start != body.startIndex { snippet = "…" + snippet }
        if end != body.endIndex { snippet += "…" }
        return snippet
    }
}

/// Wikilink targets are matched case-insensitively, the way Obsidian resolves them.
private struct NoteTitleKey: Hashable {
    let value: String

    init(_ raw: String) {
        value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
