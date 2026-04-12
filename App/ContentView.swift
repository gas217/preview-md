import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("PreviewMD")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Quick Look previews for Markdown files")
                .font(.title3)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 14) {
                Tip(key: "Space", text: "Preview any .md file in Finder")
                Tip(key: "⌥ Space", text: "Full-screen preview")
                Tip(key: "↑↓", text: "Scroll with arrow keys")
            }
            .padding(.horizontal, 20)

            Button("Open Quick Look Extensions Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(minWidth: 380, idealWidth: 440, minHeight: 340, idealHeight: 420)
    }
}

struct Tip: View {
    let key: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(size: 12, weight: .medium, design: .rounded))
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
