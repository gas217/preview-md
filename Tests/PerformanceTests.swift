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

    func testRenderLargeFileUnder100ms() throws {
        let path = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestFiles/large_test.md")

        let content = try String(contentsOf: path, encoding: .utf8)
        XCTAssertTrue(content.count > 5000, "Large file should be substantial")

        let start = CFAbsoluteTimeGetCurrent()
        let html = MarkdownRenderer.render(content)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        print("Large file render time: \(elapsed)ms")
        print("Output size: \(html.count) characters")
        XCTAssertLessThan(elapsed, 100, "Rendering should complete in under 100ms")
    }
}
