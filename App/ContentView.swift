import SwiftUI

struct ContentView: View {
    @State private var extensionEnabled = false
    @State private var updaterActive = false

    var body: some View {
        VStack(spacing: 0) {
            // Hero: animated GIF showing preview in action
            AnimatedGIFView(name: "preview-demo")
                .frame(height: 280)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.clear, Color(nsColor: .windowBackgroundColor)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 40),
                    alignment: .bottom
                )

            VStack(spacing: 16) {
                // Title
                HStack(spacing: 10) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PreviewMD")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Quick Look for Markdown")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Status
                VStack(spacing: 8) {
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
                        title: updaterActive ? "Auto-updates active" : "Auto-updater not installed",
                        action: updaterActive ? ("Check Now", { checkForUpdateNow() }) : nil
                    )
                }

                Divider()

                // How to use — just the essentials
                HStack(spacing: 20) {
                    Tip(key: "Space", text: "Preview")
                    Tip(key: "⌥Space", text: "Full screen")
                    Tip(key: "↑↓", text: "Scroll")
                }

                Spacer()

                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .frame(width: 420, height: 520)
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

// MARK: - Animated GIF View

struct AnimatedGIFView: NSViewRepresentable {
    let name: String

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.animates = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.canDrawSubviewsIntoLayer = true
        if let url = Bundle.main.url(forResource: name, withExtension: "gif"),
           let image = NSImage(contentsOf: url) {
            imageView.image = image
        }
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {}
}

// MARK: - Components

struct StatusRow: View {
    let icon: String
    let color: Color
    let title: String
    var action: (String, () -> Void)?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
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

struct Tip: View {
    let key: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Text(key)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .cornerRadius(5)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
