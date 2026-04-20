import AppKit
import ApplicationServices
import CoreGraphics
import WindowEngine

/// Builds a plain-text diagnostic report about the currently-focused
/// window. Used by the menubar "Debug → Copy Focused Window Info" item
/// to make "it doesn't work on <app>" reports cheap to triage.
enum FocusedWindowDiagnostics {
    @MainActor
    static func snapshot() -> String {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return "No frontmost application."
        }
        let bundleID = app.bundleIdentifier ?? "<unknown bundle id>"
        let appName = app.localizedName ?? "<unknown name>"
        let pid = app.processIdentifier

        guard let window = AXWindow.focusedWindow() else {
            return """
            app: \(appName)
            bundleID: \(bundleID)
            pid: \(pid)
            window: <none — AXWindow.focusedWindow() returned nil>
            nudged: \(ChromiumNudge.hasNudged(pid: pid))
            """
        }

        let title = window.stringAttribute(kAXTitleAttribute as String) ?? "<no title>"
        let role = window.stringAttribute(kAXRoleAttribute as String) ?? "<no role>"
        let subrole = window.stringAttribute(kAXSubroleAttribute as String) ?? "<none>"
        let frame = window.frame() ?? .zero
        let posSettable = window.isAttributeSettable(kAXPositionAttribute as String)
        let sizeSettable = window.isAttributeSettable(kAXSizeAttribute as String)

        return """
        app: \(appName)
        bundleID: \(bundleID)
        pid: \(pid)
        role: \(role)
        subrole: \(subrole)
        title: \"\(title)\"
        position: (\(Int(frame.origin.x)), \(Int(frame.origin.y)))
        size: (\(Int(frame.width)), \(Int(frame.height)))
        settable: {pos: \(posSettable), size: \(sizeSettable)}
        chromiumNudged: \(ChromiumNudge.hasNudged(pid: pid))
        """
    }
}
