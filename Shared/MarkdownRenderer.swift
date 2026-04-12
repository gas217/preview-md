import Foundation
import Markdown

enum MarkdownRenderer {
    static func render(fileAt url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
        return render(content)
    }

    static func render(_ input: String) -> String {
        let parsed = FrontmatterParser.parse(input)
        let frontmatterHTML = renderFrontmatter(parsed.frontmatter)
        let document = Document(parsing: parsed.content)
        let hasMermaid = documentHasMermaid(document)
        let hasMath = contentHasMath(parsed.content)
        var converter = HTMLConverter()
        let contentHTML = converter.visit(document)
        return HTMLTemplate.build(frontmatter: frontmatterHTML, content: contentHTML, hasMermaid: hasMermaid, hasMath: hasMath)
    }

    private static func contentHasMath(_ content: String) -> Bool {
        if content.contains("$$") || content.contains("\\(") || content.contains("\\[") {
            return true
        }
        // Single-dollar: match $<non-digit>..$ but not prices like $5 or $100
        return content.range(of: "\\$[^\\d$][^$]+\\$", options: .regularExpression) != nil
    }

    private static func documentHasMermaid(_ markup: any Markup) -> Bool {
        if let code = markup as? CodeBlock, code.language?.lowercased() == "mermaid" {
            return true
        }
        for child in markup.children {
            if documentHasMermaid(child) { return true }
        }
        return false
    }

    private static func renderFrontmatter(_ frontmatter: Frontmatter?) -> String {
        guard let fm = frontmatter else { return "" }
        let esc = HTMLUtils.escapeHTML

        var html = "<div class=\"frontmatter\">\n"

        if let title = fm.title {
            html += "  <h1 class=\"fm-title\">\(esc(title))</h1>\n"
        }

        var metaItems: [String] = []

        if let status = fm.status {
            metaItems.append("<span class=\"fm-badge \(badgeClass(status, from: statusColors))\">\(esc(status))</span>")
        }

        if let priority = fm.priority {
            metaItems.append("<span class=\"fm-badge \(badgeClass(priority, from: priorityColors))\">Priority: \(esc(priority))</span>")
        }

        for dateEntry in fm.dates {
            let label = dateEntry.label == "date" ? "" : "\(esc(dateEntry.label)): "
            metaItems.append("<span class=\"fm-date\">\(label)\(esc(dateEntry.value))</span>")
        }

        if !fm.tags.isEmpty {
            metaItems.append(fm.tags.map { "<span class=\"fm-tag\">\(esc($0))</span>" }.joined(separator: " "))
        }

        if !metaItems.isEmpty {
            html += "  <div class=\"fm-meta\">\(metaItems.joined(separator: " "))</div>\n"
        }

        let otherFields = fm.fields
            .filter { !skipFields.contains($0.key) }
            .sorted {
                let (a, b) = (fieldOrder[$0.key.lowercased()] ?? 10, fieldOrder[$1.key.lowercased()] ?? 10)
                return a != b ? a < b : $0.key < $1.key
            }

        if !otherFields.isEmpty {
            html += "  <dl class=\"fm-fields\">\n"
            for field in otherFields {
                html += "    <dt>\(esc(formatFieldLabel(field.key)))</dt><dd>\(esc(formatValue(field.value)))</dd>\n"
            }
            html += "  </dl>\n"
        }

        html += "</div>\n"
        return html
    }

    private static let skipFields = Set(["title", "status", "priority", "tags"]).union(Frontmatter.dateFields)

    private static let statusColors: [String: String] = [
        "done": "badge-green", "complete": "badge-green", "completed": "badge-green",
        "closed": "badge-green", "resolved": "badge-green",
        "in progress": "badge-blue", "in-progress": "badge-blue",
        "active": "badge-blue", "doing": "badge-blue", "wip": "badge-blue",
        "blocked": "badge-red", "stuck": "badge-red",
        "review": "badge-yellow", "in review": "badge-yellow", "pending": "badge-yellow",
    ]

    private static let priorityColors: [String: String] = [
        "critical": "badge-red", "urgent": "badge-red", "p0": "badge-red",
        "high": "badge-orange", "p1": "badge-orange",
        "medium": "badge-yellow", "normal": "badge-yellow", "p2": "badge-yellow",
    ]

    private static func badgeClass(_ value: String, from map: [String: String]) -> String {
        map[value.lowercased()] ?? "badge-gray"
    }

    private static let fieldOrder: [String: Int] = [
        "id": 0,
        "type": 1, "kind": 1, "category": 1,
        "description": 2, "summary": 2, "prompt": 2,
        "assignee": 3, "author": 3, "owner": 3,
        "parent": 4, "project": 4, "epic": 4,
    ]

    private static func formatFieldLabel(_ key: String) -> String {
        key.replacingOccurrences(of: "[_-]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    private static func formatValue(_ value: Any) -> String {
        switch value {
        case let array as [Any]:
            return array.map { formatValue($0) }.joined(separator: ", ")
        case let dict as [String: Any]:
            return dict.map { "\($0.key): \(formatValue($0.value))" }.joined(separator: "; ")
        case let n as NSNumber where CFGetTypeID(n) == CFBooleanGetTypeID():
            return n.boolValue ? "Yes" : "No"
        default:
            return "\(value)"
        }
    }

}
