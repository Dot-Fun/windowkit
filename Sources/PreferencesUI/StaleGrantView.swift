import Combine
import PermissionsCoordinator
import SwiftUI

public struct StaleGrantView: View {
    @State private var state: TrustState = AccessibilityTrust.currentState()
    @State private var cancellable: AnyCancellable?

    public var onRestored: (() -> Void)?

    public init(onRestored: (() -> Void)? = nil) {
        self.onRestored = onRestored
    }

    public var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .foregroundStyle(.orange)

            Text("Accessibility grant is out of date")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text("WindowKit appears enabled in Accessibility, but the grant no longer matches this build. Hotkeys fire but can't reach your windows.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Label("Open System Settings → Privacy & Security → Accessibility.", systemImage: "1.circle.fill")
                Label("Select WindowKit and click the − button to remove it.", systemImage: "2.circle.fill")
                Label("Drag WindowKit.app back into the list and toggle it on.", systemImage: "3.circle.fill")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                Button {
                    AccessibilityTrust.openSystemSettings()
                } label: {
                    Label("Open System Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Button("Recheck") {
                    state = AccessibilityTrust.currentState()
                }
                .controlSize(.regular)
            }

            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                Text(statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .frame(width: 460)
        .onAppear {
            cancellable = AccessibilityTrust.statePublisher(interval: 2.0)
                .receive(on: RunLoop.main)
                .sink { newState in
                    state = newState
                    if newState == .functional {
                        onRestored?()
                    }
                }
        }
        .onDisappear { cancellable = nil }
    }

    private var statusIcon: String {
        switch state {
        case .functional: return "checkmark.circle.fill"
        case .stale: return "exclamationmark.triangle.fill"
        case .denied: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch state {
        case .functional: return .green
        case .stale: return .orange
        case .denied: return .red
        }
    }

    private var statusText: String {
        switch state {
        case .functional: return "Accessibility working"
        case .stale: return "Waiting for re-grant…"
        case .denied: return "Accessibility revoked"
        }
    }
}
