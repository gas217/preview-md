import SwiftUI

struct ContentView: View {
    @State private var extensionEnabled = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("PreviewMD")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Quick Look previews for Markdown files")
                .font(.title3)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 16) {
                Text("Setup")
                    .font(.headline)

                SetupStep(
                    number: 1,
                    title: "Enable the extension",
                    description: "Open System Settings > Privacy & Security > Extensions > Quick Look, then enable PreviewMD."
                )

                SetupStep(
                    number: 2,
                    title: "Preview markdown files",
                    description: "Select any .md file in Finder and press Space to preview it."
                )

                SetupStep(
                    number: 3,
                    title: "That's it",
                    description: "Frontmatter, tables, code blocks, and task lists are all rendered automatically."
                )
            }
            .padding(.horizontal, 20)

            Button("Open Quick Look Extensions Settings") {
                openExtensionSettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 500, height: 580)
    }

    private func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct SetupStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
