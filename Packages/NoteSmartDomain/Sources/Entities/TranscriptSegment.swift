import Foundation

/// One contiguous chunk of recognised speech, anchored to the audio timeline so
/// playback can highlight it.
public struct TranscriptSegment: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let text: String
    public let range: TimeRange
    /// Model confidence in `0...1` when the transcriber reports one.
    public let confidence: Double?

    public init(
        id: UUID = UUID(),
        text: String,
        range: TimeRange,
        confidence: Double? = nil
    ) {
        self.id = id
        self.text = text
        self.range = range
        self.confidence = confidence
    }

    public var isFinal: Bool { confidence != nil || !range.isEmpty }
}

extension TranscriptSegment {
    public static func < (lhs: TranscriptSegment, rhs: TranscriptSegment) -> Bool {
        lhs.range.start < rhs.range.start
    }
}

/// A snapshot of in-flight transcription. `volatileText` is a best guess that
/// will be replaced, so the UI shows it greyed and never mixes it into the
/// final transcript.
public struct TranscriptionProgress: Hashable, Sendable {
    public var volatileText: String
    public var finalized: [TranscriptSegment]
    public var isFinal: Bool

    public init(
        volatileText: String = "",
        finalized: [TranscriptSegment] = [],
        isFinal: Bool = false
    ) {
        self.volatileText = volatileText
        self.finalized = finalized
        self.isFinal = isFinal
    }

    /// What the user should read right now: stable text plus the pending guess.
    public var displayText: String {
        ([finalized.map(\.text).joined(separator: " "), volatileText])
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    public static let empty = TranscriptionProgress()
}
