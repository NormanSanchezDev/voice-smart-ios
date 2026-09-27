import Foundation
import NoteSmartDomain

/// Turns a raw transcript into a titled, tagged, readable note without any model.
///
/// This is the floor of the feature, not a placeholder: it runs on every device, in
/// every locale, with no download and no waiting. The AI enricher is an upgrade on
/// top of this, never a prerequisite, so a note is always produced.
public struct RuleBasedNoteEnricher: NoteEnricher {
    public init() {}

    public var availability: AIAvailability { .available }

    public func enrich(
        transcript: String,
        suggestedTags: [VaultTag],
        locale: Locale
    ) async -> AsyncThrowingStream<EnrichmentProgress, Error> {
        AsyncThrowingStream { continuation in
            let enrichment = Self.enrich(
                transcript: transcript,
                suggestedTags: suggestedTags,
                locale: locale
            )
            // Emitted as two steps so the UI exercises the same progressive path it
            // uses for the model, and so a fast title can appear before the cleanup.
            continuation.yield(EnrichmentProgress(title: enrichment.title))
            continuation.yield(
                EnrichmentProgress(
                    summary: enrichment.summary,
                    tags: enrichment.tags,
                    actionItems: enrichment.actionItems,
                    cleanedMarkdown: enrichment.cleanedMarkdown,
                    isFinal: true
                )
            )
            continuation.finish()
        }
    }

    // MARK: - Heuristics

    public static func enrich(
        transcript: String,
        suggestedTags: [VaultTag],
        locale: Locale
    ) -> NoteEnrichment {
        let paragraphs = splitIntoParagraphs(transcript)
        let sentences = splitSentences(paragraphs.joined(separator: " "))

        return NoteEnrichment(
            title: makeTitle(from: sentences, transcript: transcript),
            summary: makeSummary(from: sentences),
            tags: mergedTags(from: transcript, suggested: suggestedTags),
            actionItems: actionItems(in: sentences),
            cleanedMarkdown: paragraphs.joined(separator: "\n\n")
        )
    }

    /// First sentence, trimmed to something that fits a list row.
    static func makeTitle(from sentences: [String], transcript: String) -> String {
        let candidate = sentences.first ?? transcript
        var cleaned = candidate
            .replacingOccurrences(
                of: #"^(hola|buenas|bueno|hey|ok|okay|well|so|a ver|pues)[,\s]+"#,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )

        // `splitSentences` keeps the terminator so a summary stitched from whole
        // sentences still reads as prose. A title is the opposite: it sits in a list
        // row next to other titles, and a row that ends in a full stop looks like a
        // truncated sentence rather than a label.
        while let last = cleaned.last, ".!?…".contains(last) {
            cleaned.removeLast()
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return "Nota sin título" }
        if cleaned.count <= 60 { return capitalised(cleaned) }

        // Cut on a word boundary so the title never ends mid-word.
        let truncated = cleaned.prefix(60)
        if let lastSpace = truncated.lastIndex(of: " ") {
            return capitalised(String(truncated[truncated.startIndex..<lastSpace])) + "…"
        }
        return capitalised(String(truncated)) + "…"
    }

    /// The first one or two sentences, which is what a glance at the note should show.
    static func makeSummary(from sentences: [String]) -> String {
        let picked = sentences.prefix(2).joined(separator: " ")
        guard picked.count > 160 else { return picked }
        return String(picked.prefix(157)) + "…"
    }

    /// Inline `#tags` the user actually said, plus whatever the caller suggested.
    static func mergedTags(from transcript: String, suggested: [VaultTag]) -> [VaultTag] {
        let inline = MarkdownEditing.inlineTags(in: transcript)
        var seen: Set<String> = []
        var result: [VaultTag] = []

        for tag in inline + suggested where seen.insert(tag.name).inserted {
            result.append(tag)
        }
        return Array(result.prefix(6)).sorted()
    }

    /// Sentences that read as a commitment. Deliberately conservative: a wrong
    /// action item is worse than a missing one.
    static func actionItems(in sentences: [String]) -> [String] {
        let cues = [
            "tengo que", "hay que", "debo", "necesito", "vamos a", "voy a", "va a",
            "remember to", "need to", "have to", "must ", "should ", "todo", "pendiente"
        ]

        return sentences
            .filter { sentence in
                let lower = sentence.lowercased()
                return cues.contains { lower.contains($0) }
            }
            .map { sentence in
                var text = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if text.hasSuffix(".") { text.removeLast() }
                return text
            }
            .prefix(6)
            .map { $0 }
    }

    /// Groups the transcript into paragraphs on pauses. Speech arrives with
    /// newlines or runs of spaces where the speaker stopped; ordinary sentence
    /// spacing is prose, so it must not be shredded into one-sentence paragraphs.
    static func splitIntoParagraphs(_ transcript: String) -> [String] {
        let normalized = transcript.replacingOccurrences(
            of: #"\s{2,}"#,
            with: "\n\n",
            options: .regularExpression
        )

        return normalized
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Splits on sentence terminators and newlines, keeping the terminator so a
    /// summary stitched from the first sentences still reads as prose.
    static func splitSentences(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""

        func flush() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(trimmed) }
            current = ""
        }

        for character in text {
            if ".!?".contains(character) {
                current.append(character)
                flush()
            } else if character.isNewline {
                flush()
            } else {
                current.append(character)
            }
        }
        flush()
        return result
    }

    private static func capitalised(_ text: String) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased() + text.dropFirst()
    }
}
