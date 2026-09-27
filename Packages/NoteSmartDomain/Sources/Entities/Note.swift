import Foundation

/// A vault note. The file on disk is the source of truth; this is its in-memory
/// shape.
public struct Note: Hashable, Sendable, Codable, Identifiable {
    public let id: NoteID
    /// Folder holding the file, relative to the vault root.
    public var folder: VaultPath
    /// File name including the `.md` extension.
    public var fileName: String
    public var frontmatter: NoteFrontmatter
    /// Markdown below the frontmatter, including any `[[wikilinks]]`.
    public var body: String
    /// Time-indexed transcript, kept out of `body` so editing prose never
    /// destroys the ability to play audio back against the words.
    public var transcript: [TranscriptSegment]

    public init(
        id: NoteID = NoteID(),
        folder: VaultPath = VaultPath(),
        fileName: String,
        frontmatter: NoteFrontmatter,
        body: String = "",
        transcript: [TranscriptSegment] = []
    ) {
        self.id = id
        self.folder = folder
        self.fileName = fileName
        self.frontmatter = frontmatter
        self.body = body
        self.transcript = transcript
    }

    public var title: String {
        get { frontmatter.title }
        set { frontmatter.title = newValue }
    }

    public var tags: [VaultTag] {
        get { frontmatter.tags }
        set { frontmatter.tags = newValue }
    }

    public var isEditedByAI: Bool { frontmatter.enriched }

    /// Relative path of the file inside the vault.
    public var relativePath: String {
        folder.isRoot ? fileName : "\(folder.description)/\(fileName)"
    }

    public func url(relativeTo root: URL) -> URL {
        folder.url(relativeTo: root).appendingPathComponent(fileName)
    }

    public var transcriptText: String {
        transcript.map(\.text).joined(separator: " ")
    }

    /// Segment active at a given playback time, for highlight-as-you-listen.
    public func segment(at time: TimeInterval) -> TranscriptSegment? {
        transcript.first { $0.range.contains(time) }
    }
}
