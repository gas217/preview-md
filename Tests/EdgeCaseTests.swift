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

    // MARK: - Mermaid blocks

    func testMermaidBlockEmitsPlaceholderWithDataAttr() {
        let input = "```mermaid\ngraph TD;\n  A-->B;\n```"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("class=\"mermaid-block\""),
                      "Mermaid block should use .mermaid-block container")
        XCTAssertTrue(html.contains("data-mermaid-src=\""),
                      "Mermaid block should carry source in data-mermaid-src")
        XCTAssertTrue(html.contains("graph TD;"),
                      "Mermaid source must be preserved (HTML-escaped) in the data attribute")
    }

    func testMermaidSourceIsHTMLEscapedInDataAttribute() {
        let input = "```mermaid\ngraph LR; A-->B & \"C\"\n```"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("A--&gt;B &amp; &quot;C&quot;"),
                      "Mermaid source must be HTML-escaped inside data-mermaid-src")
        XCTAssertFalse(html.contains("data-mermaid-src=\"graph LR; A-->B & \"C\""),
                       "Unescaped quotes would break the attribute")
    }

    func testMermaidDoesNotEmitLegacyHeader() {
        let input = "```mermaid\ngraph TD;\n```"
        let body = bodyHTML(MarkdownRenderer.render(input))
        XCTAssertFalse(body.contains("mermaid-header"),
                       "Old 'mermaid-header' div should be gone — init JS handles labeling")
        XCTAssertFalse(body.contains("Mermaid Diagram"),
                       "Old header text should be gone")
    }

    func testMermaidDoesNotGetLanguageClass() {
        let input = "```mermaid\ngraph TD;\n```"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("language-mermaid"),
                       "Mermaid should not get generic language class")
    }

    func testRegularCodeBlockUnaffected() {
        let input = "```python\nprint('hi')\n```"
        let body = bodyHTML(MarkdownRenderer.render(input))
        XCTAssertFalse(body.contains("mermaid-block"),
                       "Python block must not be wrapped in mermaid container")
        XCTAssertFalse(body.contains("data-mermaid-src"),
                       "Python block must not carry a mermaid data attribute")
        XCTAssertTrue(body.contains("<pre><code class=\"language-python\""),
                      "Regular code keeps its language class")
    }

    // MARK: - Image lazy loading

    func testImageLazyLoading() {
        let input = "![alt](image.png)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("loading=\"lazy\""), "Images should have lazy loading")
    }

    // MARK: - Mermaid injection in HTMLTemplate

    func testTemplateOmitsMermaidScriptWhenNoDiagrams() {
        let html = HTMLTemplate.build(frontmatter: "", content: "<p>hi</p>")
        XCTAssertFalse(html.contains("mermaid.initialize"),
                       "Plain docs must not ship the mermaid bundle")
        // NB: use trailing `="` to distinguish the real attribute from the
        // CSS selector `.mermaid-block[data-mermaid-src]::before` which also
        // contains the substring `data-mermaid-src` and is always in the template.
        XCTAssertFalse(html.contains("data-mermaid-src=\""),
                       "Plain docs have no mermaid placeholder divs")
    }

    func testTemplateInjectsMermaidScriptWhenHasMermaid() {
        let html = HTMLTemplate.build(frontmatter: "", content: "<div class=\"mermaid-block\" data-mermaid-src=\"graph TD\"></div>", hasMermaid: true)
        XCTAssertTrue(html.contains("mermaid.initialize"),
                      "hasMermaid=true must inject init script")
        XCTAssertTrue(html.contains("mermaid-svg-"),
                      "init script must reference mermaid-svg- id prefix")
    }

    func testTemplateMermaidScriptIsLargeEnough() {
        XCTAssertGreaterThan(HTMLTemplate.mermaidScript.count, 1_000_000,
                             "Vendored mermaid.min.js must be at least 1 MB when loaded")
    }

    func testTemplateCSPStillForbidsUnsafeEval() {
        let html = HTMLTemplate.build(frontmatter: "", content: "<div class=\"mermaid-block\" data-mermaid-src=\"graph TD\"></div>", hasMermaid: true)
        XCTAssertFalse(html.contains("'unsafe-eval'"),
                       "CSP must never include unsafe-eval")
        XCTAssertTrue(html.contains("script-src 'nonce-"),
                      "CSP must still use nonce-based script-src")
    }

    func testRendererInjectsMermaidBundleWhenDocumentHasMermaid() {
        let input = "# Hi\n\n```mermaid\ngraph TD; A-->B\n```\n"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("mermaid.initialize"),
                      "Renderer must trip hasMermaid when a mermaid block is present")
    }

    func testRendererOmitsMermaidBundleForPlainDoc() {
        let input = "# Hi\n\n```python\nprint('hi')\n```\n"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("mermaid.initialize"),
                       "Renderer must not inject mermaid bundle when no mermaid block")
    }

    func testRendererDetectsMermaidInNestedContexts() {
        let cases = [
            ("blockquote",    "> ```mermaid\n> graph TD; A-->B\n> ```\n"),
            ("list item",     "- item\n\n  ```mermaid\n  graph TD; A-->B\n  ```\n"),
            ("uppercase tag", "```MERMAID\ngraph TD; A-->B\n```\n"),
        ]
        for (name, input) in cases {
            let html = MarkdownRenderer.render(input)
            XCTAssertTrue(html.contains("mermaid.initialize"),
                          "Walker should detect mermaid in \(name): \(input)")
        }
    }

    // MARK: - Mermaid fixture rendering (follows RenderOutputTest pattern)

    func testMermaidFixtureRenders() throws {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/mermaid-sample.md")
        guard FileManager.default.fileExists(atPath: path.path) else {
            throw XCTSkip("TestFiles/mermaid-sample.md not found relative to \(#file)")
        }
        let html = try MarkdownRenderer.render(fileAt: path)
        let body = bodyHTML(html)

        // Bundle injected (document has mermaid blocks)
        XCTAssertTrue(html.contains("mermaid.initialize"),
                      "Mermaid bundle must be injected for a document with mermaid blocks")

        // All 3 placeholder divs emitted
        let placeholderCount = body.components(separatedBy: "data-mermaid-src=\"").count - 1
        XCTAssertEqual(placeholderCount, 3,
                       "Fixture has 3 mermaid blocks; got \(placeholderCount) placeholders")

        // Each diagram's source is preserved in the placeholder
        XCTAssertTrue(body.contains("graph TD"), "Flowchart source preserved")
        XCTAssertTrue(body.contains("sequenceDiagram"), "Sequence source preserved")
        XCTAssertTrue(body.contains("not valid mermaid syntax"), "Broken source preserved")

        // Frontmatter rendered
        XCTAssertTrue(html.contains("Mermaid Sample"), "Frontmatter title rendered")
        XCTAssertTrue(html.contains("fm-badge"), "Status badge rendered")

        // Prose after diagrams survives
        XCTAssertTrue(body.contains("Regular prose after the diagrams should still render fine."),
                      "Trailing prose must not be swallowed by mermaid blocks")

        // Write to /tmp for manual browser inspection
        try html.write(to: URL(fileURLWithPath: "/tmp/previewmd-mermaid-full.html"),
                       atomically: true, encoding: .utf8)
        print("Written: /tmp/previewmd-mermaid-full.html (\(html.count) chars)")
    }

    // MARK: - Math/LaTeX rendering

    func testRendererInjectsKaTeXWhenDocumentHasMath() {
        let input = "The equation $$E = mc^2$$ is famous."
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("renderMathInElement"),
                      "Renderer must inject KaTeX when math delimiters present")
        XCTAssertTrue(html.contains("font-src data:"),
                      "CSP must include font-src data: for KaTeX fonts")
    }

    func testRendererOmitsKaTeXForPlainDoc() {
        let input = "# No math here\n\nJust regular text."
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("renderMathInElement"),
                       "Renderer must not inject KaTeX when no math")
        XCTAssertFalse(html.contains("font-src"),
                       "CSP must not include font-src when no math")
    }

    func testMathDetectionVariousDelimiters() {
        let cases = [
            ("display $$", "The result is $$x^2 + y^2$$"),
            ("inline \\\\(", "The value \\(x\\) is positive"),
            ("display \\\\[", "We have \\[\\sum_{i=1}^n i\\]"),
        ]
        for (name, input) in cases {
            let html = MarkdownRenderer.render(input)
            XCTAssertTrue(html.contains("renderMathInElement"),
                          "Should detect math in \(name)")
        }
    }

    func testKaTeXScriptIsLargeEnough() {
        XCTAssertGreaterThan(HTMLTemplate.katexScript.count, 100_000,
                             "Vendored katex.min.js must be at least 100 KB")
    }

    func testKaTeXCSSHasInlinedFonts() {
        XCTAssertTrue(HTMLTemplate.katexCSS.contains("data:font/woff2;base64,"),
                      "KaTeX CSS must have inlined woff2 fonts")
    }

    func testMathFixtureRendersToTmp() throws {
        let fixture = """
        # Math Rendering Test

        Inline: The equation $$E = mc^2$$ is famous.

        Display math:

        $$
        \\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}
        $$

        Regular text after math.
        """
        let html = MarkdownRenderer.render(fixture)
        XCTAssertTrue(html.contains("renderMathInElement"))
        let url = URL(fileURLWithPath: "/tmp/previewmd-math-out.html")
        try html.write(to: url, atomically: true, encoding: .utf8)
        print("Written: \(url.path) (\(html.count) chars)")
    }
}
