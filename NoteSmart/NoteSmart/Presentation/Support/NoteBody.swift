//
//  NoteBody.swift
//  NoteSmart
//

import Foundation

/// Splits a note body into the part a human reads and the parts the app renders as
/// widgets.
///
/// A body written from a recording is not free-form prose: `CreateNoteFromRecording`
/// appends `## Action items` and `## Transcript` sections, and the editor draws those
/// as a checklist and a tappable timeline. Both are cut out of the markdown before it
/// is displayed, otherwise every action item would appear twice — once as literal
/// `- [ ]` text and once as a control that actually works.
enum NoteBody {

    /// The only two level-two headings the app writes. A heading the user typed is
    /// left alone and rendered as markdown.
    static let generatedHeadings = ["## Action items", "## Transcript"]

    /// The prose: everything before the first generated section.
    ///
    /// - Parameter cuttingAtAnyHeading: also cut at a heading the user wrote. Used by
    ///   list teasers, where a truncated section is noise, but not by the editor,
    ///   where a user's own `##` structure is content.
    static func prose(from body: String, cuttingAtAnyHeading: Bool = false) -> String {
        let lines = body.components(separatedBy: "\n")

        let cut = lines.firstIndex { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if cuttingAtAnyHeading { return trimmed.hasPrefix("#") }
            return generatedHeadings.contains { trimmed.caseInsensitiveCompare($0) == .orderedSame }
        }

        guard let cut else { return body }
        return lines[lines.startIndex..<cut]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
