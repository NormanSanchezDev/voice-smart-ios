import Foundation

public struct SearchScope: Hashable, Sendable {
    public var folder: VaultPath?
    public var tags: Set<VaultTag>
    /// Whether to match the note body as well as the title.
    public var includeBody: Bool

    public init(folder: VaultPath? = nil, tags: Set<VaultTag> = [], includeBody: Bool = true) {
        self.folder = folder
        self.tags = tags
        self.includeBody = includeBody
    }

    public static let everything = SearchScope()
}

public struct NoteSearchResult: Hashable, Sendable, Identifiable {
    public let noteID: NoteID
    public let relativePath: String
    public let title: String
    public let snippet: String
    public let tags: [VaultTag]
    /// Higher is better. Not comparable across queries.
    public let score: Double

    public init(
        noteID: NoteID,
        relativePath: String,
        title: String,
        snippet: String,
        tags: [VaultTag],
        score: Double
    ) {
        self.noteID = noteID
        self.relativePath = relativePath
        self.title = title
        self.snippet = snippet
        self.tags = tags
        self.score = score
    }

    public var id: NoteID { noteID }
}

/// Full-text lookup over the vault. Backed by a rebuildable index, never by the
/// database being the source of truth.
public protocol NoteSearch: Sendable {
    func search(_ query: String, scope: SearchScope) async throws -> [NoteSearchResult]
    func allTags() async throws -> [VaultTag]
    /// Re-reads the vault from disk and replaces the index. Must be safe to call
    /// at any time; it is the recovery path for a corrupted index.
    func rebuildIndex() async throws
    /// Incremental updates so search reflects an edit without a full rescan.
    func index(_ note: Note) async throws
    func removeFromIndex(noteID: NoteID) async throws
}

/// Builds the wikilink graph. Deferred in the UI, but the boundary exists now so
/// the feature can land without touching the data layer.
public protocol GraphBuilding: Sendable {
    func graph() async throws -> NoteGraph
}

public struct NoteGraph: Hashable, Sendable {
    public struct Node: Hashable, Sendable, Identifiable {
        public let id: NoteID
        public let title: String
        public let linkCount: Int

        public init(id: NoteID, title: String, linkCount: Int) {
            self.id = id
            self.title = title
            self.linkCount = linkCount
        }
    }

    public struct Edge: Hashable, Sendable, Identifiable {
        public let source: NoteID
        public let target: NoteID
        public var id: String { "\(source.description)->\(target.description)" }

        public init(source: NoteID, target: NoteID) {
            self.source = source
            self.target = target
        }
    }

    public var nodes: [Node]
    public var edges: [Edge]

    public init(nodes: [Node], edges: [Edge]) {
        self.nodes = nodes
        self.edges = edges
    }

    public static let empty = NoteGraph(nodes: [], edges: [])
}
