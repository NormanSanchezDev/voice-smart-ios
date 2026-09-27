import Foundation

/// A folder path relative to the vault root, expressed as ordered components.
/// An empty component list is the vault root.
public struct VaultPath: Hashable, Sendable, Codable, CustomStringConvertible {
    public let components: [String]

    public init(components: [String] = []) {
        // Normalise by trimming and dropping empty and "." components.
        self.components = components
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0 != "." && $0 != ".." }
    }

    public var isRoot: Bool { components.isEmpty }

    public var name: String { components.last ?? "" }

    public func appending(_ component: String) -> VaultPath {
        VaultPath(components: components + [component])
    }

    public func appending(path: VaultPath) -> VaultPath {
        VaultPath(components: components + path.components)
    }

    public func deletingLastComponent() -> VaultPath {
        VaultPath(components: Array(components.dropLast()))
    }

    public func isDescendant(of other: VaultPath) -> Bool {
        guard other.components.count <= components.count else { return false }
        return Array(components.prefix(other.components.count)) == other.components
    }

    public func url(relativeTo root: URL) -> URL {
        components.reduce(root) { $0.appendingPathComponent($1, isDirectory: true) }
    }

    /// Human readable form: `/` for the root, `Work/Ideas` otherwise.
    public var description: String {
        isRoot ? "/" : components.joined(separator: "/")
    }
}
