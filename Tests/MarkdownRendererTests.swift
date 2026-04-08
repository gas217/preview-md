import XCTest
import Markdown
import Yams

final class MarkdownRendererTests: XCTestCase {

    func testBasicMarkdown() {
        let input = "# Hello World\n\nThis is a paragraph."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<h1"))
        XCTAssertTrue(html.contains("Hello World"))
        XCTAssertTrue(html.contains("<p>This is a paragraph.</p>"))
    }

    func testFrontmatterParsing() {
        let input = """
        ---
        title: Test Document
        status: in progress
        priority: high
        tags:
          - swift
          - markdown
        ---

        # Content Here

        Some text.
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("Test Document"))
        XCTAssertTrue(html.contains("fm-title"))
        XCTAssertTrue(html.contains("in progress"))
        XCTAssertTrue(html.contains("badge-blue"))
        XCTAssertTrue(html.contains("badge-orange"))
        XCTAssertTrue(html.contains("swift"))
        XCTAssertTrue(html.contains("fm-tag"))
    }

    func testNoFrontmatter() {
        let input = "Just regular markdown\n\nWith paragraphs."
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("<div class=\"frontmatter\">"), "No frontmatter block when none present")
        XCTAssertTrue(html.contains("<p>Just regular markdown</p>"))
    }

    func testGFMTable() {
        let input = """
        | Name | Value |
        |------|-------|
        | foo  | bar   |
        | baz  | qux   |
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<th>"))
        XCTAssertTrue(html.contains("foo"))
        XCTAssertTrue(html.contains("bar"))
    }

    func testTaskList() {
        let input = """
        - [x] Done task
        - [ ] Pending task
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("task-list"))
        XCTAssertTrue(html.contains("checked"))
        XCTAssertTrue(html.contains("Done task"))
        XCTAssertTrue(html.contains("Pending task"))
    }

    func testCodeBlock() {
        let input = """
        ```swift
        let x = 42
        ```
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("language-swift"))
        XCTAssertTrue(html.contains("let x = 42"))
    }

    func testStrikethrough() {
        let input = "This is ~~deleted~~ text."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<del>"))
        XCTAssertTrue(html.contains("deleted"))
    }

    func testBlockquote() {
        let input = "> This is a quote"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("This is a quote"))
    }

    func testHTMLStructure() {
        let input = "# Test"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<html>"))
        XCTAssertTrue(html.contains("</html>"))
        XCTAssertTrue(html.contains("prefers-color-scheme"))
    }

    func testMalformedFrontmatter() {
        let input = """
        ---
        this is not: [valid yaml
        ---
        # Content
        """
        let html = MarkdownRenderer.render(input)
        // Should not crash, should render something
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
    }

    func testEmptyInput() {
        let html = MarkdownRenderer.render("")
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
    }

    func testHTMLEscaping() {
        let input = "This has <script>alert('xss')</script> in it"
        let html = MarkdownRenderer.render(input)
        // The raw <script> should be escaped
        XCTAssertFalse(html.contains("<script>alert"))
    }
}

final class FrontmatterParserTests: XCTestCase {

    func testParsesValidFrontmatter() {
        let input = """
        ---
        title: My Doc
        status: done
        ---
        Content here
        """
        let result = FrontmatterParser.parse(input)
        XCTAssertNotNil(result.frontmatter)
        XCTAssertEqual(result.frontmatter?.title, "My Doc")
        XCTAssertEqual(result.frontmatter?.status, "done")
        XCTAssertTrue(result.content.contains("Content here"))
    }

    func testNoFrontmatter() {
        let input = "Just content\nNo frontmatter"
        let result = FrontmatterParser.parse(input)
        XCTAssertNil(result.frontmatter)
        XCTAssertEqual(result.content, input)
    }

    func testEmptyFrontmatter() {
        let input = """
        ---
        ---
        Content
        """
        let result = FrontmatterParser.parse(input)
        XCTAssertNil(result.frontmatter)
    }

    func testFrontmatterWithTags() {
        let input = """
        ---
        tags:
          - one
          - two
          - three
        ---
        """
        let result = FrontmatterParser.parse(input)
        XCTAssertEqual(result.frontmatter?.tags, ["one", "two", "three"])
    }

    func testFrontmatterWithDates() {
        let input = """
        ---
        date: 2025-01-15
        ---
        """
        let result = FrontmatterParser.parse(input)
        XCTAssertNotNil(result.frontmatter)
        // Yams may parse dates as Date objects or strings depending on format
        XCTAssertNotNil(result.frontmatter?.date)
    }
}
