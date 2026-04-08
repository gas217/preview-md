import Foundation
import Markdown

enum MarkdownRenderer {
    static func render(fileAt url: URL) throws -> String {
        let content: String
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            content = utf8
        } else if let latin1 = try? String(contentsOf: url, encoding: .isoLatin1) {
            content = latin1
        } else {
            // Last resort: lossy UTF-8
            let data = try Data(contentsOf: url)
            content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? ""
        }
        return render(content)
    }

    static func render(_ input: String) -> String {
        let parsed = FrontmatterParser.parse(input)
        let frontmatterHTML = renderFrontmatter(parsed.frontmatter)
        let document = Document(parsing: parsed.content)
        var converter = HTMLConverter()
        let contentHTML = converter.visit(document)
        return HTMLTemplate.build(frontmatter: frontmatterHTML, content: contentHTML)
    }

    private static func renderFrontmatter(_ frontmatter: Frontmatter?) -> String {
        guard let fm = frontmatter else { return "" }

        var html = "<div class=\"frontmatter\">\n"

        if let title = fm.title {
            html += "  <h1 class=\"fm-title\">\(escapeHTML(title))</h1>\n"
        }

        var metaItems: [String] = []

        if let status = fm.status {
            let statusClass = statusColorClass(status)
            metaItems.append("<span class=\"fm-badge \(statusClass)\">\(escapeHTML(status))</span>")
        }

        if let priority = fm.priority {
            let priorityClass = priorityColorClass(priority)
            metaItems.append("<span class=\"fm-badge \(priorityClass)\">Priority: \(escapeHTML(priority))</span>")
        }

        for dateEntry in fm.dates {
            let label = dateEntry.label == "date" ? "" : "\(escapeHTML(dateEntry.label)): "
            metaItems.append("<span class=\"fm-date\">\(label)\(escapeHTML(dateEntry.value))</span>")
        }

        if !fm.tags.isEmpty {
            let tagHTML = fm.tags.map { "<span class=\"fm-tag\">\(escapeHTML($0))</span>" }.joined(separator: " ")
            metaItems.append(tagHTML)
        }

        if !metaItems.isEmpty {
            html += "  <div class=\"fm-meta\">\(metaItems.joined(separator: " "))</div>\n"
        }

        // Render remaining fields as a definition list
        let dateFieldNames: Set<String> = ["date", "created", "modified", "updated", "due", "deadline", "created_at", "updated_at", "published", "completed"]
        let skipFields = Set(["title", "status", "priority", "tags"]).union(dateFieldNames)
        let otherFields = fm.fields.filter { !skipFields.contains($0.key) }

        if !otherFields.isEmpty {
            html += "  <dl class=\"fm-fields\">\n"
            for field in otherFields {
                html += "    <dt>\(escapeHTML(field.key))</dt>\n"
                html += "    <dd>\(escapeHTML(formatValue(field.value)))</dd>\n"
            }
            html += "  </dl>\n"
        }

        html += "</div>\n"
        return html
    }

    private static func statusColorClass(_ status: String) -> String {
        switch status.lowercased() {
        case "done", "complete", "completed", "closed", "resolved":
            return "badge-green"
        case "in progress", "in-progress", "active", "doing", "wip":
            return "badge-blue"
        case "blocked", "stuck":
            return "badge-red"
        case "todo", "to do", "open", "new", "backlog":
            return "badge-gray"
        case "review", "in review", "pending":
            return "badge-yellow"
        default:
            return "badge-gray"
        }
    }

    private static func priorityColorClass(_ priority: String) -> String {
        switch priority.lowercased() {
        case "critical", "urgent", "p0":
            return "badge-red"
        case "high", "p1":
            return "badge-orange"
        case "medium", "normal", "p2":
            return "badge-yellow"
        case "low", "p3":
            return "badge-gray"
        default:
            return "badge-gray"
        }
    }

    private static func formatValue(_ value: Any) -> String {
        if let array = value as? [Any] {
            return array.map { formatValue($0) }.joined(separator: ", ")
        }
        if let dict = value as? [String: Any] {
            return dict.map { "\($0.key): \(formatValue($0.value))" }.joined(separator: "; ")
        }
        if let bool = value as? Bool {
            return bool ? "Yes" : "No"
        }
        return "\(value)"
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
