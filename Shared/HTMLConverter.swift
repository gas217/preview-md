import Foundation
import Markdown

struct HTMLConverter: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(_ markup: any Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    // MARK: - Block Elements

    mutating func visitDocument(_ document: Document) -> String {
        document.children.map { visit($0) }.joined()
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        let level = heading.level
        let id = heading.plainText
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let content = heading.children.map { visit($0) }.joined()
        return "<h\(level) id=\"\(escapeAttribute(id))\">\(content)</h\(level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        let content = paragraph.children.map { visit($0) }.joined()
        return "<p>\(content)</p>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        let content = blockQuote.children.map { visit($0) }.joined()
        return "<blockquote>\n\(content)</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let escaped = escapeHTML(codeBlock.code)
        if let lang = codeBlock.language, !lang.isEmpty {
            return "<pre><code class=\"language-\(escapeAttribute(lang))\">\(escaped)</code></pre>\n"
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
        let start = orderedList.startIndex
        let items = orderedList.children.map { visit($0) }.joined()
        if start != 1 {
            return "<ol start=\"\(start)\">\n\(items)</ol>\n"
        }
        return "<ol>\n\(items)</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        let hasCheckboxes = unorderedList.children.contains { child in
            if let item = child as? ListItem {
                return item.checkbox != nil
            }
            return false
        }
        let items = unorderedList.children.map { visit($0) }.joined()
        if hasCheckboxes {
            return "<ul class=\"task-list\">\n\(items)</ul>\n"
        }
        return "<ul>\n\(items)</ul>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        let content = listItem.children.map { visit($0) }.joined()
        if let checkbox = listItem.checkbox {
            let checked = checkbox == .checked
            let checkedAttr = checked ? " checked disabled" : " disabled"
            let className = checked ? "task-list-item done" : "task-list-item"
            return "<li class=\"\(className)\"><input type=\"checkbox\"\(checkedAttr)> \(content)</li>\n"
        }
        return "<li>\(content)</li>\n"
    }

    // MARK: - Tables

    mutating func visitTable(_ table: Table) -> String {
        let alignments = table.columnAlignments
        var html = "<table>\n"
        html += "<thead>\n<tr>\n"
        for (i, cell) in table.head.cells.enumerated() {
            let align = alignmentAttr(alignments, column: i)
            let content = cell.children.map { visit($0) }.joined()
            html += "<th\(align)>\(content)</th>\n"
        }
        html += "</tr>\n</thead>\n"

        let bodyChildren = Array(table.body.children)
        if !bodyChildren.isEmpty {
            html += "<tbody>\n"
            for child in bodyChildren {
                if let row = child as? Table.Row {
                    html += "<tr>\n"
                    for (i, cell) in row.cells.enumerated() {
                        let align = alignmentAttr(alignments, column: i)
                        let content = cell.children.map { visit($0) }.joined()
                        html += "<td\(align)>\(content)</td>\n"
                    }
                    html += "</tr>\n"
                }
            }
            html += "</tbody>\n"
        }
        html += "</table>\n"
        return html
    }

    private func alignmentAttr(_ alignments: [Table.ColumnAlignment?], column: Int) -> String {
        guard column < alignments.count, let alignment = alignments[column] else { return "" }
        switch alignment {
        case .left: return " style=\"text-align:left\""
        case .center: return " style=\"text-align:center\""
        case .right: return " style=\"text-align:right\""
        }
    }

    // MARK: - Inline Elements

    mutating func visitText(_ text: Text) -> String {
        escapeHTML(text.plainText)
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        let content = strong.children.map { visit($0) }.joined()
        return "<strong>\(content)</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        let content = emphasis.children.map { visit($0) }.joined()
        return "<em>\(content)</em>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitLink(_ link: Markdown.Link) -> String {
        let content = link.children.map { visit($0) }.joined()
        let rawHref = link.destination ?? ""
        guard isSafeURL(rawHref) else { return content }
        let href = escapeAttribute(rawHref)
        if let title = link.title, !title.isEmpty {
            return "<a href=\"\(href)\" title=\"\(escapeAttribute(title))\">\(content)</a>"
        }
        return "<a href=\"\(href)\">\(content)</a>"
    }

    mutating func visitImage(_ image: Markdown.Image) -> String {
        let alt = image.plainText
        let rawSrc = image.source ?? ""
        guard isSafeURL(rawSrc) else {
            return "<span>[\(escapeHTML(alt))]</span>"
        }
        let src = escapeAttribute(rawSrc)
        if let title = image.title, !title.isEmpty {
            return "<img src=\"\(src)\" alt=\"\(escapeAttribute(alt))\" title=\"\(escapeAttribute(title))\">"
        }
        return "<img src=\"\(src)\" alt=\"\(escapeAttribute(alt))\">"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>\n"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        let content = strikethrough.children.map { visit($0) }.joined()
        return "<del>\(content)</del>"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        // Escape inline HTML for security in Quick Look context
        escapeHTML(inlineHTML.rawHTML)
    }

    // MARK: - Helpers

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func escapeAttribute(_ string: String) -> String {
        escapeHTML(string)
    }

    private func isSafeURL(_ url: String) -> Bool {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Block dangerous protocols
        if trimmed.hasPrefix("javascript:") || trimmed.hasPrefix("vbscript:") || trimmed.hasPrefix("data:text/html") {
            return false
        }
        return true
    }

}

extension Heading {
    var plainText: String {
        children.compactMap { ($0 as? Text)?.plainText }.joined(separator: " ")
    }
}
