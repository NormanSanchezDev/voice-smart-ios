import Foundation

public enum NoteSource: String, Sendable, Codable {
    case voice
    case manual
    case imported
}

/// Pointer to the audio a note was born from, stored in frontmatter so a vault
/// stays self-describing even if the app is gone.
public struct AudioRef: Hashable, Sendable, Codable {
    public let fileName: String
    public let duration: TimeInterval

    public init(fileName: String, duration: TimeInterval) {
        self.fileName = fileName
        self.duration = duration
    }
}

/// The YAML block at the top of a markdown file. Kept deliberately small and flat
/// so it round-trips through Obsidian without surprises.
public struct NoteFrontmatter: Hashable, Sendable, Codable {
    public var title: String
    public var created: Date
    public var modified: Date
    public var tags: [VaultTag]
    public var audio: AudioRef?
    public var source: NoteSource
    /// `true` once on-device AI touched the body. Drives the "AI edited" badge.
    public var enriched: Bool

    public init(
        title: String,
        created: Date,
        modified: Date,
        tags: [VaultTag] = [],
        audio: AudioRef? = nil,
        source: NoteSource = .manual,
        enriched: Bool = false
    ) {
        self.title = title
        self.created = created
        self.modified = modified
        self.tags = tags
        self.audio = audio
        self.source = source
        self.enriched = enriched
    }
}
