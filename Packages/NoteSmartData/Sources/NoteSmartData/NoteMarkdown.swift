import Foundation
import NoteSmartDomain

/// Turns a `Note` into the text of a markdown file and back.
///
/// Only a small, flat subset of YAML is used for frontmatter, on purpose: the
/// block has to round-trip through Obsidian and other editors without surprises.
/// Supported per key: plain scalars, double-quoted scalars, single-quoted
/// scalars, flow sequences (`[a, b]`) and block sequences. Nested maps and
/// multi-line scalars are not produced and are skipped when reading.
public enum NoteMarkdown {
    // MARK: - Keys

    enum Key {
        static let id = "id"
        static let title = "title"
        static let created = "created"
        static let modified = "modified"
        static let tags = "tags"
        static let source = "source"
        static let enriched = "enriched"
        static let audio = "audio"
        static let audioDuration = "audio_duration"
        static let transcript = "transcript"
    }

    // MARK: - Encoding

    public static func encode(_ note: Note) -> String {
        var lines: [String] = ["---"]

        lines.append("\(Key.id): \(note.id.description)")
        lines.append("\(Key.title): \(quoted(note.frontmatter.title))")
        lines.append("\(Key.created): \(iso8601(note.frontmatter.created))")
        lines.append("\(Key.modified): \(iso8601(note.frontmatter.modified))")
        lines.append("\(Key.tags): [\(note.frontmatter.tags.map(\.name).map(quoted).joined(separator: ", "))]")
        lines.append("\(Key.source): \(note.frontmatter.source.rawValue)")
        lines.append("\(Key.enriched): \(note.frontmatter.enriched)")

        if let audio = note.frontmatter.audio {
            lines.append("\(Key.audio): \(quoted(audio.fileName))")
            lines.append("\(Key.audioDuration): \(formatNumber(audio.duration))")
        }

        if !note.transcript.isEmpty {
            lines.append("\(Key.transcript): \(singleQuoted(transcriptJSON(note.transcript)))")
        }

        lines.append("---")
        lines.append("")

        let body = note.body.trimmingCharacters(in: .newlines)
        if !body.isEmpty {
            lines.append(body)
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Decoding

    /// Parses a markdown file. Throws when the file has no usable frontmatter,
    /// because a note without a title cannot be identified.
    public static func decode(_ text: String, fileName: String, folder: VaultPath) throws -> Note {
        let parsed = try parseFrontmatter(text)
        guard let title = parsed[Key.title]?.first, !title.isEmpty else {
            throw NoteError.malformedMarkdown(reason: "\(fileName): missing title")
        }

        let created = parsed[Key.created]?.first.flatMap(parseDate) ?? .now
        let modified = parsed[Key.modified]?.first.flatMap(parseDate) ?? created
        let tags = (parsed[Key.tags] ?? []).compactMap(VaultTag.init)
        let source = parsed[Key.source]?.first.flatMap(NoteSource.init(rawValue:)) ?? .manual
        let enriched = parsed[Key.enriched]?.first?.lowercased() == "true"

        var audio: AudioRef?
        if let file = parsed[Key.audio]?.first, !file.isEmpty {
            let duration = parsed[Key.audioDuration]?.first.flatMap(Double.init) ?? 0
            audio = AudioRef(fileName: file, duration: duration)
        }

        let transcript = parsed[Key.transcript]?.first.flatMap(decodeTranscriptJSON) ?? []

        let frontmatter = NoteFrontmatter(
            title: title,
            created: created,
            modified: modified,
            tags: tags,
            audio: audio,
            source: source,
            enriched: enriched
        )

        return Note(
            id: parsed[Key.id]?.first.flatMap(UUID.init(uuidString:)).map(NoteID.init(rawValue:)) ?? NoteID(),
            folder: folder,
            fileName: fileName,
            frontmatter: frontmatter,
            body: body(of: text),
            transcript: transcript
        )
    }

    /// Everything after the closing `---` fence, trimmed.
    public static func body(of text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        guard let closeIndex = frontmatterEndLine(in: lines) else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return lines[(closeIndex + 1)...]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Index of the line holding the closing fence, or `nil` when the document has
    /// no frontmatter.
    static func frontmatterEndLine(in lines: [String]) -> Int? {
        guard let first = lines.first, first.trimmingCharacters(in: .whitespaces) == "---" else {
            return nil
        }
        for index in lines.indices.dropFirst() where lines[index].trimmingCharacters(in: .whitespaces) == "---" {
            return index
        }
        return nil
    }

    /// Splits a document into its frontmatter key/value pairs.
    private static func parseFrontmatter(_ text: String) throws -> [String: [String]] {
        var result: [String: [String]] = [:]
        let lines = text.components(separatedBy: "\n")
        guard let first = lines.first, first.trimmingCharacters(in: .whitespaces) == "---" else {
            throw NoteError.malformedMarkdown(reason: "missing opening frontmatter fence")
        }

        var currentKey: String?
        var closed = false

        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" {
                closed = true
                break
            }
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            if trimmed.hasPrefix("- "), let key = currentKey {
                result[key, default: []].append(unquote(String(trimmed.dropFirst(2))))
                continue
            }

            guard let separator = trimmed.firstIndex(of: ":") else { continue }
            let key = String(trimmed[trimmed.startIndex..<separator]).trimmingCharacters(in: .whitespaces)
            let raw = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespaces)

            if raw.isEmpty {
                // Either a block sequence follows, or the key is simply empty.
                currentKey = key
                result[key] = []
            } else if raw.hasPrefix("["), raw.hasSuffix("]") {
                result[key] = raw
                    .dropFirst()
                    .dropLast()
                    .split(separator: ",")
                    .map { unquote($0.trimmingCharacters(in: .whitespaces)) }
                    .filter { !$0.isEmpty }
                currentKey = nil
            } else {
                result[key] = [unquote(raw)]
                currentKey = nil
            }
        }

        guard closed else {
            throw NoteError.malformedMarkdown(reason: "unterminated frontmatter")
        }
        return result
    }

