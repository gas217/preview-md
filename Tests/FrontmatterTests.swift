import XCTest

final class FrontmatterRenderTests: XCTestCase {

    func testFrontmatterTaskFile() throws {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/frontmatter_task.md")

        let content = try String(contentsOf: path, encoding: .utf8)
        let html = MarkdownRenderer.render(content)

        // Frontmatter: title as prominent header
        XCTAssertTrue(html.contains("fm-title"), "Title rendered as frontmatter title")
        XCTAssertTrue(html.contains("Implement markdown Quick Look extension"))

        // Frontmatter: status badge
        XCTAssertTrue(html.contains("badge-blue"), "Status 'in progress' gets blue badge")

        // Frontmatter: priority badge
        XCTAssertTrue(html.contains("badge-orange"), "Priority 'high' gets orange badge")

        // Frontmatter: date
        XCTAssertTrue(html.contains("2025"), "Date rendered")

        // Frontmatter: tags
        XCTAssertTrue(html.contains("fm-tag"), "Tags rendered as pills")
        XCTAssertTrue(html.contains("engineering"))
        XCTAssertTrue(html.contains("macos"))
        XCTAssertTrue(html.contains("quick-look"))

        // Frontmatter: custom fields (id, parent, assignee, prompt)
        XCTAssertTrue(html.contains("fm-fields"), "Custom fields rendered")
        XCTAssertTrue(html.contains("task-2025-0142"), "ID field present")
        XCTAssertTrue(html.contains("project-preview-md"), "Parent field present")

        // Content: task list with mixed states
        XCTAssertTrue(html.contains("task-list"), "Task list rendered")
        XCTAssertTrue(html.contains("task-list-item done"), "Completed items styled")

        // Content: table with alignment
        XCTAssertTrue(html.contains("<table>"), "Table rendered")
        XCTAssertTrue(html.contains("text-align:left"), "Left alignment")
        XCTAssertTrue(html.contains("text-align:center"), "Center alignment")
        XCTAssertTrue(html.contains("text-align:right"), "Right alignment")

        // Content: code block
        XCTAssertTrue(html.contains("language-swift"), "Swift code block")

        // Content: blockquote
        XCTAssertTrue(html.contains("<blockquote>"), "Blockquote rendered")

        // Verify no frontmatter delimiters leak into content
        XCTAssertFalse(html.contains("<p>---</p>"), "No raw frontmatter delimiters in content")
    }

    func testFrontmatterMinimalTask() {
        let input = """
        ---
        id: t-001
        title: Quick task
        status: todo
        ---
        Just a note.
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("Quick task"))
        XCTAssertTrue(html.contains("badge-gray"), "Todo status gets gray badge")
        XCTAssertTrue(html.contains("t-001"))
    }

    func testFrontmatterCompletedTask() {
        let input = """
        ---
        title: Done task
        status: done
        priority: low
        ---
        All finished.
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("badge-green"), "Done status gets green badge")
        XCTAssertTrue(html.contains("badge-gray"), "Low priority gets gray badge")
    }

    func testMultipleDateFields() {
        let input = """
        ---
        title: Multi-date task
        created: 2025-01-10
        modified: 2025-01-15
        due: 2025-02-01
        ---
        Content
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("created:"), "Created date label shown")
        XCTAssertTrue(html.contains("modified:"), "Modified date label shown")
        XCTAssertTrue(html.contains("due:"), "Due date label shown")
        // Dates should NOT appear in the custom fields section
        XCTAssertFalse(html.contains("<dt>created</dt>"), "Created not in custom fields")
    }

    func testFrontmatterBlockedTask() {
        let input = """
        ---
        title: Blocked task
        status: blocked
        priority: critical
        ---
        Waiting on dependency.
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("badge-red"), "Blocked status and critical priority get red badges")
    }
}
