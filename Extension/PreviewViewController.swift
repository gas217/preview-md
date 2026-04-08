import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {
    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(false, forKey: "javaScriptCanOpenWindowsAutomatically")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: config)

        // Transparent background — the HTML body provides its own background color
        // matching light/dark mode via prefers-color-scheme
        if #available(macOS 13.3, *) {
            webView.isInspectable = false
            webView.underPageBackgroundColor = .clear
        }
        webView.setValue(false, forKey: "drawsBackground")

        self.view = webView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let html = try MarkdownRenderer.render(fileAt: url)
            webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
            handler(nil)
        } catch {
            handler(error)
        }
    }
}
