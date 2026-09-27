import Foundation
import Testing
@testable import NoteSmartDomain

@Suite("Markdown editing")
struct MarkdownEditingTests {

    @Test("Toggles a task checkbox in place")
    func toggleTask() throws {
        let body = """
        # Shopping

        - [ ] milk
        - [x] bread
        - [ ] eggs
        """
        let result = try MarkdownEditing.toggleTask(in: body, at: 0)
        #expect(result.contains("- [x] milk"))
        #expect(result.contains("- [x] bread"), "other tasks are untouched")

        let untoggled = try MarkdownEditing.toggleTask(in: result, at: 0)
        #expect(untoggled.contains("- [ ] milk"))
    }

    @Test("Toggles only the requested task")
    func toggleTaskByIndex() throws {
        let body = "- [ ] a\n- [ ] b\n- [ ] c"
        let result = try MarkdownEditing.toggleTask(in: body, at: 1)
        #expect(result == "- [ ] a\n- [x] b\n- [ ] c")
    }

    @Test("Accepts * and + as task bullets")
    func toggleTaskBulletStyles() throws {
        #expect(try MarkdownEditing.toggleTask(in: "* [ ] a", at: 0) == "* [x] a")
        #expect(try MarkdownEditing.toggleTask(in: "+ [ ] a", at: 0) == "+ [x] a")
        #expect(try MarkdownEditing.toggleTask(in: "   - [ ] a", at: 0) == "   - [x] a")
    }

    @Test("Fails when there is no task at that index")
    func toggleTaskMissing() {
        #expect(throws: NoteError.self) {
            try MarkdownEditing.toggleTask(in: "just prose", at: 0)
        }
        #expect(throws: NoteError.self) {
            try MarkdownEditing.toggleTask(in: "- [ ] a", at: 7)
        }
    }

    @Test("Does not toggle a line that merely contains brackets")
    func toggleTaskNotAList() {
        #expect(throws: NoteError.self) {
            try MarkdownEditing.toggleTask(in: "array[0] = 1", at: 0)
        }
    }

    @Test("Extracts wikilinks including aliases")
    func wikilinks() {
        let body = """
        See [[Project Apollo]] and [[Roadmap|the plan]].
        Nested [[Work/Ideas/Shipping]].
        No link here.
        """
        #expect(
            MarkdownEditing.wikilinks(in: body) == ["Project Apollo", "Roadmap", "Work/Ideas/Shipping"]
        )
    }

    @Test("Ignores empty wikilinks")
    func emptyWikilinks() {
        #expect(MarkdownEditing.wikilinks(in: "[[]] and [[   ]]").isEmpty)
    }

    @Test("Extracts inline tags but not inside code fences")
    func inlineTags() {
        let body = """
        Tagged #idea and #work/active today.
        ```swift
        let color = "#notATag"
        ```
        Back to prose #idea.
        """
        let tags = MarkdownEditing.inlineTags(in: body)
        #expect(tags == [VaultTag("idea")!, VaultTag("work/active")!, VaultTag("idea")!])
    }
}
