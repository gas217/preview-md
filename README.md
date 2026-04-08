# PreviewMD

A macOS Quick Look extension for people who live in markdown.

Press spacebar on a `.md` file in Finder and see frontmatter rendered as a clean metadata block, GFM tables, task lists, syntax-highlighted code, and beautiful typography — all instant, all local, all signed.

## Features

- **Frontmatter-aware** — YAML frontmatter renders as structured metadata: title prominent, status/priority as colored badges, dates formatted, tags as pills
- **Full GFM** — Tables (with column alignment), task lists, strikethrough, autolinks, fenced code blocks, blockquotes
- **Syntax highlighting** — Swift, Python, JavaScript, TypeScript, Go, Rust, Ruby, Bash, SQL
- **Dark mode** — Automatic light/dark theme via `prefers-color-scheme`
- **Local-first** ��� Everything bundled, zero network calls, Content Security Policy enforced
- **Fast** — 10KB markdown renders in ~6ms

## Installation

### From Source

1. Clone the repository
2. Open `PreviewMD.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and Run (Cmd+R)
5. Open **System Settings > Privacy & Security > Extensions > Quick Look**
6. Enable **PreviewMD**
7. Select any `.md` file in Finder and press Space

### CLI Build (tests only)

```bash
xcodegen generate
xcodebuild -project PreviewMD.xcodeproj -scheme PreviewMD -configuration Debug -derivedDataPath build build-for-testing
xcrun xctest build/Build/Products/Debug/PreviewMDTests.xctest
```

Note: The Quick Look extension requires Xcode automatic signing to function. CLI ad-hoc signing doesn't provide the team identifiers needed for XPC extension loading.

## Supported File Types

`.md`, `.markdown`, `.mdown`, `.mkd`, `.mkdn`

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ (for building)

## Architecture

```
App/         — SwiftUI host app (setup instructions)
Extension/   — Quick Look extension (QLPreviewingController + WKWebView)
Shared/      — Rendering engine
  ├── MarkdownRenderer.swift   — Pipeline: file → frontmatter + markdown → HTML
  ├── FrontmatterParser.swift  — YAML extraction and structuring
  ├── HTMLConverter.swift      — swift-markdown AST → HTML (MarkupVisitor)
  └── HTMLTemplate.swift       — Full HTML document with embedded CSS/JS
Tests/       — 55 unit tests (rendering, security, edge cases, performance)
```

Dependencies: [swift-markdown](https://github.com/swiftlang/swift-markdown) (cmark-gfm), [Yams](https://github.com/jpsim/Yams)

## License

MIT
