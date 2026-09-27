import Foundation

/// Enriches a transcript, falling back to heuristics when the on-device model is
/// unavailable. The fallback is a first-class outcome here, not an error: an app
/// that only works on Apple-Intelligence hardware is broken for everyone else.
public struct EnrichTranscript: Sendable {
    private let enricher: any NoteEnricher
    private let fallback: any NoteEnricher

    public init(enricher: any NoteEnricher, fallback: any NoteEnricher) {
        self.enricher = enricher
        self.fallback = fallback
    }

    public func callAsFunction(
        _ transcript: String,
        suggestedTags: [VaultTag] = [],
        locale: Locale = .current
    ) async -> AsyncThrowingStream<EnrichmentProgress, Error> {
        let availability = await enricher.availability
        let chosen: any NoteEnricher
        switch availability {
        case .available: chosen = enricher
        case .unavailable: chosen = fallback
        }

        let stream = await chosen.enrich(
            transcript: transcript,
            suggestedTags: suggestedTags,
            locale: locale
        )
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Consume to the end of the stream rather than stopping at
                    // `isFinal`: a producer may mark an element final and still
                    // send later fields, and stopping early silently drops them.
                    for try await progress in stream {
                        continuation.yield(progress)
                    }
                    continuation.finish()
                } catch {
                    // AI failed mid-flight. The heuristic result is still worth
                    // showing, so degrade instead of surfacing an error.
                    do {
                        for try await progress in await fallback.enrich(
                            transcript: transcript,
                            suggestedTags: suggestedTags,
                            locale: locale
                        ) {
                            continuation.yield(progress)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Blocking convenience that also reports which path produced the result.
    public func enrichment(
        for transcript: String,
        suggestedTags: [VaultTag] = [],
        locale: Locale = .current
    ) async throws -> (enrichment: NoteEnrichment, source: EnrichmentSource) {
        let availability = await enricher.availability
        let source: EnrichmentSource = availability.isAvailable ? .onDeviceAI : .ruleBasedFallback

        var latest = NoteEnrichment.empty()
        for try await progress in await callAsFunction(transcript, suggestedTags: suggestedTags, locale: locale) {
            latest = progress.applied(to: latest)
        }
        return (latest, source)
    }
}
