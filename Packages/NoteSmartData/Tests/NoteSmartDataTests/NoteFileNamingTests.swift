import Foundation
import Testing

@testable import NoteSmartData

@Suite("Note file naming")
struct NoteFileNamingTests {
    @Test("Slugs fold diacritics and punctuation into hyphens")
    func slug() {
        #expect(NoteFileNaming.slug(for: "Crème brûlée & notes!") == "creme-brulee-notes")
        #expect(NoteFileNaming.slug(for: "Weekly Review 2026-09-26") == "weekly-review-2026-09-26")
        #expect(NoteFileNaming.slug(for: "  leading and trailing  ") == "leading-and-trailing")
    }

    @Test("Slugs collapse repeated separators")
    func repeatedSeparators() {
        #expect(NoteFileNaming.slug(for: "a -- b __ c") == "a-b-c")
    }

    @Test("Titles with nothing usable fall back instead of producing an empty name")
    func fallback() {
        #expect(NoteFileNaming.slug(for: "!!!") == "untitled")
        #expect(NoteFileNaming.slug(for: "") == "untitled")
        #expect(NoteFileNaming.fileName(for: "¿Qué?") == "que.md")
    }

    @Test("Long titles are cut on a word boundary")
    func longTitle() {
        let title = String(repeating: "palabra ", count: 30)
        let slug = NoteFileNaming.slug(for: title)
        #expect(slug.count <= NoteFileNaming.maxLength)
        #expect(!slug.hasSuffix("-"))
    }

    @Test("Collisions get a numeric suffix before the extension")
    func uniqueName() {
        let taken: Set<String> = ["idea.md", "idea 2.md"]
        #expect(NoteFileNaming.uniqueFileName(base: "idea.md", isTaken: taken.contains) == "idea 3.md")
        #expect(NoteFileNaming.uniqueFileName(base: "fresh.md", isTaken: taken.contains) == "fresh.md")
    }

    @Test("A title that already ends in a number is not mistaken for a suffix")
    func numericSuffixLookalike() {
        let taken: Set<String> = ["note.md"]
        #expect(NoteFileNaming.uniqueFileName(base: "note.md", isTaken: taken.contains) == "note 2.md")
    }
}
