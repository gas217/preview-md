import Foundation
import Markdown

struct HTMLConverter: MarkupVisitor {
    typealias Result = String
    private var usedIDs: [String: Int] = [:]

    mutating func defaultVisit(_ markup: any Markup) -> String {
        visitChildren(markup)
    }

    // MARK: - Block Elements

    mutating func visitHeading(_ heading: Heading) -> String {
        let level = heading.level
        var id = heading.recursiveText
            .lowercased()
            .replacingOccurrences(of: "[\u{2013}\u{2014} ]", with: "-", options: .regularExpression)
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        if id.isEmpty { id = "heading" }
        let count = usedIDs[id, default: 0]
        usedIDs[id] = count + 1
        if count > 0 { id = "\(id)-\(count)" }
        let content = visitChildren(heading)
        return "<h\(level) id=\"\(escapeHTML(id))\">\(content)</h\(level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        "<p>\(visitChildren(paragraph))</p>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        "<blockquote>\n\(visitChildren(blockQuote))</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let escaped = escapeHTML(codeBlock.code)
        if let lang = codeBlock.language, !lang.isEmpty {
            let s = escapeHTML(lang)
            return "<pre><code class=\"language-\(s)\" data-lang=\"\(s)\">\(escaped)</code></pre>\n"
        }
        return "<pre><code>\(escaped)</code></pre>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        // Escape raw HTML blocks for security in Quick Look context
        "<pre><code>\(escapeHTML(html.rawHTML))</code></pre>\n"
    }

    // MARK: - Lists

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let startAttr = orderedList.startIndex != 1 ? " start=\"\(orderedList.startIndex)\"" : ""
        return "<ol\(startAttr)>\n\(visitChildren(orderedList))</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        let isTasks = unorderedList.children.contains { ($0 as? ListItem)?.checkbox != nil }
        let cls = isTasks ? " class=\"task-list\"" : ""
        return "<ul\(cls)>\n\(visitChildren(unorderedList))</ul>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        let content = visitChildren(listItem)
        guard let checkbox = listItem.checkbox else { return "<li>\(content)</li>\n" }
        let done = checkbox == .checked
        return "<li class=\"task-list-item\(done ? " done" : "")\"><input type=\"checkbox\"\(done ? " checked disabled" : " disabled")> \(content)</li>\n"
    }

    // MARK: - Tables

    mutating func visitTable(_ table: Table) -> String {
        let aligns = table.columnAlignments
        var html = "<div class=\"table-wrap\"><table>\n<thead>\n<tr>\n"
        html += renderCells(table.head.cells, tag: "th", alignments: aligns)
        html += "</tr>\n</thead>\n"

        let rows = table.body.children.compactMap { $0 as? Table.Row }
        if !rows.isEmpty {
            html += "<tbody>\n"
            for row in rows {
                html += "<tr>\n"
                html += renderCells(row.cells, tag: "td", alignments: aligns)
                html += "</tr>\n"
            }
            html += "</tbody>\n"
        }
        html += "</table></div>\n"
        return html
    }

    private static let alignCSS: [Table.ColumnAlignment: String] = [
        .left: " style=\"text-align:left\"", .center: " style=\"text-align:center\"", .right: " style=\"text-align:right\""
    ]

    private mutating func renderCells(_ cells: some Sequence<Table.Cell>, tag: String, alignments: [Table.ColumnAlignment?]) -> String {
        cells.enumerated().map { (i, cell) in
            let align = (i < alignments.count ? alignments[i] : nil).flatMap { Self.alignCSS[$0] } ?? ""
            return "<\(tag)\(align)>\(visitChildren(cell))</\(tag)>\n"
        }.joined()
    }

    // MARK: - Inline Elements

    mutating func visitText(_ text: Text) -> String {
        escapeHTML(text.plainText)
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        "<strong>\(visitChildren(strong))</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(visitChildren(emphasis))</em>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitLink(_ link: Markdown.Link) -> String {
        let content = visitChildren(link)
        let rawHref = link.destination ?? ""
        guard isSafeURL(rawHref) else { return content }
        return "<a href=\"\(escapeHTML(rawHref))\"\(attr("title", link.title))>\(content)</a>"
    }

    mutating func visitImage(_ image: Markdown.Image) -> String {
        let rawSrc = image.source ?? ""
        guard isSafeURL(rawSrc) else {
            return "<span>[\(escapeHTML(image.plainText))]</span>"
        }
        return "<img src=\"\(escapeHTML(rawSrc))\" alt=\"\(escapeHTML(image.plainText))\"\(attr("title", image.title)) loading=\"lazy\">"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>\n"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(visitChildren(strikethrough))</del>"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        // Escape inline HTML for security in Quick Look context
        escapeHTML(inlineHTML.rawHTML)
    }

    // MARK: - Helpers

    private mutating func visitChildren(_ markup: any Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    private func escapeHTML(_ string: String) -> String {
        HTMLUtils.escapeHTML(string)
    }

    private func attr(_ name: String, _ value: String?) -> String {
        guard let v = value, !v.isEmpty else { return "" }
        return " \(name)=\"\(escapeHTML(v))\""
    }

    private static let maxDataURILength = 10_000_000
    private static let safeDataURIPrefixes = ["data:image/png", "data:image/jpeg", "data:image/gif", "data:image/webp", "data:image/bmp", "data:image/x-icon"]

    private func isSafeURL(_ url: String) -> Bool {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasPrefix("javascript:") || trimmed.hasPrefix("vbscript:") {
            return false
        }
        if trimmed.hasPrefix("data:") {
            return url.count <= Self.maxDataURILength
                && Self.safeDataURIPrefixes.contains(where: { trimmed.hasPrefix($0) })
        }
        return true
    }

}

extension Markup {
    var recursiveText: String {
        switch self {
        case let text as Text: return text.plainText
        case let code as InlineCode: return code.code
        case is SoftBreak: return " "
        default: return children.map { $0.recursiveText }.joined()
        }
    }
}
