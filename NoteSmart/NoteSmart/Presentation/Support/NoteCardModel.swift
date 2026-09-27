//
//  NoteCardModel.swift
//  NoteSmart
//

import DSAtoms
import DSOrganisms
import Foundation
import NoteSmartDomain

/// A note flattened into the primitives `DSNoteCard` renders.
///
/// The design system takes primitives so it stays reusable; this is the seam where a
/// domain entity becomes pixels. Doing the mapping here rather than in each list cell
/// keeps badge rules and preview extraction in one place, so a note looks the same in
/// the list, in a search result and in a folder.
struct NoteCardModel: Identifiable {

    let id: NoteID
    let title: String
    let preview: String
    let date: Date
    let duration: TimeInterval?
    let tags: [String]
    let badges: [DSNoteCard.Badge]

    init(_ note: Note) {
        self.id = note.id
        self.title = note.title
        self.preview = Self.previewText(for: note)
        self.date = note.frontmatter.modified
        self.duration = note.frontmatter.audio?.duration
        self.tags = note.tags.map(\.displayText)
        self.badges = Self.badges(for: note)
    }

    func card(action: @escaping () -> Void) -> DSNoteCard {
        DSNoteCard(
            title: title,
            preview: preview,
            date: date,
            duration: duration,
            tags: tags,
            badges: badges,
            action: action
        )
    }

    // MARK: - Mapping rules

    private static func badges(for note: Note) -> [DSNoteCard.Badge] {
        var badges: [DSNoteCard.Badge] = []

        if note.frontmatter.enriched {
            badges.append(.init("IA", systemImage: "sparkles", tone: .accent))
        }

        switch note.frontmatter.source {
        case .voice:
            badges.append(.init("Voz", systemImage: "waveform"))
        case .manual:
            badges.append(.init("Texto", systemImage: "pencil"))
        case .imported:
            badges.append(.init("Importada", systemImage: "square.and.arrow.down"))
        }

        let pending = pendingTaskCount(in: note.body)
        if pending > 0 {
            badges.append(.init("\(pending)", systemImage: "checklist", tone: .warning))
        }

        return badges
    }

    /// First sentence-ish run of prose from the body.
    ///
    /// A note written from a recording starts with the AI summary, then prose, then
    /// `## Action items`, then the timestamped transcript. Only the prose says
    /// anything about the note, so every section is dropped along with the summary
    /// line the user has already read in the editor.
    private static func previewText(for note: Note) -> String {
        let prose = NoteBody.prose(from: note.body, cuttingAtAnyHeading: true)
            .components(separatedBy: "\n")
            .map { line -> String in
                guard !line.hasPrefix(">") else { return "" }
                return line
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "-*+# "))
                    .trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !prose.isEmpty { return truncate(prose) }
        return truncate(note.transcriptText)
    }

    private static func pendingTaskCount(in body: String) -> Int {
        body.components(separatedBy: "\n").reduce(into: 0) { total, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- [ ]") || trimmed.hasPrefix("* [ ]") else { return }
            total += 1
        }
    }

    private static func truncate(_ text: String, limit: Int = 180) -> String {
        guard text.count > limit else { return text }
        let clipped = text.prefix(limit)
        guard let lastSpace = clipped.lastIndex(of: " ") else { return String(clipped) + "…" }
        return String(clipped[clipped.startIndex..<lastSpace]) + "…"
    }
}
