import ApplicationServices
import Foundation

public final class PermissionsCoordinator {
    public init() {}

    public func isTrusted() -> Bool {
        AccessibilityTrust.isTrusted(prompt: false)
    }

    public func promptForTrust() {
        _ = AccessibilityTrust.isTrusted(prompt: true)
    }

    public func openAccessibilitySettings() {
        AccessibilityTrust.openSystemSettings()
    }
}
