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

    @Test("Lists tasks with the index toggleTask expects")
    func listTasks() {
        let body = """
        # Shopping

        - [ ] milk
        * [x] bread
          - [ ] not a task at the wrong depth is still a task
        prose with array[0] = 1
        """
        let tasks = MarkdownEditing.tasks(in: body)

        #expect(tasks.map(\.index) == [0, 1, 2])
        #expect(tasks.map(\.isChecked) == [false, true, false])
        #expect(tasks.map(\.text) == ["milk", "bread", "not a task at the wrong depth is still a task"])
        #expect(tasks.map(\.line) == [2, 3, 4])
    }

    @Test("Every listed task toggles back at its own index")
    func listTasksRoundTrips() throws {
        let body = "- [ ] a\n- [x] b\n- [ ] c"
        let tasks = MarkdownEditing.tasks(in: body)

        for task in tasks {
            let toggled = try MarkdownEditing.toggleTask(in: body, at: task.index)
            #expect(MarkdownEditing.tasks(in: toggled)[task.index].isChecked != task.isChecked)
        }
    }

    @Test("Finds no tasks in prose")
    func listTasksEmpty() {
        #expect(MarkdownEditing.tasks(in: "just prose") == [])
        #expect(MarkdownEditing.tasks(in: "") == [])
        #expect(MarkdownEditing.tasks(in: "array[0] = 1") == [])
    }

    @Test("Counts a fenced task, because toggleTask would too")
    func listTasksIgnoresFences() throws {
        // Fence awareness would be nicer, but `tasks(in:)` has to agree with
        // `toggleTask(in:at:)` on what a task is. If only one of them looked inside
        // code fences, the indices would drift and the UI would tick the wrong line.
        let body = "```\n- [ ] fenced\n```"
        #expect(MarkdownEditing.tasks(in: body).map(\.index) == [0])
        #expect(try MarkdownEditing.toggleTask(in: body, at: 0) == "```\n- [x] fenced\n```")
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
