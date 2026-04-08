---
id: task-2025-0142
title: Implement markdown Quick Look extension
status: in progress
priority: high
created: 2025-01-10
modified: 2025-01-15
parent: project-preview-md
tags:
  - engineering
  - macos
  - quick-look
assignee: ag
prompt: Build a macOS Quick Look extension that renders markdown with frontmatter support
---

# Implement markdown Quick Look extension

## Objective

Build a native macOS Quick Look extension that renders `.md` files with proper frontmatter support, GFM rendering, and syntax highlighting.

## Acceptance Criteria

- [x] Extension activates for `.md` files in Finder Quick Look
- [x] YAML frontmatter renders as structured metadata block
- [x] GFM tables, task lists, strikethrough work
- [x] Code blocks have syntax highlighting
- [x] Dark mode supported
- [ ] Signed and notarized for distribution
- [ ] Performance under 100ms for typical files

## Notes

> This replaces the current PreviewMarkdown extension which doesn't understand frontmatter and renders `---` delimiters as raw text.

### Dependencies

| Dependency | Version | Purpose |
|:-----------|:-------:|--------:|
| swift-markdown | 0.7.3 | Markdown parsing (cmark-gfm) |
| Yams | 5.4.0 | YAML frontmatter |
| macOS SDK | 14.0+ | QLPreviewingController API |

### Implementation Notes

```swift
// The rendering pipeline
let parsed = FrontmatterParser.parse(content)
let document = Document(parsing: parsed.content)
var converter = HTMLConverter()
let html = converter.visit(document)
```

The key insight is embedding all CSS and JS inline in the HTML string — no bundle resource loading needed, which makes the extension more reliable across different sandboxing contexts.

## Log

- 2025-01-10: Created task, started research
- 2025-01-12: Scaffolded Xcode project with XcodeGen
- 2025-01-15: V1 complete, 55 tests passing
