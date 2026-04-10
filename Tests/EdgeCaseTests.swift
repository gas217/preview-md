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

    func testBOMWithMalformedYAML() {
        let input = "\u{FEFF}---\nthis is not: [valid yaml\n---\n# Content\nHello"
        let result = FrontmatterParser.parse(input)
        // Content should be BOM-stripped even on YAML error path
        XCTAssertFalse(result.content.hasPrefix("\u{FEFF}"), "BOM should be stripped on malformed YAML path")
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

    func testZeroNotShownAsBool() {
        let input = """
        ---
        title: Zero Test
        count: 0
        retries: 1
        ---
        """
        let html = MarkdownRenderer.render(input)
        // 0 and 1 should render as numbers, not "No"/"Yes"
        XCTAssertTrue(html.contains(">0<"), "Zero should render as 0, not No")
        XCTAssertTrue(html.contains(">1<"), "One should render as 1, not Yes")
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

    func testDuplicateHeadingIDs() {
        let input = "## Notes\n\nFirst section.\n\n## Notes\n\nSecond section."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("id=\"notes\""), "First heading gets base ID")
        XCTAssertTrue(html.contains("id=\"notes-1\""), "Second heading gets deduplicated ID")
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

    // MARK: - Empty heading ID fallback

    func testEmptyHeadingGetsFallbackID() {
        // Use chars that all get filtered out (no letters, digits, dashes, or underscores)
        let input = "## @#$%"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("id=\"heading\""), "Empty heading should get fallback ID")
    }

    func testDuplicateEmptyHeadings() {
        let input = "## @#$\n\n## @#$"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("id=\"heading\""))
        XCTAssertTrue(html.contains("id=\"heading-1\""), "Second empty heading gets deduplicated ID")
    }

    // MARK: - Code block language label

    func testCodeBlockDataLang() {
        let input = "```swift\nlet x = 1\n```"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("data-lang=\"swift\""), "Code block should have data-lang attribute")
    }

    func testCodeBlockNoLangNoDataLang() {
        let input = "```\nplain code\n```"
        let html = MarkdownRenderer.render(input)
        // Check the <code> tag itself doesn't have data-lang (it also appears in CSS/JS template)
        XCTAssertTrue(html.contains("<pre><code>plain code"), "Unlabeled code block should render without data-lang on tag")
    }

    // MARK: - Image lazy loading

    // MARK: - Admonitions

    func testGitHubAdmonitionNote() {
        // Test the detection directly — swift-markdown wraps [!NOTE] as text inside a paragraph
        let input = "> [!NOTE]\n> This is a note."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("class=\"adm-note\""), "Note admonition should get styled class")
    }

    func testGitHubAdmonitionWarning() {
        let input = "> [!WARNING]\n> Be careful."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<blockquote class=\"adm-warning\">"))
    }

    func testRegularBlockquoteUnchanged() {
        let input = "> Just a normal quote."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("<blockquote>\n"), "Regular blockquotes should not have admonition class")
    }

    // MARK: - Image lazy loading

    func testImageLazyLoading() {
        let input = "![alt](image.png)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("loading=\"lazy\""), "Images should have lazy loading")
    }
}
