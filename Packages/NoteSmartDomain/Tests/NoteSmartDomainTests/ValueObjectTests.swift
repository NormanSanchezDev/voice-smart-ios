import Foundation
import Testing
@testable import NoteSmartDomain

@Suite("Value objects")
struct ValueObjectTests {

    @Test("VaultPath normalises and describes itself")
    func vaultPath() {
        #expect(VaultPath().isRoot)
        #expect(VaultPath().description == "/")
        #expect(VaultPath(components: ["Work", " ", "Ideas"]).components == ["Work", "Ideas"])
        #expect(VaultPath(components: ["a", "..", "b"]).components == ["a", "b"])
        #expect(VaultPath(components: ["Work"]).appending("Ideas").description == "Work/Ideas")
        #expect(VaultPath(components: ["Work", "Ideas"]).deletingLastComponent().description == "Work")
    }

    @Test("VaultPath ancestry")
    func vaultPathAncestry() {
        let work = VaultPath(components: ["Work"])
        let child = VaultPath(components: ["Work", "Ideas", "Q3"])
        #expect(child.isDescendant(of: work))
        #expect(child.isDescendant(of: VaultPath()))
        #expect(!work.isDescendant(of: child))
    }

    @Test("VaultPath builds a nested URL")
    func vaultPathURL() {
        let root = URL(fileURLWithPath: "/tmp/vault", isDirectory: true)
        let url = VaultPath(components: ["Work", "Ideas"]).url(relativeTo: root)
        #expect(url.path == "/tmp/vault/Work/Ideas")
    }

    @Test("TimeRange orders its bounds and computes geometry")
    func timeRange() {
        let range = TimeRange(start: 12, end: 4)
        #expect(range.start == 4)
        #expect(range.end == 12)
        #expect(range.duration == 8)

        let a = TimeRange(start: 0, end: 10)
        let b = TimeRange(start: 5, end: 15)
        #expect(a.overlaps(b))
        #expect(a.union(b) == TimeRange(start: 0, end: 15))
        #expect(a.intersection(b) == TimeRange(start: 5, end: 10))
        #expect(a.contains(0))
        #expect(!a.contains(10), "half-open range excludes the end")
        #expect(a.intersection(TimeRange(start: 20, end: 30)) == nil)
    }

    @Test("TimeRange formats as a timestamp")
    func timeRangeText() {
        #expect(TimeRange(start: 0, end: 1).timestampText() == "0:00")
        #expect(TimeRange(start: 65, end: 70).timestampText() == "1:05")
        #expect(TimeRange(start: 3725, end: 3730).timestampText() == "1:02:05")
    }

    @Test("VaultTag normalises like Obsidian and rejects junk")
    func tags() {
        #expect(VaultTag("#Ideas")?.name == "ideas")
        #expect(VaultTag("Work In Progress")?.name == "work-in-progress")
        #expect(VaultTag("deep/nested/tag")?.name == "deep/nested/tag")
        #expect(VaultTag("snake_case")?.name == "snake_case")
        #expect(VaultTag("#") == nil)
        #expect(VaultTag("   ") == nil)
        #expect(VaultTag("has space!") == nil, "punctuation is not a valid tag")
        #expect(VaultTag("#Ideas")?.displayText == "#ideas")
    }

    @Test("Tags sort alphabetically")
    func tagOrdering() {
        let tags = [VaultTag("zeta")!, VaultTag("alpha")!, VaultTag("mid")!]
        #expect(tags.sorted() == [VaultTag("alpha")!, VaultTag("mid")!, VaultTag("zeta")!])
    }
}
