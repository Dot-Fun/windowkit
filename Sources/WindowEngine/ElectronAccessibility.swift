import ApplicationServices
import Foundation

/// Wakes a Chromium/Electron app's accessibility tree so its window becomes
/// discoverable, using `AXManualAccessibility`.
///
/// Chromium-based apps (Chrome, Discord, Cursor, VS Code, Slack) build only a
/// minimal AX tree by default, so `AXWindow.focusedWindow()` can come back
/// empty. The historical trigger for "build the full tree" was
/// `AXEnhancedUserInterface`, but that attribute is reserved for VoiceOver and
/// *breaks window positioning* — setting it permanently is what kept Discord
/// from moving. `AXManualAccessibility` was added by Electron/Chromium for
/// exactly this case: it wakes the tree with no positioning side-effect, so
/// it's safe to set once and leave on.
///
/// We track which pids we've woken so each app gets at most one wake per
/// WindowKit launch.
@MainActor
public enum ElectronAccessibility {
    private static var wokenPids: Set<pid_t> = []

    /// Enable the full a11y tree on the given app. Returns true if we just
    /// woke it (pid not seen before); false if already woken.
    @discardableResult
    public static func wake(pid: pid_t) -> Bool {
        guard !wokenPids.contains(pid) else { return false }
        wokenPids.insert(pid)
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(app, AXAttr.manualAccessibility as CFString, kCFBooleanTrue)
        return true
    }

    public static func hasWoken(pid: pid_t) -> Bool {
        wokenPids.contains(pid)
    }
}
