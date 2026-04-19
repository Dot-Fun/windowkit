import Combine
import PermissionsCoordinator
import SwiftUI

public struct OnboardingView: View {
    @State private var isTrusted: Bool = AccessibilityTrust.isTrusted(prompt: false)
    @State private var cancellable: AnyCancellable?

    public var onTrusted: (() -> Void)?

    public init(onTrusted: (() -> Void)? = nil) {
        self.onTrusted = onTrusted
    }

    public var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.3.group")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(.tint)

            Text("Welcome to WindowKit")
                .font(.title2.weight(.semibold))

            Text("WindowKit needs Accessibility access to move and resize windows on your behalf. macOS requires this for any app that controls other apps' windows.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Button {
                    AccessibilityTrust.openSystemSettings()
                    _ = AccessibilityTrust.isTrusted(prompt: true)
                } label: {
                    Label("Open System Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Button("Recheck") {
                    isTrusted = AccessibilityTrust.isTrusted(prompt: false)
                }
                .controlSize(.regular)
            }

            HStack(spacing: 6) {
                Image(systemName: isTrusted ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(isTrusted ? .green : .secondary)
                Text(isTrusted ? "Accessibility granted" : "Waiting for permission…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .frame(width: 420)
        .onAppear {
            cancellable = AccessibilityTrust.trustPublisher(interval: 1.0)
                .receive(on: RunLoop.main)
                .sink { trusted in
                    isTrusted = trusted
                    if trusted { onTrusted?() }
                }
        }
        .onDisappear { cancellable?.cancel() }
    }
}
