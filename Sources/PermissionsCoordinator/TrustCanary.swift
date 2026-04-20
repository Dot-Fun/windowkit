import ApplicationServices
import Foundation

/// Detects whether the Accessibility grant is *functionally* working, not
/// just whether `AXIsProcessTrusted` returns true.
///
/// Why: ad-hoc-signed rebuilds change the binary's code identity. macOS's
/// TCC database keeps the old grant with the toggle showing ON in System
/// Settings, but the kernel rejects real AX calls for the new identity.
/// `AXIsProcessTrusted` can still report `true` in that state, so we probe
/// with an actual AX call to detect the stale-grant case.
public enum TrustCanary {
    public static func isFunctional() -> Bool {
        guard AccessibilityTrust.isTrusted(prompt: false) else { return false }
        let system = AXUIElementCreateSystemWide()
        var appRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            system, kAXFocusedApplicationAttribute as CFString, &appRef
        )
        // .success → trusted and something was focused.
        // .noValue → trusted but nothing focused right now (still healthy).
        // .cannotComplete / .apiDisabled → stale grant; real calls blocked.
        return err == .success || err == .noValue
    }
}
