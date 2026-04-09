import XCTest

final class SecurityTests: XCTestCase {

    func testJavascriptLinkBlocked() {
        let input = "[click me](javascript:alert(1))"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("javascript:"), "javascript: protocol should be stripped")
        XCTAssertTrue(html.contains("click me"), "Link text preserved")
    }

    func testVBScriptLinkBlocked() {
        let input = "[click](vbscript:msgbox)"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("vbscript:"), "vbscript: protocol should be stripped")
    }

    func testDataURIBlocked() {
        let input = "![img](data:text/html,<script>alert(1)</script>)"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("data:text/html"), "data:text/html should be blocked")
    }

    func testSafeLinksAllowed() {
        let input = "[link](https://example.com)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("href=\"https://example.com\""), "HTTPS links allowed")
    }

    func testRelativeLinksAllowed() {
        let input = "[link](./other.md)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("href=\"./other.md\""), "Relative links allowed")
    }

    func testSingleQuoteEscaped() {
        let input = "It's a test with 'quotes'"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("<p>It's"), "Single quotes should be escaped in content")
    }

    func testInlineHTMLEscaped() {
        let input = "Test <script>alert('xss')</script> end"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("<script>alert"), "Script tags should be escaped")
    }

    func testHTMLBlockEscaped() {
        let input = """
        <div onclick="alert('xss')">
        malicious content
        </div>
        """
        let html = MarkdownRenderer.render(input)
        // The HTML block should be escaped and wrapped in <pre><code> — not rendered as live HTML
        XCTAssertTrue(html.contains("&lt;div"), "HTML block should be entity-escaped")
        XCTAssertFalse(html.contains("<div onclick"), "Raw HTML block should not be rendered as live HTML")
    }

    func testDataImageURIAllowed() {
        let input = "![img](data:image/png;base64,iVBORw0KGgo=)"
        let html = MarkdownRenderer.render(input)
        XCTAssertTrue(html.contains("data:image/png;base64"), "data:image/* URIs should be allowed")
        XCTAssertTrue(html.contains("<img"), "Image tag should render")
    }

    func testDataJavascriptURIBlocked() {
        let input = "[click](data:text/javascript,alert(1))"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("data:text/javascript"), "data:text/javascript should be blocked")
    }

    func testDataApplicationURIBlocked() {
        let input = "![img](data:application/pdf;base64,abc)"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("data:application/"), "data:application/* should be blocked for images")
    }

    func testDataSVGURIBlocked() {
        // Base64 SVG avoids markdown parser splitting on < >
        let input = "![img](data:image/svg+xml;base64,PHN2Zz4=)"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("<img"), "data:image/svg+xml should be blocked (SVG can execute JS)")
    }

    func testMixedCaseJavascriptBlocked() {
        let input = "[click](JaVaScRiPt:alert(1))"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("javascript:"), "Mixed-case javascript: should be blocked")
    }

    func testUppercaseDataURIBlocked() {
        let input = "![img](DATA:TEXT/HTML,<script>alert(1)</script>)"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("data:text/html"), "Uppercase DATA: should be blocked")
    }

    func testBOMHandling() {
        let input = "\u{FEFF}---\ntitle: BOM Test\n---\nContent"
        let result = FrontmatterParser.parse(input)
        XCTAssertNotNil(result.frontmatter, "Should parse frontmatter with BOM")
        XCTAssertEqual(result.frontmatter?.title, "BOM Test")
    }

    func testDataURILengthLimit() {
        let hugePayload = String(repeating: "A", count: 11_000_000)
        let input = "![img](data:image/png;base64,\(hugePayload))"
        let html = MarkdownRenderer.render(input)
        XCTAssertFalse(html.contains("<img"), "Oversized data URI should be blocked")
    }
}
