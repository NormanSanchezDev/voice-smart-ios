import Foundation

public enum AIUnavailableReason: Hashable, Sendable {
    case deviceNotEligible
    case modelNotReady
    case regionNotSupported
    case unknown(String)
}

public enum AIAvailability: Hashable, Sendable {
    case available
    case unavailable(AIUnavailableReason)

    public var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}

/// The structured result of turning raw speech into a usable note.
public struct NoteEnrichment: Hashable, Sendable, Codable {
    public var title: String
    public var summary: String
    public var tags: [VaultTag]
    public var actionItems: [String]
    /// Prose with filler removed and paragraphs split, ready to be the note body.
    public var cleanedMarkdown: String

    public init(
        title: String,
        summary: String = "",
        tags: [VaultTag] = [],
        actionItems: [String] = [],
        cleanedMarkdown: String
    ) {
        self.title = title
        self.summary = summary
        self.tags = tags
        self.actionItems = actionItems
        self.cleanedMarkdown = cleanedMarkdown
    }

    public static func empty(title: String = "Untitled") -> NoteEnrichment {
        NoteEnrichment(title: title, cleanedMarkdown: "")
    }
}

/// Incremental enrichment. Fields are optional because a streaming model fills
/// them in over time; `isFinal` marks the last element.
public struct EnrichmentProgress: Hashable, Sendable {
    public var title: String?
    public var summary: String?
    public var tags: [VaultTag]?
    public var actionItems: [String]?
    public var cleanedMarkdown: String?
    public var isFinal: Bool

    public init(
        title: String? = nil,
        summary: String? = nil,
        tags: [VaultTag]? = nil,
        actionItems: [String]? = nil,
        cleanedMarkdown: String? = nil,
        isFinal: Bool = false
    ) {
        self.title = title
        self.summary = summary
        self.tags = tags
        self.actionItems = actionItems
        self.cleanedMarkdown = cleanedMarkdown
        self.isFinal = isFinal
    }

    /// Collapses a snapshot onto an existing enrichment, keeping previous values
    /// for fields the model has not produced yet.
    public func applied(to base: NoteEnrichment) -> NoteEnrichment {
        NoteEnrichment(
            title: title ?? base.title,
            summary: summary ?? base.summary,
            tags: tags ?? base.tags,
            actionItems: actionItems ?? base.actionItems,
            cleanedMarkdown: cleanedMarkdown ?? base.cleanedMarkdown
        )
    }
}

public enum EnrichmentSource: Hashable, Sendable {
    /// Produced by the on-device foundation model.
    case onDeviceAI
    /// Produced by heuristics, because AI is unavailable on this device.
    case ruleBasedFallback

    public var isAI: Bool { self == .onDeviceAI }
}

/// Turns a raw transcript into a titled, tagged, cleaned note.
public protocol NoteEnricher: Sendable {
    var availability: AIAvailability { get async }

    func enrich(
        transcript: String,
        suggestedTags: [VaultTag],
        locale: Locale
    ) async -> AsyncThrowingStream<EnrichmentProgress, Error>
}
