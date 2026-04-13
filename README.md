# PreviewMD

A macOS Quick Look extension for people who live in markdown.

Press spacebar on a `.md` file in Finder and see frontmatter rendered as a clean metadata block, GFM tables, task lists, syntax-highlighted code, mermaid diagrams, math equations, and beautiful typography — all instant, all local, all signed.

## Install

```bash
curl -sSL https://github.com/gas217/preview-md/releases/latest/download/install.sh | sh
```

This installs PreviewMD to `/Applications`, registers the Quick Look extension, and sets up automatic updates.

## Features

- **Frontmatter-aware** — YAML frontmatter renders as structured metadata: title prominent, status/priority as colored badges, dates formatted, tags as pills
- **Full GFM** — Tables (with column alignment), task lists, strikethrough, autolinks, fenced code blocks, blockquotes, admonitions (`[!NOTE]`, `[!WARNING]`, etc.)
- **Mermaid diagrams** — ` ```mermaid ` blocks render as SVG locally. No CDN, no `unsafe-eval` — the bundle is patched and ships under the same strict CSP as the rest of the preview
- **Math/LaTeX** — `$$...$$`, `$...$`, `\(...\)`, `\[...\]` rendered via bundled KaTeX with inlined fonts. Smart detection avoids false positives with dollar amounts
- **Syntax highlighting** — Swift, Python, JavaScript, TypeScript, Go, Rust, Ruby, C, C++, Java, Kotlin, PHP, Bash, SQL
- **Dark mode** — Automatic light/dark theme via `prefers-color-scheme`
- **Keyboard scrolling** — Arrow keys, Space, Page Up/Down. Option+Space for full-screen preview
- **Auto-updates** — LaunchAgent checks GitHub Releases every 5 min via ETag. Downloads only when a new version is available
- **Local-first** — Everything bundled, zero network calls (except update checks), Content Security Policy enforced
- **Fast** — 10KB markdown renders in ~6ms

## Supported File Types

`.md`, `.markdown`, `.mdown`, `.mkd`, `.mkdn`

## Auto-Updates

The install script sets up a LaunchAgent that checks for new releases every 5 minutes. It uses HTTP ETag headers — when no update is available, the check costs one HEAD request (~50ms).

```bash
launchctl list | grep previewmd    # check updater status
cat ~/.previewmd-etag              # last known release ETag
```

To disable:
```bash
launchctl unload ~/Library/LaunchAgents/com.previewmd.updater.plist
```

## Build from Source

```bash
make deploy    # build, sign, install to /Applications
make test      # run 103 unit tests
make release   # notarize, staple, publish to GitHub Releases
make clean     # remove build artifacts
```

Requires macOS 14+, Xcode 15+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Uninstall

```bash
sh /Applications/PreviewMD.app/Contents/Resources/uninstall.sh
```

Or manually:
```bash
rm -rf /Applications/PreviewMD.app
launchctl unload ~/Library/LaunchAgents/com.previewmd.updater.plist
rm -f ~/Library/LaunchAgents/com.previewmd.updater.plist ~/.previewmd-etag
qlmanage -r
```

## License

MIT