    // MARK: - Scalar helpers

    static func unquote(_ raw: String) -> String {
        let value = raw.trimmingCharacters(in: .whitespaces)
        guard value.count >= 2 else { return value }

        if value.hasPrefix("\""), value.hasSuffix("\"") {
            return String(value.dropFirst().dropLast())
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\n", with: "\n")
        }
        if value.hasPrefix("'"), value.hasSuffix("'") {
            return String(value.dropFirst().dropLast())
                .replacingOccurrences(of: "''", with: "'")
        }
        return value
    }

    static func quoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    static func singleQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "''"))'"
    }

    static func iso8601(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day().dateSeparator(.dash).time(includingFractionalSeconds: false).timeZone(separator: .omitted))
    }

    static func parseDate(_ raw: String) -> Date? {
        if let date = try? Date(raw, strategy: .iso8601) { return date }
        let withFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        if let date = try? Date(raw, strategy: withFraction) { return date }
        return nil
    }

    static func formatNumber(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    // MARK: - Transcript sidecar

    /// The transcript lives in frontmatter as compact JSON so it survives edits and
    /// stays out of the prose the user reads and rewrites.
    static func transcriptJSON(_ segments: [TranscriptSegment]) -> String {
        let payload = segments.map { segment -> [String: Any?] in
            var entry: [String: Any?] = ["text": segment.text, "start": segment.range.start, "end": segment.range.end]
            entry["confidence"] = segment.confidence
            return entry
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    static func decodeTranscriptJSON(_ raw: String) -> [TranscriptSegment]? {
        guard let data = raw.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }

        return array.compactMap { entry in
            guard let text = entry["text"] as? String,
                  let start = entry["start"] as? Double,
                  let end = entry["end"] as? Double else { return nil }
            return TranscriptSegment(
                text: text,
                range: TimeRange(start: start, end: end),
                confidence: entry["confidence"] as? Double
            )
        }
    }
}
