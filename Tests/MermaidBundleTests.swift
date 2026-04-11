import XCTest

final class MermaidBundleTests: XCTestCase {
    private final class BundleLocator {}

    func testMermaidBundleFileExists() {
        let bundle = Bundle(for: BundleLocator.self)
        let url = bundle.url(forResource: "mermaid.min", withExtension: "js")
        XCTAssertNotNil(url, "mermaid.min.js should be in the test target bundle")
    }

    func testMermaidBundleIsNonTrivial() throws {
        let bundle = Bundle(for: BundleLocator.self)
        guard let url = bundle.url(forResource: "mermaid.min", withExtension: "js") else {
            XCTFail("mermaid.min.js missing from bundle")
            return
        }
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThan(data.count, 1_000_000, "mermaid.min.js should be at least 1 MB")
        XCTAssertLessThan(data.count, 10_000_000, "mermaid.min.js should be under 10 MB")
    }

    func testMermaidBundleHasNoForbiddenFunctionCalls() throws {
        let bundle = Bundle(for: BundleLocator.self)
        guard let url = bundle.url(forResource: "mermaid.min", withExtension: "js"),
              let js = try? String(contentsOf: url, encoding: .utf8) else {
            XCTFail("mermaid.min.js unreadable")
            return
        }
        XCTAssertFalse(js.contains("Function(\"return this\")"),
                       "Patched mermaid.min.js must not contain Function(\"return this\")")
    }
}
