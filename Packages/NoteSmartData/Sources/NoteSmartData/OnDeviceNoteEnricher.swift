import Foundation
import FoundationModels
import NoteSmartDomain

/// The structured shape the on-device model is asked to fill.
@Generable(description: "A voice note turned into a titled, tagged, readable note.")
struct NoteEnrichmentDraft: Sendable {
    @Guide(description: "A short title, at most 8 words, no trailing period.")
    var title: String

    @Guide(description: "One or two sentences summarising the note.")
    var summary: String

    @Guide(description: "Up to 5 lowercase topic tags, without the # character.")
    var tags: [String]

    @Guide(description: "Concrete commitments the speaker stated. Empty when there are none.")
    var actionItems: [String]

    @Guide(description: "The transcript as clean markdown: filler words removed, paragraphs split, no preamble.")
    var cleanedMarkdown: String
}

/// Enriches a transcript with the on-device foundation model.
///
/// The model proposes; it never gates. If the device is ineligible, Apple
/// Intelligence is off, the model is still warming up, or generation trips a
/// guardrail, the caller falls back to `RuleBasedNoteEnricher`. That fallback lives
/// in the domain's `EnrichTranscript` use case, so this type can fail loudly.
public actor OnDeviceNoteEnricher: NoteEnricher {
    public init() {}

    public var availability: AIAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            .available
        case .unavailable(.deviceNotEligible):
            .unavailable(.deviceNotEligible)
        case .unavailable(.appleIntelligenceNotEnabled):
            .unavailable(.regionNotSupported)
        case .unavailable(.modelNotReady):
            .unavailable(.modelNotReady)
        @unknown default:
            .unavailable(.unknown("unrecognised availability"))
        }
    }

    public func enrich(
        transcript: String,
        suggestedTags: [VaultTag],
        locale: Locale
    ) async -> AsyncThrowingStream<EnrichmentProgress, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard case .available = availability else {
                        throw EnrichmentError.modelUnavailable(Self.reason(for: availability))
                    }

                    let session = LanguageModelSession(
                        instructions: Self.instructions(suggestedTags: suggestedTags, locale: locale)
                    )

                    var latest: NoteEnrichmentDraft.PartiallyGenerated?
                    let stream = session.streamResponse(generating: NoteEnrichmentDraft.self) {
                        Prompt(
                            """
                            Organise this voice-note transcript.

                            Transcript:
                            \(transcript)
                            """
                        )
                    }

                    for try await snapshot in stream {
                        latest = snapshot.content
                        continuation.yield(Self.progress(from: snapshot.content))
                    }

                    // The last snapshot is the complete draft; a missing body means the
                    // model stopped early, which is a failure worth surfacing so the
                    // caller falls back rather than storing a half note.
                    guard let cleaned = latest?.cleanedMarkdown, !cleaned.isEmpty else {
                        throw EnrichmentError.modelUnavailable(.modelNotReady)
                    }

                    continuation.yield(
                        EnrichmentProgress(
                            title: latest?.title,
                            summary: latest?.summary,
                            tags: latest?.tags?.compactMap(VaultTag.init),
                            actionItems: latest?.actionItems,
                            cleanedMarkdown: cleaned,
                            isFinal: true
                        )
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Prompting

    nonisolated static func instructions(suggestedTags: [VaultTag], locale: Locale) -> String {
        let tagHint = suggestedTags.isEmpty
            ? "No tags were suggested."
            : "The note belongs near these existing vault tags: \(suggestedTags.map(\.name).joined(separator: ", ")). Reuse them when they fit."

        return """
        You turn raw speech-to-text output from a voice notes app into a clean, \
        titled, tagged markdown note.

        Rules:
        - Remove filler and disfluencies: um, uh, like, you know, repeats, false starts.
        - Never invent content. If the transcript does not say it, it is not in the note.
        - Keep the speaker's own language. The transcript is in \(locale.identifier).
        - Split long stretches of speech into paragraphs.
        - `actionItems` holds only commitments the speaker explicitly made. An empty \
        list is correct and expected for most notes.
        - `tags` are lowercase, without `#`, at most 5, and reuse existing vault tags \
        when they apply.
        - The title is at most 8 words with no trailing period.

        \(tagHint)
        """
    }

    /// Projects a partial draft onto the progress shape, omitting anything the model
    /// has not produced yet.
    nonisolated static func progress(from partial: NoteEnrichmentDraft.PartiallyGenerated) -> EnrichmentProgress {
        EnrichmentProgress(
            title: partial.title,
            summary: partial.summary,
            tags: partial.tags?.compactMap(VaultTag.init),
            actionItems: partial.actionItems,
            cleanedMarkdown: partial.cleanedMarkdown
        )
    }

    private nonisolated static func reason(for availability: AIAvailability) -> AIUnavailableReason {
        switch availability {
        case .available: .modelNotReady
        case .unavailable(let reason): reason
        }
    }
}
