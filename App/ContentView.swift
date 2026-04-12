import SwiftUI

struct ContentView: View {
    @State private var extensionEnabled = false
    @State private var updaterActive = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                Text("PreviewMD")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Quick Look previews for Markdown files")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)

            Divider().padding(.horizontal, 24)

            // Status
            VStack(spacing: 12) {
                StatusRow(
                    icon: extensionEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    color: extensionEnabled ? .green : .orange,
                    title: extensionEnabled ? "Extension enabled" : "Extension not detected",
                    action: ("Open Settings", {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                            NSWorkspace.shared.open(url)
                        }
                    })
                )

                StatusRow(
                    icon: updaterActive ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath.circle",
                    color: updaterActive ? .blue : .secondary,
                    title: updaterActive ? "Auto-updates active (every 5 min)" : "Auto-updater not installed",
                    action: updaterActive ? ("Check Now", {
                        checkForUpdateNow()
                    }) : nil
                )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)

            // Features
            VStack(alignment: .leading, spacing: 8) {
                Text("Features")
                    .font(.headline)
                    .padding(.bottom, 2)
                FeatureRow(text: "GFM tables, task lists, strikethrough, autolinks, admonitions")
                FeatureRow(text: "Mermaid diagrams rendered as SVG (local, no network)")
                FeatureRow(text: "Syntax highlighting for 14 languages")
                FeatureRow(text: "YAML frontmatter as structured metadata")
                FeatureRow(text: "Dark mode + keyboard scrolling")
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)

            // Keyboard shortcuts
            VStack(alignment: .leading, spacing: 8) {
                Tip(key: "Space", text: "Preview any .md file in Finder")
                Tip(key: "⌥ Space", text: "Full-screen preview")
                Tip(key: "↑↓ PgUp PgDn", text: "Scroll")
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)

            Spacer()

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .padding(.top, 24)
        .padding(.horizontal, 8)
        .frame(minWidth: 420, idealWidth: 480, minHeight: 520, idealHeight: 600)
        .onAppear {
            extensionEnabled = checkExtensionEnabled()
            updaterActive = checkUpdaterActive()
        }
    }

    private func checkExtensionEnabled() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        task.arguments = ["-m", "-i", "com.previewmd.PreviewMD.QuickLook"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.contains("com.previewmd.PreviewMD.QuickLook")
    }

    private func checkUpdaterActive() -> Bool {
        let plistPath = NSHomeDirectory() + "/Library/LaunchAgents/com.previewmd.updater.plist"
        return FileManager.default.fileExists(atPath: plistPath)
    }

    private func checkForUpdateNow() {
        let scriptPath = "/Applications/PreviewMD.app/Contents/Resources/check-update.sh"
        guard FileManager.default.fileExists(atPath: scriptPath) else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = [scriptPath]
        try? task.run()
    }
}

struct StatusRow: View {
    let icon: String
    let color: Color
    let title: String
    var action: (String, () -> Void)?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(title)
                .font(.callout)
            Spacer()
            if let (label, handler) = action {
                Button(label, action: handler)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

struct Tip: View {
    let key: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .cornerRadius(5)
                .fixedSize()
            Text(text)
                .font(.callout)
        }
    }
}
