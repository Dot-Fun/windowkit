import ApplicationServices
import Foundation

/// One-shot `AXEnhancedUserInterface` nudge for Chromium/Electron apps.
///
/// Chromium-based apps (Chrome, Discord, Cursor, VSCode, Slack) often build
/// a minimal AX tree by default, so the first `setFrame` request lands on a
/// stub and does nothing. Setting `AXEnhancedUserInterface = true` on the
/// application element causes Chromium to build a full AX tree with
/// settable position/size attributes — after that, frame changes work.
///
/// We only enable the attribute; we never disable it. Some Chromium apps
/// reportedly animate less smoothly while it's on, but it's the same
/// attribute VoiceOver sets, and nearly all window-manager users have it
/// on already. We track which pids we've nudged so each app gets at most
/// one nudge per WindowKit launch.
@MainActor
public enum ChromiumNudge {
    private static var nudgedPids: Set<pid_t> = []

    /// Enable enhanced AX on the given app. Returns true if the nudge was
    /// just applied (i.e. this pid hadn't been nudged yet); false if we'd
    /// already touched it.
    @discardableResult
    public static func nudge(pid: pid_t) -> Bool {
        guard !nudgedPids.contains(pid) else { return false }
        nudgedPids.insert(pid)
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
        return true
    }

    public static func hasNudged(pid: pid_t) -> Bool {
        nudgedPids.contains(pid)
    }
}
