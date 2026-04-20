import AppKit
import SwiftUI
import UpdateChecker

public struct AboutView: View {
    @ObservedObject private var updateChecker: UpdateChecker

    public init(updateChecker: UpdateChecker) {
        self.updateChecker = updateChecker
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }

    public var body: some View {
        VStack(spacing: 14) {
            DotfunLogo(height: 36)

            Text("WindowKit")
                .font(.title.weight(.semibold))

            Text("Version \(version)")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let update = updateChecker.availableUpdate {
                Button("Update available — \(update.tagName)") {
                    NSWorkspace.shared.open(update.htmlURL)
                }
                .buttonStyle(.link)
            } else {
                Text("Up to date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(spacing: 6) {
                Text("A native macOS window manager by dotfun.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                Text("Spatial 3×3 grid hotkeys with multi-tap cycling.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 4)

            Text("Licensed under the Apache License 2.0.\nProvided “as is”, without warranty of any kind.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 420)
    }
}
