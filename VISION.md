# PreviewMD Vision

## The Problem

Markdown is everywhere — task systems, knowledge bases, project docs, README files, personal notes. On macOS, pressing spacebar on a markdown file in Finder gives you raw text or a mediocre render from an unsigned extension that breaks every OS update.

The existing landscape:
- **PreviewMDdown** (sbarex) — most capable but unsigned, getting removed from Homebrew Sept 2026, phones home to CDNs, breaks on macOS updates, persistent permission dialogs
- **PreviewMarkdown** — App Store, stable, but very basic
- **Markdown Preview** (Anybox) — $2.99, polished, but no frontmatter support
- **Flux Markdown** — new, promising, but unproven

None of them understand that markdown isn't just a document format — it's a workspace format. When your entire task system, knowledge base, and project docs are markdown files with YAML frontmatter, Quick Look should show you something useful, not raw `---` delimiters and key-value pairs.

## The Product

PreviewMD is a Quick Look extension for people who live in markdown.

Press spacebar on a markdown file and see:
- Frontmatter rendered as a clean header block — title prominent, status as a colored badge, dates formatted, priority visible
- Content rendered beautifully — GFM tables, task lists, syntax-highlighted code
- Everything instant, everything local, everything signed

## Who It's For

- Developers who use markdown daily
- People running markdown-based task/knowledge systems (Obsidian, Reeve, Zettelkasten)
- Anyone tired of fighting Gatekeeper to preview a text file

## Core Differentiators

1. **Frontmatter-aware** — YAML frontmatter renders as a clean metadata block (title, status, priority, dates as pills/badges), not raw code
2. **Signed and notarized** — proper code signing, no Gatekeeper fights, potential App Store distribution
3. **Local-first** — everything bundled, zero network calls, no CDN dependencies
4. **Fast** — instant rendering, no lag on large files or workspaces
5. **Feature-rich** — admonitions, language labels, lazy images, keyboard scrolling
6. **Open source** — MIT licensed. The community can fix what one developer can't.

## Feature Scope

### V1 (shipped)
- Quick Look preview of `.md` files with proper rendering
- CommonMark + GFM (tables, task lists, strikethrough, autolinks)
- YAML frontmatter rendered as structured metadata block
- Syntax highlighting for 14 languages with language labels
- GitHub-style admonitions ([!NOTE], [!WARNING], etc.)
- Properly signed and notarized
- Dark mode support with print stylesheet
- Keyboard scrolling (arrows, Space, Page Up/Down)

### V2
- Mermaid diagram rendering (bundled, not CDN)
- Math rendering (KaTeX bundled, not MathJax CDN)
- Thumbnail generation for Finder
- Custom CSS themes

### Not In Scope
- Editing (this is a previewer, not an editor)
- Wikilinks / Obsidian compatibility (maybe later)
- Non-markdown formats

## Tech Stack

- **Language:** Swift
- **Markdown parsing:** cmark-gfm (C library, same as GitHub uses)
- **Rendering:** HTML/CSS in WKWebView
- **Build:** Xcode, Swift Package Manager where possible
- **Distribution:** Direct download + Homebrew cask, later App Store
- **Target:** macOS 14+ (Sonoma and later)

## Project Layout

```
App/          — SwiftUI host app (keyboard shortcut tips)
Extension/    — Quick Look extension (QLPreviewingController + WKWebView)
Shared/       — Rendering engine (~1050 lines)
  MarkdownRenderer   — Pipeline: file → frontmatter + markdown → HTML
  FrontmatterParser  — YAML extraction and structuring
  HTMLConverter      — swift-markdown AST → HTML (MarkupVisitor)
  HTMLTemplate       — Full HTML document with embedded CSS/JS
  HTMLUtils          — HTML escaping
Tests/        — 78 unit tests
```

## Architecture Notes

- Quick Look extensions use the modern `QLPreviewingController` API (not the deprecated qlgenerator plugin)
- The extension receives a file URL, reads markdown, converts to HTML, displays in WKWebView
- Frontmatter parsing: split on `---` delimiters, parse YAML, render as styled HTML block above the content
- All rendering is local — network.client entitlement is for WebKit only, no actual network calls
- CSS and JS are embedded as string constants — no bundle resource loading needed

## Success Criteria

- Replaces PreviewMDdown on ag's machines without losing functionality
- Passes notarization, installs cleanly, no Gatekeeper prompts
- Renders Reeve workspace files (frontmatter + content) beautifully
- Fast enough that previewing feels instant (<100ms for typical files)
- Open sourced with enough polish that others adopt it
