import XCTest

final class PerformanceTests: XCTestCase {

    func testRenderPerformanceSmallFile() {
        let input = """
        ---
        title: Small File
        status: done
        ---

        # Hello

        Just a small markdown file with **bold** and *italic*.

        - Item 1
        - Item 2
        """
        measure {
            _ = MarkdownRenderer.render(input)
        }
    }

    func testRenderPerformanceLargeFile() throws {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/large_test.md")

        let content = try String(contentsOf: path, encoding: .utf8)
        XCTAssertTrue(content.count > 5000, "Large file should be substantial")

        measure {
            _ = MarkdownRenderer.render(content)
        }
    }

    func testRenderLargeFileUnder100ms() throws {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/large_test.md")

        let content = try String(contentsOf: path, encoding: .utf8)

        let start = CFAbsoluteTimeGetCurrent()
        let html = MarkdownRenderer.render(content)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        print("Large file render time: \(elapsed)ms")
        print("Output size: \(html.count) characters")
        XCTAssertLessThan(elapsed, 100, "Rendering should complete in under 100ms")
    }

    func testAngleBracketAutolinks() {
        // Standard CommonMark autolinks (angle bracket form)
        let input = "Visit <https://example.com> for more info."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<a href="), "Angle bracket autolink should render as link")
        XCTAssertTrue(html.contains("example.com"), "URL should be present")
    }

    func testBareURLsPreserved() {
        // Bare URLs are auto-linked by client-side JS, but text should be preserved
        let input = "Visit https://example.com for more info."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("https://example.com"), "Bare URL text preserved for JS auto-linking")
        // The autolink JS script should be present
        XCTAssertTrue(html.contains("autolinkScript") == false, "Script is inlined, not referenced by name")
        XCTAssertTrue(html.contains("urlRegex"), "Autolink JS is embedded in the HTML")
    }

    func testNestedFormatting() {
        let input = "This is ***bold and italic*** text."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<strong>"), "Bold should render")
        XCTAssertTrue(html.contains("<em>"), "Italic should render")
    }

    func testFencedCodeWithoutLanguage() {
        let input = """
        ```
        plain code block
        ```
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<pre><code>"), "Code block without language")
        XCTAssertTrue(html.contains("plain code block"))
    }

    func testOrderedList() {
        let input = """
        1. First
        2. Second
        3. Third
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<ol>"), "Ordered list rendered")
        XCTAssertTrue(html.contains("First"))
    }

    func testTableAlignment() {
        let input = """
        | Left | Center | Right |
        |:-----|:------:|------:|
        | a    | b      | c     |
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("text-align:left"), "Left alignment")
        XCTAssertTrue(html.contains("text-align:center"), "Center alignment")
        XCTAssertTrue(html.contains("text-align:right"), "Right alignment")
    }

    func testImageRendering() {
        let input = "![Alt text](image.png \"Title\")"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<img"), "Image tag rendered")
        XCTAssertTrue(html.contains("alt=\"Alt text\""), "Alt text present")
        XCTAssertTrue(html.contains("title=\"Title\""), "Title present")
    }

    func testRelativeImagePath() {
        let input = "![Screenshot](./assets/screenshot.png)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("src=\"./assets/screenshot.png\""), "Relative path preserved")
    }

    func testAbsoluteFileImagePath() {
        let input = "![Photo](file:///Users/test/photo.jpg)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("src=\"file:///Users/test/photo.jpg\""), "Absolute file path preserved")
    }

    func testCSPAllowsLocalImages() {
        let html = MarkdownRenderer.render("# test")
        XCTAssertTrue(html.contains("img-src file: data:"), "CSP allows file: and data: images")
    }
}
