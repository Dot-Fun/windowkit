import ApplicationServices
import Foundation

public final class PermissionsCoordinator {
    public init() {}

    public func isTrusted() -> Bool {
        // TODO: implement in ui-dev task using AXIsProcessTrustedWithOptions.
        return false
    }

    public func promptForTrust() {
        // TODO: implement in ui-dev task.
    }

    public func openAccessibilitySettings() {
        // TODO: implement in ui-dev task.
    }
}
