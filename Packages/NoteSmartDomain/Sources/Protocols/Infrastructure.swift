import Foundation

/// Resolves where the vault lives. A protocol rather than a constant so the
/// location can move to iCloud later without touching call sites.
public protocol VaultLocator: Sendable {
    /// Root of the vault. Creating it is the caller's job; see `ensureVaultExists`.
    var rootURL: URL { get }
    /// Where audio attachments are written.
    var recordingsURL: URL { get }
    /// Creates the vault and recordings directories if missing.
    func ensureVaultExists() async throws
}

/// Injected clock. Keeps "now" controllable in tests instead of reaching for
/// `Date()` inside domain logic.
public protocol DateProvider: Sendable {
    var now: Date { get }
}

public struct SystemDateProvider: DateProvider {
    public init() {}
    public var now: Date { .now }
}

/// Fixed clock for tests and previews.
public struct FixedDateProvider: DateProvider {
    public let now: Date
    public init(now: Date) { self.now = now }
}
