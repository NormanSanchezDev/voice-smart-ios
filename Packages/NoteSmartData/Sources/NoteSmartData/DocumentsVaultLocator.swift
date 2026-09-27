import Foundation
import NoteSmartDomain

/// Locates the vault inside the app's Documents directory.
///
/// The markdown files stay plain and readable outside the app; the app never
/// depends on this location being Documents forever, which is why call sites use
/// the `VaultLocator` protocol.
public struct DocumentsVaultLocator: VaultLocator {
    public let rootURL: URL
    public let recordingsURL: URL

    public init(rootURL: URL, recordingsURL: URL) {
        self.rootURL = rootURL
        self.recordingsURL = recordingsURL
    }

    /// `~/Documents/Vault`, matching what a user would see in Files.
    public static func documentsDefault(
        fileManager: FileManager = .default
    ) throws -> DocumentsVaultLocator {
        let documents = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = documents.appendingPathComponent("Vault", isDirectory: true)
        return DocumentsVaultLocator(
            rootURL: root,
            recordingsURL: root.appendingPathComponent("Recordings", isDirectory: true)
        )
    }

    public func ensureVaultExists() async throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
    }
}
