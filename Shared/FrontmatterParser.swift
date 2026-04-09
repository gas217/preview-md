import Foundation
import Yams

struct Frontmatter {
    let fields: [(key: String, value: Any)]
    let title: String?
    let status: String?
    let priority: String?
    let dates: [(label: String, value: String)]
    let tags: [String]

    static let dateFields: Set<String> = [
        "date", "created", "modified", "updated", "due", "deadline",
        "created_at", "updated_at", "published", "completed"
    ]

    init(raw: [String: Any]) {
        self.fields = raw.map { ($0.key, $0.value) }
        self.title = raw["title"] as? String
        self.status = raw["status"] as? String
        self.priority = raw["priority"] as? String

        self.dates = raw.keys
            .filter { Self.dateFields.contains($0) }
            .sorted()
            .compactMap { key in Self.formatDateValue(raw[key]).map { (label: key, value: $0) } }

        switch raw["tags"] {
        case let array as [String]: self.tags = array
        case let string as String: self.tags = string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        default: self.tags = []
        }
    }

    var isEmpty: Bool {
        fields.isEmpty
    }

    private static let utcDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let isoDateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let isoDateTime: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone.current
        return f
    }()

    private static func formatDateValue(_ value: Any?) -> String? {
        switch value {
        case let date as Date:
            return utcDateFormatter.string(from: date)
        case let string as String where !string.isEmpty:
            return isoDateOnly.date(from: string).map { utcDateFormatter.string(from: $0) }
                ?? isoDateTime.date(from: string).map { dateTimeFormatter.string(from: $0) }
                ?? string
        default:
            return nil
        }
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

        guard cleaned.hasPrefix("---\n") else {
            return ParsedMarkdown(frontmatter: nil, content: cleaned)
        }

        let lines = cleaned.components(separatedBy: "\n")
        guard let endIndex = (1..<lines.count).first(where: { lines[$0].trimmingCharacters(in: .whitespaces) == "---" }),
              endIndex > 1 else {
            return ParsedMarkdown(frontmatter: nil, content: cleaned)
        }

        let yamlString = lines[1..<endIndex].joined(separator: "\n")
        let content = lines[(endIndex + 1)...].joined(separator: "\n")

        do {
            if let yaml = try Yams.load(yaml: yamlString) as? [String: Any] {
                let fm = Frontmatter(raw: yaml)
                return ParsedMarkdown(frontmatter: fm.isEmpty ? nil : fm, content: content)
            }
        } catch {}

        return ParsedMarkdown(frontmatter: nil, content: cleaned)
    }
}
