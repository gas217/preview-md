import XCTest

final class EdgeCaseTests: XCTestCase {

    // MARK: - Heading with inline formatting

    func testHeadingWithBold() {
        let input = "# Hello **World**"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("id=\"hello-world\""), "Heading ID includes text from bold")
        XCTAssertTrue(html.contains("<strong>World</strong>"))
    }

    func testHeadingWithCode() {
        let input = "## The `render()` method"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<code>render()</code>"), "Code in heading preserved")
        XCTAssertTrue(html.contains("id=\"the-render-method\""), "Heading ID extracts text from code")
    }

    func testHeadingWithLink() {
        let input = "### [Click here](https://example.com) for info"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<a href="), "Link in heading works")
    }

    // MARK: - Deeply nested lists

    func testNestedLists() {
        let input = """
        - Level 1
          - Level 2
            - Level 3
              - Level 4
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("Level 4"))
    }

    // MARK: - Only frontmatter, no content

    func testFrontmatterOnly() {
        let input = """
        ---
        title: Just Metadata
        status: done
        ---
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("Just Metadata"), "Title from frontmatter rendered")
        XCTAssertTrue(html.contains("badge-green"), "Status badge rendered")
        XCTAssertTrue(html.contains("<article"), "Article wrapper present")
    }

    // MARK: - Unicode and emoji

    func testUnicodeContent() {
        let input = "# Привет мир\n\n日本語テスト\n\nEmoji: 🎉🚀✅"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("Привет мир"), "Cyrillic preserved")
        XCTAssertTrue(html.contains("日本語テスト"), "CJK preserved")
        XCTAssertTrue(html.contains("🎉"), "Emoji preserved")
    }

    func testUnicodeFrontmatter() {
        let input = """
        ---
        title: Ünïcödé Tïtlé
        tags:
          - café
          - naïve
        ---
        Content
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("Ünïcödé Tïtlé"), "Unicode frontmatter title")
        XCTAssertTrue(html.contains("café"), "Unicode tag")
    }

    // MARK: - Windows line endings

    func testCRLFLineEndings() {
        let input = "---\r\ntitle: CRLF Test\r\nstatus: done\r\n---\r\n# Hello\r\n\r\nParagraph\r\n"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("CRLF Test"), "Frontmatter parsed with CRLF")
        XCTAssertTrue(html.contains("<h1"), "Heading rendered with CRLF")
        XCTAssertTrue(html.contains("<p>Paragraph"), "Paragraph rendered with CRLF")
    }

    func testCRLFFrontmatterValues() {
        let input = "---\r\ntitle: CRLF Values\r\ntags:\r\n  - one\r\n  - two\r\n---\r\nContent\r\n"
        let result = FrontmatterParser.parse(input)
        XCTAssertNotNil(result.frontmatter)
        XCTAssertEqual(result.frontmatter?.title, "CRLF Values")
        XCTAssertEqual(result.frontmatter?.tags, ["one", "two"])
    }

    func testPureCRLineEndings() {
        let input = "---\rtitle: CR Only\rstatus: done\r---\r# Hello\r"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("CR Only"), "Frontmatter parsed with CR-only endings")
    }

    // MARK: - Long content

    func testVeryLongLine() {
        let longWord = String(repeating: "a", count: 5000)
        let input = "# Title\n\n\(longWord)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains(longWord), "Long line preserved")
    }

    // MARK: - Mixed frontmatter types

    func testBooleanFrontmatter() {
        let input = """
        ---
        title: Bool Test
        draft: true
        published: false
        ---
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("Yes") || html.contains("true"), "Boolean true rendered")
    }

    func testNumericFrontmatter() {
        let input = """
        ---
        title: Numbers
        count: 42
        score: 3.14
        ---
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("42"), "Integer rendered")
        XCTAssertTrue(html.contains("3.14"), "Float rendered")
    }

    // MARK: - Edge case markdown

    func testEmptyCodeBlock() {
        let input = "```\n```"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<pre><code>"), "Empty code block renders")
    }

    func testConsecutiveHeadings() {
        let input = "# H1\n## H2\n### H3\n#### H4\n##### H5\n###### H6"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<h1"))
        XCTAssertTrue(html.contains("<h6"))
    }

    func testHorizontalRules() {
        let input = "---\n\n***\n\n___"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<hr>"), "Horizontal rule rendered")
    }

    func testNestedBlockquotes() {
        let input = "> Level 1\n>> Level 2\n>>> Level 3"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<blockquote>"))
    }

    func testMixedListTypes() {
        let input = """
        1. Ordered
        2. Items
           - Nested unordered
           - Another
        3. Back to ordered
        """
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<ol>"), "Ordered list")
        XCTAssertTrue(html.contains("<ul>"), "Nested unordered list")
    }
}
