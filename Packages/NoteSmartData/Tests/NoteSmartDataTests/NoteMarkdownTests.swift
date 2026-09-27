import Foundation
import NoteSmartDomain
import Testing

@testable import NoteSmartData

@Suite("Note markdown")
struct NoteMarkdownTests {
    private func makeNote(
        title: String = "Weekly review",
        tags: [String] = ["work", "weekly/review"],
        body: String = "Shipped the recorder.\n\nStill need to fix search.",
        audio: AudioRef? = nil,
        transcript: [TranscriptSegment] = []
    ) -> Note {
        Note(
            folder: VaultPath(),
            fileName: "weekly-review.md",
            frontmatter: NoteFrontmatter(
                title: title,
                created: Date(timeIntervalSince1970: 1_700_000_000),
                modified: Date(timeIntervalSince1970: 1_700_000_500),
                tags: tags.compactMap(VaultTag.init),
                audio: audio,
                source: .voice,
                enriched: true
            ),
            body: body,
            transcript: transcript
        )
    }

    @Test("A note round-trips through the file format")
    func roundTrip() throws {
        let original = makeNote(
            audio: AudioRef(fileName: "2026-09-26.m4a", duration: 42.5),
            transcript: [TranscriptSegment(text: "hello there", range: TimeRange(start: 0, end: 1.2))]
        )

        let text = NoteMarkdown.encode(original)
        let decoded = try NoteMarkdown.decode(text, fileName: original.fileName, folder: original.folder)

        #expect(decoded.id == original.id)
        #expect(decoded.title == original.title)
        #expect(decoded.tags == original.tags)
        #expect(decoded.body == original.body)
        #expect(decoded.frontmatter.created == original.frontmatter.created)
        #expect(decoded.frontmatter.modified == original.frontmatter.modified)
        #expect(decoded.frontmatter.source == .voice)
        #expect(decoded.frontmatter.enriched)
        #expect(decoded.frontmatter.audio?.fileName == "2026-09-26.m4a")
        #expect(decoded.frontmatter.audio?.duration == 42.5)
        #expect(decoded.transcript.count == 1)
        #expect(decoded.transcript.first?.text == "hello there")
        #expect(decoded.transcript.first?.range == TimeRange(start: 0, end: 1.2))
    }

    @Test("Identity survives the round trip so a note keeps its id across launches")
    func identityPersists() throws {
        let original = makeNote()
        let decoded = try NoteMarkdown.decode(
            NoteMarkdown.encode(original),
            fileName: original.fileName,
            folder: original.folder
        )
        #expect(decoded.id == original.id)
    }

    @Test("Titles with quotes and newlines survive quoting")
    func awkwardTitle() throws {
        let original = makeNote(title: "He said \"hi\"\nthen left")
        let decoded = try NoteMarkdown.decode(
            NoteMarkdown.encode(original),
            fileName: "x.md",
            folder: VaultPath()
        )
        #expect(decoded.title == "He said \"hi\"\nthen left")
    }

    @Test("A body containing wikilinks and code fences is preserved verbatim")
    func bodyWithMarkup() throws {
        let body = """
        See [[Search design]] for context.

        ```swift
        let x = 1
        ```

        # Heading
        """
        let original = makeNote(body: body)
        let decoded = try NoteMarkdown.decode(
            NoteMarkdown.encode(original),
            fileName: "x.md",
            folder: VaultPath()
        )
        #expect(decoded.body == body)
    }

    @Test("Frontmatter written by another tool parses")
    func foreignFrontmatter() throws {
        let text = """
        ---
        title: Hand written
        created: 2026-01-02T03:04:05Z
        tags:
          - alpha
          - beta
        enriched: false
        ---

        Body text here.
        """
        let note = try NoteMarkdown.decode(text, fileName: "hand.md", folder: VaultPath())
        #expect(note.title == "Hand written")
        #expect(note.tags.map(\.name) == ["alpha", "beta"])
        #expect(note.frontmatter.source == .manual)
        #expect(note.body == "Body text here.")
    }

    @Test("A file without frontmatter is rejected rather than silently emptied")
    func missingFrontmatter() {
        #expect(throws: NoteError.self) {
            try NoteMarkdown.decode("Just prose, no metadata.", fileName: "x.md", folder: VaultPath())
        }
    }

    @Test("An unterminated frontmatter block is rejected")
    func unterminatedFrontmatter() {
        #expect(throws: NoteError.self) {
            try NoteMarkdown.decode("---\ntitle: Broken\n", fileName: "x.md", folder: VaultPath())
        }
    }

    @Test("An empty tag list survives")
    func noTags() throws {
        let original = makeNote(tags: [])
        let decoded = try NoteMarkdown.decode(
            NoteMarkdown.encode(original),
            fileName: "x.md",
            folder: VaultPath()
        )
        #expect(decoded.tags.isEmpty)
    }
}
