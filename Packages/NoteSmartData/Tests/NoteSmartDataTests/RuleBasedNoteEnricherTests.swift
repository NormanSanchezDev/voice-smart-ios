import Foundation
import NoteSmartDomain
import Testing

@testable import NoteSmartData

@Suite("Rule-based enricher")
struct RuleBasedNoteEnricherTests {
    private let enricher = RuleBasedNoteEnricher()

    private func collect(
        _ transcript: String,
        suggested: [VaultTag] = []
    ) async throws -> [EnrichmentProgress] {
        var steps: [EnrichmentProgress] = []
        for try await step in await enricher.enrich(
            transcript: transcript,
            suggestedTags: suggested,
            locale: Locale(identifier: "es_MX")
        ) {
            steps.append(step)
        }
        return steps
    }

    @Test("The title comes from the first sentence, with filler removed")
    func title() async throws {
        let steps = try await collect("Bueno, hay que revisar el presupuesto. Luego vemos el resto.")
        #expect(steps.first?.title == "Hay que revisar el presupuesto")
    }

    @Test("A long first sentence is cut on a word boundary and marked as truncated")
    func longTitle() async throws {
        let sentence = (1..<40).map { "palabra\($0)" }.joined(separator: " ") + "."
        let steps = try await collect(sentence)
        let title = try #require(steps.first?.title)

        #expect(title.count <= 61)
        #expect(title.hasSuffix("…"))
        #expect(title.contains(" "))
        #expect(!title.hasSuffix(" … "))
    }

    @Test("A transcript with no usable text still yields a note")
    func emptyTranscript() async throws {
        let steps = try await collect("   \n  \n ")

        #expect(steps.count == 2)
        #expect(steps.last?.isFinal == true)
        #expect(steps.last?.title == nil)
    }

    @Test("Silence in the middle of a note becomes a paragraph break")
    func paragraphs() async throws {
        let steps = try await collect("Primera idea.\n\nSegunda idea.\n\nTercera idea.")
        let body = try #require(steps.last?.cleanedMarkdown)

        #expect(body == "Primera idea.\n\nSegunda idea.\n\nTercera idea.")
    }

    @Test("Plain sentence spacing stays one paragraph")
    func sentencesAreNotParagraphs() async throws {
        let steps = try await collect("Primera idea. Segunda idea. Tercera idea.")
        let body = try #require(steps.last?.cleanedMarkdown)

        #expect(body == "Primera idea. Segunda idea. Tercera idea.")
    }

    @Test("A summary covers at most the first two sentences")
    func summary() async throws {
        let steps = try await collect("Uno. Dos. Tres. Cuatro.")
        let summary = try #require(steps.last?.summary)

        #expect(summary == "Uno. Dos.")
    }

    @Test("Inline tags the speaker said are picked up, without the # or trailing punctuation")
    func inlineTags() async throws {
        let steps = try await collect("Sobre #presupuesto y #finanzas del año.")
        let tags = try #require(steps.last?.tags)

        #expect(tags.map(\.name) == ["finanzas", "presupuesto"])
    }

    @Test("Suggested tags are merged in and duplicates are dropped")
    func mergedTags() async throws {
        let steps = try await collect(
            "Nada importante.",
            suggested: [VaultTag("salud")!, VaultTag("finanzas")!]
        )
        let tags = try #require(steps.last?.tags)

        #expect(tags.map(\.name) == ["finanzas", "salud"])
    }

    @Test("Action items are found from commitment cues and lose their full stop")
    func actionItems() async throws {
        let steps = try await collect(
            "Hay que llamar al banco. Luego voy al gym. Nada más por hoy."
        )
        let items = try #require(steps.last?.actionItems)

        #expect(items == ["Hay que llamar al banco", "Luego voy al gym"])
    }

    @Test("A note with no commitments gets an empty action list, not a guess")
    func noActionItems() async throws {
        let steps = try await collect("Mañana llueve mucho en Guadalajara.")

        #expect(try #require(steps.last?.actionItems).isEmpty)
    }

    @Test("English cues are recognised too")
    func englishActionItems() async throws {
        let steps = try await collect("I need to email the landlord. I have to renew the lease.")
        let items = try #require(steps.last?.actionItems)

        #expect(items.count == 2)
        #expect(items[0] == "I need to email the landlord")
    }

    @Test("Progress is emitted more than once and the last step is final")
    func progressiveSteps() async throws {
        let steps = try await collect("Una nota cualquiera.")

        #expect(steps.count == 2)
        #expect(steps.first?.title != nil)
        #expect(steps.last?.isFinal == true)
    }

    @Test("The rule-based enricher is always available; it is the floor, not a fallback of last resort")
    func alwaysAvailable() async {
        #expect(await enricher.availability == .available)
    }

    @Test("Heuristics are pure, so the same transcript always gives the same note")
    func deterministic() {
        let transcript = "Comprar pan. Pagar el recibo. #casa"
        let first = RuleBasedNoteEnricher.enrich(
            transcript: transcript,
            suggestedTags: [],
            locale: Locale(identifier: "es_MX")
        )
        let second = RuleBasedNoteEnricher.enrich(
            transcript: transcript,
            suggestedTags: [],
            locale: Locale(identifier: "es_MX")
        )

        #expect(first.title == second.title)
        #expect(first.summary == second.summary)
        #expect(first.tags == second.tags)
        #expect(first.actionItems == second.actionItems)
        #expect(first.cleanedMarkdown == second.cleanedMarkdown)
    }
}
