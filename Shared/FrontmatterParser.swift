import Foundation
import Yams

struct Frontmatter {
    let fields: [(key: String, value: Any)]
    let title: String?
    let status: String?
    let priority: String?
    let date: String?
    let tags: [String]
    let raw: [String: Any]

    init(raw: [String: Any]) {
        self.raw = raw
        self.fields = raw.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
        self.title = raw["title"] as? String
        self.status = raw["status"] as? String
        self.priority = raw["priority"] as? String

        if let dateVal = raw["date"] as? String {
            self.date = dateVal
        } else if let dateVal = raw["date"] as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            self.date = formatter.string(from: dateVal)
        } else {
            self.date = nil
        }

        if let tagsArray = raw["tags"] as? [String] {
            self.tags = tagsArray
        } else if let tagString = raw["tags"] as? String {
            self.tags = tagString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            self.tags = []
        }
    }

    var isEmpty: Bool {
        raw.isEmpty
    }
}

struct ParsedMarkdown {
    let frontmatter: Frontmatter?
    let content: String
}

enum FrontmatterParser {
    static func parse(_ input: String) -> ParsedMarkdown {
        // Strip UTF-8 BOM if present
        let cleaned = input.hasPrefix("\u{FEFF}") ? String(input.dropFirst()) : input
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
