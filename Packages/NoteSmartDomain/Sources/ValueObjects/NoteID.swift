import Foundation

/// Stable identity of a note. Survives renames and moves, which is why it is
/// separate from the file path.
public struct NoteID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    public init() {
        self.rawValue = UUID()
    }

    public var description: String {
        rawValue.uuidString
    }
}
