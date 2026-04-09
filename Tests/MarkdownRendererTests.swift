import XCTest

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
        XCTAssertFalse(html.contains("<script>alert"))
    }

    func testAngleBracketAutolinks() {
        let input = "Visit <https://example.com> for more info."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<a href="), "Angle bracket autolink renders as link")
        XCTAssertTrue(html.contains("example.com"))
    }

    func testBareURLsPreserved() {
        let input = "Visit https://example.com for more info."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("https://example.com"), "Bare URL text preserved for JS auto-linking")
        XCTAssertTrue(html.contains("urlRegex"), "Autolink JS is embedded")
    }

    func testNestedFormatting() {
        let input = "This is ***bold and italic*** text."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<strong>"))
        XCTAssertTrue(html.contains("<em>"))
    }

    func testOrderedList() {
        let input = "1. First\n2. Second\n3. Third"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("First"))
    }

    func testTableAlignment() {
        let input = "| Left | Center | Right |\n|:-----|:------:|------:|\n| a | b | c |"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("text-align:left"))
        XCTAssertTrue(html.contains("text-align:center"))
        XCTAssertTrue(html.contains("text-align:right"))
    }

    func testImageRendering() {
        let input = "![Alt text](image.png \"Title\")"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<img"))
        XCTAssertTrue(html.contains("alt=\"Alt text\""))
        XCTAssertTrue(html.contains("title=\"Title\""))
    }

    func testImagePaths() {
        let relative = MarkdownRenderer.render("![Screenshot](./assets/screenshot.png)")
        XCTAssertTrue(relative.contains("src=\"./assets/screenshot.png\""))

        let absolute = MarkdownRenderer.render("![Photo](file:///Users/test/photo.jpg)")
        XCTAssertTrue(absolute.contains("src=\"file:///Users/test/photo.jpg\""))
    }

    func testCSPAllowsLocalImages() {
        let html = MarkdownRenderer.render("# test")
        XCTAssertTrue(html.contains("img-src file: data:"))
    }
}
