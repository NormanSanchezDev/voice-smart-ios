import Foundation

/// A half-open time range `[start, end)` in seconds, relative to the beginning
/// of a recording.
public struct TimeRange: Hashable, Sendable, Codable {
    public let start: TimeInterval
    public let end: TimeInterval

    public init(start: TimeInterval, end: TimeInterval) {
        self.start = min(start, end)
        self.end = max(start, end)
    }

    public init(duration: TimeInterval) {
        self.init(start: 0, end: duration)
    }

    public var duration: TimeInterval { end - start }
    public var isEmpty: Bool { duration <= 0 }

    public func contains(_ time: TimeInterval) -> Bool {
        time >= start && time < end
    }

    public func overlaps(_ other: TimeRange) -> Bool {
        start < other.end && other.start < end
    }

    public func union(_ other: TimeRange) -> TimeRange {
        TimeRange(start: min(start, other.start), end: max(end, other.end))
    }

    public func intersection(_ other: TimeRange) -> TimeRange? {
        let lower = max(start, other.start)
        let upper = min(end, other.end)
        guard lower < upper else { return nil }
        return TimeRange(start: lower, end: upper)
    }
}

extension TimeRange {
    /// Format as `m:ss` (or `h:mm:ss` past an hour), for transcripts and players.
    public func timestampText() -> String {
        let total = Int(start.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
