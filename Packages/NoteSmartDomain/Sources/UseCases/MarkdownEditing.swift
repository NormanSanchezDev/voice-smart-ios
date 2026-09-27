import Foundation

/// Markdown mutations. Pure string transforms, no repository access, so they are
/// trivially testable and safe to run on a draft the user has not saved.
public enum MarkdownEditing: Sendable {

    /// Flips the `n`-th task-list checkbox in a body, counting in document order.
    public static func toggleTask(in body: String, at index: Int) throws -> String {
        var seen = 0
        var lines = body.components(separatedBy: "\n")

        for i in lines.indices {
            guard let box = checkboxRange(in: lines[i]) else { continue }
            if seen == index {
                lines[i].replaceSubrange(box, with: lines[i][box].contains(" ") ? "[x]" : "[ ]")
                return lines.joined(separator: "\n")
            }
            seen += 1
        }
        throw NoteError.malformedMarkdown(reason: "No task at index \(index)")
    }

    /// Character range of the `[ ]` / `[x]` marker inside a line, if any.
    static func checkboxRange(in line: String) -> Range<String.Index>? {
        guard let lineStart = line.range(of: #"^\s*[-*+]\s+"#, options: .regularExpression) else {
            return nil
        }
        let afterMarker = lineStart.upperBound
        guard afterMarker < line.endIndex,
              line[afterMarker] == "[",
              let close = line.range(of: "]", range: afterMarker..<line.endIndex)
        else { return nil }
        return afterMarker..<close.upperBound
    }

    /// Every `[[target]]` and `[[target|alias]]` in a body, in document order.
    public static func wikilinks(in body: String) -> [String] {
        var found: [String] = []
        var remainder = Substring(body)
        while let open = remainder.range(of: "[["),
              let close = remainder.range(of: "]]", range: open.upperBound..<remainder.endIndex) {
            let inner = remainder[open.upperBound..<close.lowerBound]
            let target = inner.split(separator: "|", maxSplits: 1).first.map(String.init) ?? ""
            let trimmed = target.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { found.append(trimmed) }
            remainder = remainder[close.upperBound...]
        }
        return found
    }

    /// Every `#tag` outside fenced code blocks, in document order.
    ///
    /// Trailing punctuation is trimmed so a tag at the end of a sentence
    /// (`... today. #done.`) is found. This matches how Obsidian tokenises.
    public static func inlineTags(in body: String) -> [VaultTag] {
        let trailingPunctuation = CharacterSet(charactersIn: ".,;:!?)]}\"'")
        var tags: [VaultTag] = []
        var inFence = false

        for line in body.components(separatedBy: "\n") {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inFence.toggle()
                continue
            }
            guard !inFence else { continue }
            for raw in line.split(whereSeparator: { $0 == " " || $0 == "\t" }) {
                guard raw.hasPrefix("#"), raw.count > 1 else { continue }
                let cleaned = raw.trimmingCharacters(in: trailingPunctuation)
                if let tag = VaultTag(String(cleaned)) { tags.append(tag) }
            }
        }
        return tags
    }

    /// Replaces the note title and renames the file. Returns the stored note.
    public struct RenameNote: Sendable {
        private let repository: any NoteRepository
        private let date: any DateProvider

        public init(repository: any NoteRepository, date: any DateProvider) {
            self.repository = repository
            self.date = date
        }

        public func callAsFunction(_ note: Note, to newTitle: String) async throws -> Note {
            let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw NoteError.malformedMarkdown(reason: "Title cannot be empty")
            }
            var updated = note
            updated.title = trimmed
            updated.frontmatter.modified = date.now
            // Identical title means the file name is still correct.
            guard trimmed != note.title else {
                return try await repository.save(updated)
            }
            updated.fileName = try await repository.availableFileName(
                for: trimmed,
                in: note.folder,
                excluding: note.id
            )
            return try await repository.save(updated)
        }
    }

    /// Moves a note to another folder, keeping its identity and audio reference.
    public struct MoveNote: Sendable {
        private let repository: any NoteRepository
        private let date: any DateProvider

        public init(repository: any NoteRepository, date: any DateProvider) {
            self.repository = repository
            self.date = date
        }

        public func callAsFunction(_ note: Note, to folder: VaultPath) async throws -> Note {
            guard folder != note.folder else { return note }
            var moved = try await repository.move(note, to: folder)
            moved.frontmatter.modified = date.now
            return try await repository.save(moved)
        }
    }
}
