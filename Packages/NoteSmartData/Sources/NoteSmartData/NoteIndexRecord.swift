import Foundation
import NoteSmartDomain
import SwiftData

/// Rebuildable projection of a markdown file, used for search and the link graph.
///
/// Everything here is derived: losing this table costs a rescan, never data.
@Model
public final class NoteIndexRecord {
    /// `NoteID` as a raw UUID, so the index can be queried without loading notes.
    public var id: UUID = UUID()
    public var relativePath: String = ""
    public var folderPath: String = "/"
    public var fileName: String = ""

    public var title: String = ""
    /// Lowercased title + body, pre-joined for tokenising at query time.
    public var searchText: String = ""
    /// Wikilink targets found in the body, without brackets.
    public var links: [String] = []
    public var tags: [String] = []

    public var created: Date = Date.distantPast
    public var modified: Date = Date.distantPast
    public var wordCount: Int = 0
    public var hasAudio: Bool = false
    public var audioDuration: Double = 0
    public var isEnriched: Bool = false
    public var isAIEdited: Bool = false

    public init() {}

    public var noteID: NoteID { NoteID(rawValue: id) }
    public var tagValues: [VaultTag] { tags.compactMap(VaultTag.init) }

    /// Replaces every indexed field from a note. Called on save and on rescan so
    /// the two paths cannot drift.
    public func apply(_ note: Note) {
        id = note.id.rawValue
        relativePath = note.relativePath
        folderPath = note.folder.description
        fileName = note.fileName
        title = note.frontmatter.title
        tags = note.frontmatter.tags.map(\.name)
        created = note.frontmatter.created
        modified = note.frontmatter.modified
        isEnriched = note.frontmatter.enriched
        isAIEdited = note.frontmatter.enriched
        hasAudio = note.frontmatter.audio != nil
        audioDuration = note.frontmatter.audio?.duration ?? 0
        wordCount = note.body.split(whereSeparator: \.isWhitespace).count
        // Distinct targets, first-occurrence order: a note that links the same
        // target twice has one edge, so it must report one link.
        var seenLinks: Set<String> = []
        links = MarkdownEditing.wikilinks(in: note.body).filter { seenLinks.insert($0).inserted }
        searchText = (note.frontmatter.title + "\n" + note.body).lowercased()
    }
}
