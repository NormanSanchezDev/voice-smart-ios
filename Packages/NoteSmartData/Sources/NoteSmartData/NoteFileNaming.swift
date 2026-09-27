import Foundation
import NoteSmartDomain

/// Turns a note title into a file name that is safe on every filesystem and still
/// readable in Obsidian's file explorer.
public enum NoteFileNaming {
    public static let extensionSuffix = ".md"
    static let fallback = "untitled"
    static let maxLength = 80

    /// Lowercase, ASCII-folded, hyphen separated. `Crème brûlée & notes!` becomes
    /// `creme-brulee-notes`.
    public static func slug(for title: String) -> String {
        let folded = title
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()

        let mapped = String(folded.map { character -> Character in
            if character.isLetter || character.isNumber { return character }
            return "-"
        })

        let collapsed = String(
            mapped
                .split(separator: "-", omittingEmptySubsequences: true)
                .prefix { _ in true }
                .joined(separator: "-")
        )

        guard !collapsed.isEmpty else { return fallback }
        if collapsed.count <= maxLength { return collapsed }
        return String(collapsed.prefix(maxLength).trimmingCharacters(in: CharacterSet(charactersIn: "-")))
    }

    /// `Some title` -> `some-title.md`.
    public static func fileName(for title: String) -> String {
        slug(for: title) + extensionSuffix
    }

    /// Appends ` 2`, ` 3`, … before the extension until the name is free.
    public static func uniqueFileName(
        base: String,
        isTaken: (String) -> Bool
    ) -> String {
        if !isTaken(base) { return base }

        let stem = base.hasSuffix(extensionSuffix)
            ? String(base.dropLast(extensionSuffix.count))
            : base
        let ext = base.hasSuffix(extensionSuffix) ? extensionSuffix : ""

        var counter = 2
        while true {
            let candidate = "\(stem) \(counter)\(ext)"
            if !isTaken(candidate) { return candidate }
            counter += 1
        }
    }
}
