import Foundation
import Yams

struct Frontmatter {
    let fields: [(key: String, value: Any)]
    let title: String?
    let status: String?
    let priority: String?
    let dates: [(label: String, value: String)]
    let tags: [String]
    let raw: [String: Any]

    private static let dateFields: Set<String> = [
        "date", "created", "modified", "updated", "due", "deadline",
        "created_at", "updated_at", "published", "completed"
    ]

    init(raw: [String: Any]) {
        self.raw = raw
        self.fields = raw.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
        self.title = raw["title"] as? String
        self.status = raw["status"] as? String
        self.priority = raw["priority"] as? String

        // Collect all date fields
        var foundDates: [(label: String, value: String)] = []
        for key in raw.keys.sorted() {
            guard Self.dateFields.contains(key) else { continue }
            if let formatted = Self.formatDateValue(raw[key]) {
                foundDates.append((label: key, value: formatted))
            }
        }
        self.dates = foundDates

        if let tagsArray = raw["tags"] as? [String] {
            self.tags = tagsArray
        } else if let tagString = raw["tags"] as? String {
            self.tags = tagString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            self.tags = []
        }
    }

    /// Back-compat: first date value
    var date: String? {
        dates.first?.value
    }

    var isEmpty: Bool {
        raw.isEmpty
    }

    private static func formatDateValue(_ value: Any?) -> String? {
        guard let value = value else { return nil }
        if let date = value as? Date {
            // Yams parses date-only values as midnight UTC — format in UTC to avoid day shift
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.string(from: date)
        }
        if let string = value as? String, !string.isEmpty {
            // Try to parse ISO date strings for nicer formatting
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate]
            isoFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = isoFormatter.date(from: string) {
                let display = DateFormatter()
                display.dateStyle = .medium
                display.timeZone = TimeZone(identifier: "UTC")
                return display.string(from: date)
            }
            // Try datetime — use local TZ since time is explicit
            isoFormatter.formatOptions = [.withInternetDateTime]
            isoFormatter.timeZone = TimeZone.current
            if let date = isoFormatter.date(from: string) {
                let display = DateFormatter()
                display.dateStyle = .medium
                display.timeStyle = .short
                return display.string(from: date)
            }
            return string
        }
        return nil
    }
}

struct ParsedMarkdown {
    let frontmatter: Frontmatter?
    let content: String
}

enum FrontmatterParser {
    static func parse(_ input: String) -> ParsedMarkdown {
        // Strip UTF-8 BOM and normalize line endings
        var cleaned = input.hasPrefix("\u{FEFF}") ? String(input.dropFirst()) : input
        cleaned = cleaned.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.hasPrefix("---") else {
            return ParsedMarkdown(frontmatter: nil, content: cleaned)
        }

        let lines = cleaned.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return ParsedMarkdown(frontmatter: nil, content: cleaned)
        }

        var closingIndex: Int?
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let endIndex = closingIndex, endIndex > 1 else {
            return ParsedMarkdown(frontmatter: nil, content: input)
        }

        let yamlLines = lines[1..<endIndex]
        let yamlString = yamlLines.joined(separator: "\n")
        let contentLines = lines[(endIndex + 1)...]
        let content = contentLines.joined(separator: "\n")

        do {
            if let yaml = try Yams.load(yaml: yamlString) as? [String: Any] {
                let frontmatter = Frontmatter(raw: yaml)
                return ParsedMarkdown(frontmatter: frontmatter.isEmpty ? nil : frontmatter, content: content)
            }
        } catch {
            // Malformed YAML — treat the whole thing as content
        }

        return ParsedMarkdown(frontmatter: nil, content: input)
    }
}
