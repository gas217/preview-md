import Cocoa
import QuickLookThumbnailing

class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let size = request.maximumSize

        do {
            let data = try Data(contentsOf: request.fileURL)
            let content = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""
            let parsed = FrontmatterParser.parse(content)

            let title = parsed.frontmatter?.title
                ?? request.fileURL.deletingPathExtension().lastPathComponent
            let preview = cleanPreview(parsed.content, maxChars: 600)

            let reply = QLThumbnailReply(contextSize: size, currentContextDrawing: { () -> Bool in
                self.drawThumbnail(size: size, title: title, preview: preview)
                return true
            })
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }

    private func drawThumbnail(size: CGSize, title: String, preview: String) {
        let rect = CGRect(origin: .zero, size: size)

        // Background
        NSColor.textBackgroundColor.setFill()
        rect.fill()

        // Left accent bar
        let barWidth: CGFloat = max(size.width * 0.02, 2)
        NSColor.controlAccentColor.setFill()
        CGRect(x: 0, y: 0, width: barWidth, height: size.height).fill()

        // Top accent line
        let lineH: CGFloat = max(size.height * 0.005, 1)
        NSColor.controlAccentColor.setFill()
        CGRect(x: 0, y: size.height - lineH, width: size.width, height: lineH).fill()

        let padding = size.width * 0.07
        let inset = CGRect(x: barWidth + padding, y: padding,
                           width: size.width - barWidth - padding * 2,
                           height: size.height - padding * 2 - lineH)

        // Title
        let titleSize = max(size.height * 0.085, 8)
        let titleFont = NSFont.systemFont(ofSize: titleSize, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.labelColor,
        ]
        let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
        let titleH = titleSize * 1.4
        let titleRect = CGRect(x: inset.minX,
                                y: inset.maxY - titleH,
                                width: inset.width,
                                height: titleH)
        titleStr.draw(with: titleRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])

        // Divider
        let divY = titleRect.minY - padding * 0.5
        NSColor.separatorColor.setFill()
        CGRect(x: inset.minX, y: divY, width: inset.width * 0.3, height: max(size.height * 0.003, 0.5)).fill()

        // Body preview
        let bodySize = max(size.height * 0.055, 6)
        let bodyFont = NSFont.systemFont(ofSize: bodySize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = bodySize * 0.2
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle,
        ]
        let bodyStr = NSAttributedString(string: preview, attributes: bodyAttrs)
        let bodyTop = divY - padding * 0.5
        let bodyRect = CGRect(x: inset.minX, y: inset.minY,
                               width: inset.width, height: bodyTop - inset.minY)
        bodyStr.draw(with: bodyRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
    }

    /// Strip markdown syntax for a clean text preview.
    private func cleanPreview(_ content: String, maxChars: Int) -> String {
        var text = String(content.prefix(maxChars * 2)) // take extra for stripping
        // Remove code fences
        text = text.replacingOccurrences(of: "```[^\n]*\n", with: "", options: .regularExpression)
        // Remove headings markers
        text = text.replacingOccurrences(of: "(?m)^#{1,6}\\s+", with: "", options: .regularExpression)
        // Remove bold/italic markers
        text = text.replacingOccurrences(of: "[*_]{1,3}", with: "", options: .regularExpression)
        // Remove link syntax
        text = text.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^)]+\\)", with: "$1", options: .regularExpression)
        // Remove image syntax
        text = text.replacingOccurrences(of: "!\\[([^\\]]*)\\]\\([^)]+\\)", with: "$1", options: .regularExpression)
        // Collapse whitespace
        text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxChars))
    }
}
