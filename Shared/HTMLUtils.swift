import Foundation

enum HTMLUtils {
    static func escapeHTML(_ string: String) -> String {
        // Fast path: skip strings with no special chars (common case)
        let needsEscape = string.utf8.contains { $0 == 0x26 || $0 == 0x3C || $0 == 0x3E || $0 == 0x22 || $0 == 0x27 }
        guard needsEscape else { return string }

        var result = ""
        result.reserveCapacity(string.count + string.count / 8)
        for c in string.unicodeScalars {
            switch c {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            case "'": result += "&#39;"
            default: result.unicodeScalars.append(c)
            }
        }
        return result
    }
}
