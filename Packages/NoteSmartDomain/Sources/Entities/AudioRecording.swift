import Foundation

public enum AudioFormat: String, Sendable, Codable, CaseIterable {
    /// AAC in an MPEG-4 container. Plays everywhere, small, what we record.
    case m4a
    /// Uncompressed PCM. Only used for intermediate lossless captures.
    case caf
}

/// A file reference handed from the recorder to the transcriber.
public struct AudioFileRef: Hashable, Sendable {
    public let url: URL
    public let locale: Locale
    public let format: AudioFormat

    public init(url: URL, locale: Locale, format: AudioFormat = .m4a) {
        self.url = url
        self.locale = locale
        self.format = format
    }
}

/// A finished recording, described without touching the file system.
public struct AudioRecording: Hashable, Sendable, Identifiable {
    public let id: NoteID
    public let fileName: String
    public let duration: TimeInterval
    public let createdAt: Date
    public let format: AudioFormat

    public init(
        id: NoteID = NoteID(),
        fileName: String,
        duration: TimeInterval,
        createdAt: Date,
        format: AudioFormat = .m4a
    ) {
        self.id = id
        self.fileName = fileName
        self.duration = duration
        self.createdAt = createdAt
        self.format = format
    }

    public var file: AudioFileRef {
        AudioFileRef(url: URL(fileURLWithPath: fileName), locale: Locale.current, format: format)
    }
}

/// A normalised input level plus elapsed time, streamed while recording.
public struct AudioMeterReading: Hashable, Sendable {
    /// Normalised power in `0...1`.
    public let level: Float
    public let elapsed: TimeInterval

    public init(level: Float, elapsed: TimeInterval) {
        self.level = level
        self.elapsed = elapsed
    }
}
