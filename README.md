# PreviewMD

A macOS Quick Look extension for people who live in markdown.

Press spacebar on a `.md` file in Finder and see frontmatter rendered as a clean metadata block, GFM tables, task lists, syntax-highlighted code, and beautiful typography — all instant, all local, all signed.

## Install

```bash
curl -sSL github.com/gas217/preview-md/releases/latest/download/install.sh | sh
```

## Features

- **Frontmatter-aware** — YAML frontmatter renders as structured metadata: title prominent, status/priority as colored badges, dates formatted, tags as pills
- **Full GFM** — Tables (with column alignment), task lists, strikethrough, autolinks, fenced code blocks, blockquotes, admonitions (`[!NOTE]`, `[!WARNING]`, etc.)
- **Mermaid diagrams** — ` ```mermaid ` blocks render as SVG locally. No CDN, no `unsafe-eval` — the bundle is patched and ships under the same strict CSP as the rest of the preview
- **Math/LaTeX** — `$$...$$`, `\(...\)`, `\[...\]` rendered via bundled KaTeX with inlined fonts. CSP-safe, zero network
- **Syntax highlighting** — Swift, Python, JavaScript, TypeScript, Go, Rust, Ruby, C, C++, Java, Kotlin, PHP, Bash, SQL
- **Dark mode** — Automatic light/dark theme via `prefers-color-scheme`
- **Keyboard scrolling** — Arrow keys, Space, Page Up/Down. Option+Space for full-screen preview
- **Local-first** — Everything bundled, zero network calls, Content Security Policy enforced
- **Fast** — 10KB markdown renders in ~6ms

## Supported File Types

`.md`, `.markdown`, `.mdown`, `.mkd`, `.mkdn`

## Build from Source

```bash
make deploy    # build, sign with Developer ID, install to /Applications
make test      # run unit tests
make clean     # remove build artifacts
```

Requires macOS 14+, Xcode 15+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Architecture

```
App/         — SwiftUI host app (keyboard shortcut tips)
Extension/   — Quick Look extension (QLPreviewingController + WKWebView)
Shared/      — Rendering engine
  MarkdownRenderer.swift   — Pipeline: file -> frontmatter + markdown -> HTML
  FrontmatterParser.swift  — YAML extraction and structuring
  HTMLConverter.swift       — swift-markdown AST -> HTML (MarkupVisitor)
  HTMLTemplate.swift        — Full HTML document with embedded CSS/JS
Tests/       — Unit tests (rendering, security, edge cases, performance)
```

Dependencies: [swift-markdown](https://github.com/swiftlang/swift-markdown) (cmark-gfm), [Yams](https://github.com/jpsim/Yams)

## License

MIT
