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
    /// Upper bound on how long the probe waits for the focused app to answer.
    /// Without it, a hung focused app stalls the probe for the default ~6s on
    /// whatever thread `isFunctional()` runs on.
    private static let probeTimeout: Float = 1.0

    public static func isFunctional() -> Bool {
        guard AccessibilityTrust.isTrusted(prompt: false) else { return false }
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, probeTimeout)
        var appRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            system, kAXFocusedApplicationAttribute as CFString, &appRef
        )
        return isHealthy(probeError: err)
    }

    /// Classify the result of the focused-app AX probe.
    ///
    /// Only `kAXErrorAPIDisabled` proves the grant is non-functional — it is
    /// macOS's signal that Accessibility is not actually enabled for this
    /// process (the stale ad-hoc-rebuild case, where `AXIsProcessTrusted`
    /// still reports `true`).
    ///
    /// Everything else means the grant is fine. In particular
    /// `kAXErrorCannotComplete` means "messaging failed … or the application
    /// is busy or unresponsive" — a property of the *focused app*, not of our
    /// permission. A busy Chromium/Electron app (Discord mid-call) returns it
    /// constantly; treating that as a stale grant produced false warnings.
    static func isHealthy(probeError err: AXError) -> Bool {
        err != .apiDisabled
    }
}
