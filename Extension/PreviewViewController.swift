import Foundation
import QuickLookUI
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let html = try MarkdownRenderer.render(fileAt: request.fileURL)
        let data = Data(html.utf8)

        let reply = QLPreviewReply(
            dataOfContentType: UTType.html,
            contentSize: CGSize(width: 800, height: 600)
        ) { _ in
            return data
        }
        return reply
    }
}
