import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {
    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(false, forKey: "javaScriptCanOpenWindowsAutomatically")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
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
