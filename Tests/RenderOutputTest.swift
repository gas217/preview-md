import XCTest

/// Writes rendered HTML to /tmp for manual visual inspection
final class RenderOutputTest: XCTestCase {
    func testWriteRenderOutput() throws {
        for name in ["example", "frontmatter_task", "large_test"] {
            let path = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("TestFiles/\(name).md")
            guard FileManager.default.fileExists(atPath: path.path) else { continue }
            let html = MarkdownRenderer.render(try String(contentsOf: path, encoding: .utf8))
            try html.write(to: URL(fileURLWithPath: "/tmp/previewmd_\(name).html"), atomically: true, encoding: .utf8)
            print("Written: /tmp/previewmd_\(name).html (\(html.count) chars)")
        }
    }
}
