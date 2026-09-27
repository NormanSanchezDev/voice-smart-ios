import Foundation

/// A normalised vault tag. Tags are lowercased, never carry a leading `#`, and
/// internal whitespace is folded into hyphens — the same normalisation Obsidian
/// applies, so vaults stay interoperable.
public struct VaultTag: Hashable, Sendable, Codable, Comparable, CustomStringConvertible {
    public let name: String

    /// Creates a tag, returning `nil` when the input cannot be a valid tag.
    public init?(_ raw: String) {
        let trimmed = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let normalised = trimmed
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: "-", options: .regularExpression)
        guard !normalised.isEmpty, normalised.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "/" }) else {
            return nil
        }
        self.name = normalised
    }

    public var displayText: String { "#\(name)" }

    public var description: String { name }

    public static func < (lhs: VaultTag, rhs: VaultTag) -> Bool { lhs.name < rhs.name }
}
