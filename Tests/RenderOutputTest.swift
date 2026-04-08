import XCTest

final class RenderOutputTest: XCTestCase {
    func testRenderExampleToFile() throws {
        let examplePath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/example.md")

        let content = try String(contentsOf: examplePath, encoding: .utf8)
        let html = MarkdownRenderer.render(content)

        let outputPath = URL(fileURLWithPath: "/tmp/previewmd_test_output.html")
        try html.write(to: outputPath, atomically: true, encoding: .utf8)

        // Verify key features are present in the rendered output
        XCTAssertTrue(html.contains("Weekly Status Report"), "Title should be rendered")
        XCTAssertTrue(html.contains("fm-title"), "Frontmatter title class present")
        XCTAssertTrue(html.contains("badge-blue"), "Status badge class present")
        XCTAssertTrue(html.contains("badge-orange"), "Priority badge class present")
        XCTAssertTrue(html.contains("fm-tag"), "Tags rendered")
        XCTAssertTrue(html.contains("engineering"), "Tag value present")
        XCTAssertTrue(html.contains("<table>"), "Table rendered")
        XCTAssertTrue(html.contains("task-list"), "Task list rendered")
        XCTAssertTrue(html.contains("language-swift"), "Code block with language")
        XCTAssertTrue(html.contains("<blockquote>"), "Blockquote rendered")
        XCTAssertTrue(html.contains("<em>"), "Emphasis rendered")
        XCTAssertTrue(html.contains("<hr>"), "Horizontal rule rendered")
        XCTAssertTrue(html.contains("prefers-color-scheme"), "Dark mode support in CSS")
        XCTAssertTrue(html.contains("<a href="), "Links rendered")

        print("HTML output written to: /tmp/previewmd_test_output.html")
        print("HTML size: \(html.count) characters")
    }

    func testRenderFrontmatterTaskToFile() throws {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/frontmatter_task.md")

        let content = try String(contentsOf: path, encoding: .utf8)
        let html = MarkdownRenderer.render(content)
        let outputPath = URL(fileURLWithPath: "/tmp/previewmd_reeve_output.html")
        try html.write(to: outputPath, atomically: true, encoding: .utf8)
        print("Frontmatter task HTML output written to: /tmp/previewmd_reeve_output.html")
    }
}
