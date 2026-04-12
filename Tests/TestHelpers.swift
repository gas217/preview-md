import Foundation

/// Extract the <article class="markdown-body">...</article> content from rendered HTML,
/// stripping <style> and <script> blocks to avoid CSS/JS substring collisions in test assertions.
func bodyHTML(_ html: String) -> String {
    guard let start = html.range(of: "<article class=\"markdown-body\">"),
          let end = html.range(of: "</article>") else { return html }
    return String(html[start.upperBound..<end.lowerBound])
}

/// Extract the <div class="frontmatter">...</div> block from rendered HTML.
func frontmatterHTML(_ html: String) -> String {
    guard let start = html.range(of: "<div class=\"frontmatter\">") else { return "" }
    // Find the closing </div> that precedes <article — scan forward from start
    let after = html[start.upperBound...]
    guard let divEnd = after.range(of: "</div>") else { return "" }
    return String(html[start.lowerBound...divEnd.upperBound])
}
