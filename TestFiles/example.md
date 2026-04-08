---
title: Weekly Status Report
status: in progress
priority: high
date: 2025-01-15
tags:
  - engineering
  - sprint-42
assignee: Alice
project: PreviewMD
---

# Weekly Status Report

## Summary

This week we shipped the **Quick Look extension** for markdown files. The extension renders frontmatter as a clean metadata block and supports full GFM.

## Completed Tasks

- [x] Set up Xcode project with app + extension targets
- [x] Integrate cmark-gfm via swift-markdown
- [x] Implement YAML frontmatter parsing
- [x] Build HTML/CSS theme with dark mode
- [x] Add syntax highlighting for code blocks
- [ ] Performance optimization for large files
- [ ] App Store submission

## Code Example

```swift
func render(_ input: String) -> String {
    let parsed = FrontmatterParser.parse(input)
    let document = Document(parsing: parsed.content)
    var converter = HTMLConverter()
    let contentHTML = converter.visit(document)
    return HTMLTemplate.build(
        frontmatter: renderFrontmatter(parsed.frontmatter),
        content: contentHTML
    )
}
```

## Performance Results

| File Size | Parse Time | Render Time | Total |
|-----------|-----------|-------------|-------|
| 1 KB      | 0.2 ms    | 0.5 ms      | 0.7 ms |
| 10 KB     | 1.1 ms    | 2.3 ms      | 3.4 ms |
| 100 KB    | 8.5 ms    | 15.2 ms     | 23.7 ms |

## Architecture

> The extension uses the modern `QLPreviewingController` API with a `WKWebView` for rendering. All resources are bundled — **zero network calls**.

### Key Design Decisions

1. **swift-markdown** for parsing — Apple's official library, wraps cmark-gfm
2. **Yams** for YAML frontmatter — battle-tested Swift YAML parser
3. **WKWebView** for rendering — hardware-accelerated, supports CSS/JS
4. Inline everything — CSS, JS, and HTML in a single string

## Links

- [swift-markdown](https://github.com/swiftlang/swift-markdown)
- [Yams](https://github.com/jpsim/Yams)

---

*Last updated: 2025-01-15*
