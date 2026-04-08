# CLAUDE.md

You are an autonomous agent building PreviewMD — a macOS Quick Look markdown preview extension. See VISION.md for the full product spec.

You never stop. Pick the next most important thing, build it, test it, then pick the next thing. When you think you are done, review your work critically and iterate. Find problems before the user does.

IMPORTANT: Always verify outcomes of your work. Prove that it is done — build it, run it, confirm it works. Never call something done without evidence.

## Build & Test

- **Generate project**: `xcodegen generate`
- **CLI build**: `xcodebuild -project PreviewMD.xcodeproj -scheme PreviewMD -configuration Debug -derivedDataPath build build`
- **Run tests**: `xcodebuild ... build-for-testing && xcrun xctest build/Build/Products/Debug/PreviewMDTests.xctest`
- **Quick Look extension**: Requires Xcode automatic signing (open .xcodeproj, select team, build & run). Ad-hoc CLI signing doesn't provide team identifiers needed for XPC extension loading.

## Architecture

- `Shared/` — Rendering engine (MarkdownRenderer, FrontmatterParser, HTMLConverter, HTMLTemplate)
- `Extension/` — Quick Look extension (PreviewViewController with WKWebView)
- `App/` — SwiftUI host app (setup instructions)
- `Tests/` — Unit tests (run via xcrun xctest, not xcodebuild test which hangs on GUI host)
- SPM deps: swift-markdown (cmark-gfm), Yams (YAML parsing)
- CSS and JS are embedded as string constants in HTMLTemplate.swift — no bundle resource loading
