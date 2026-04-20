import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Thin wrapper around an `AXUIElement` representing a window.
public struct AXWindow: Equatable {
    let element: AXUIElement

    init(element: AXUIElement) {
        self.element = element
    }

    public static func == (lhs: AXWindow, rhs: AXWindow) -> Bool {
        CFEqual(lhs.element, rhs.element)
    }

    /// Resolve the focused window of the frontmost application.
    ///
    /// Uses a multi-tier strategy because Chromium/Electron apps (Chrome,
    /// Discord, Cursor, VSCode, Slack) frequently report focus on a deep
    /// `AXWebArea` descendant rather than on the `AXWindow`, which makes
    /// the naive `kAXFocusedWindowAttribute` path return something that
    /// is not a window (or returns nothing at all).
    ///
    /// Order: focused → main → first-in-list. Role-checked at each step.
    public static func focusedWindow() -> AXWindow? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            return nil
        }
        let app = AXUIElementCreateApplication(pid)

        if let win = copyWindow(from: app, attribute: kAXFocusedWindowAttribute as String) {
            return win
        }
        if let win = copyWindow(from: app, attribute: kAXMainWindowAttribute as String) {
            return win
        }
        return firstWindow(from: app)
    }

    /// Process ID of the app owning this window. Used to target the
    /// Chromium enhanced-UI nudge at the right application.
    public var ownerPid: pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return pid
    }

    // MARK: - Frame accessors

    /// Current frame in AX coordinates, or `nil` on failure.
    public func frame() -> CGRect? {
        guard let pos = copyValue(attribute: kAXPositionAttribute, as: .cgPoint, CGPoint.self),
              let size = copyValue(attribute: kAXSizeAttribute, as: .cgSize, CGSize.self)
        else { return nil }
        return CGRect(origin: pos, size: size)
    }

    /// Result of attempting to move/resize a window. Some apps clamp
    /// size (System Settings, 1Password mini, etc.) — `sizeApplied`
    /// may be false while `positionApplied` is true. Callers should
    /// treat that as a legitimate outcome rather than a failure.
    public struct SetFrameResult: Equatable, Sendable {
        public let positionApplied: Bool
        public let sizeApplied: Bool

        public init(positionApplied: Bool, sizeApplied: Bool) {
            self.positionApplied = positionApplied
            self.sizeApplied = sizeApplied
        }
    }

    /// Set the window's frame in AX coordinates.
    ///
    /// We write position twice (position → size → position) because
    /// some apps that clamp size also shift origin as a side effect;
    /// the second position write pins the origin back where we want
    /// it. `sizeApplied == false` is legitimate and the caller decides
    /// what to do with it.
    @discardableResult
    public func setFrame(_ frame: CGRect) -> SetFrameResult {
        let pt = CGPoint(x: frame.origin.x, y: frame.origin.y)
        let posOK1 = setValue(pt, type: .cgPoint, attribute: kAXPositionAttribute)
        let sizeOK = setValue(CGSize(width: frame.width, height: frame.height),
                              type: .cgSize, attribute: kAXSizeAttribute)
        let posOK2 = setValue(pt, type: .cgPoint, attribute: kAXPositionAttribute)
        return SetFrameResult(positionApplied: posOK1 || posOK2, sizeApplied: sizeOK)
    }

    // MARK: - Diagnostic helpers

    public func stringAttribute(_ name: String) -> String? {
        Self.copyStringAttr(element, name)
    }

    public func isAttributeSettable(_ name: String) -> Bool {
        var settable: DarwinBoolean = false
        guard AXUIElementIsAttributeSettable(element, name as CFString, &settable) == .success
        else { return false }
        return settable.boolValue
    }

    // MARK: - Window resolution helpers

    private static func copyWindow(from app: AXUIElement, attribute: String) -> AXWindow? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, attribute as CFString, &ref) == .success,
              let ref, CFGetTypeID(ref) == AXUIElementGetTypeID()
        else { return nil }
        let element = ref as! AXUIElement
        // Some apps return non-window elements here (WebArea, group). Filter.
        guard let role = copyStringAttr(element, kAXRoleAttribute as String),
              role == kAXWindowRole as String
        else { return nil }
        return AXWindow(element: element)
    }

    private static func firstWindow(from app: AXUIElement) -> AXWindow? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &ref) == .success,
              let arr = ref as? [AXUIElement], let first = arr.first
        else { return nil }
        return AXWindow(element: first)
    }

    private static func copyStringAttr(_ element: AXUIElement, _ attribute: String) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success,
              let s = ref as? String
        else { return nil }
        return s
    }

    // MARK: - AXValue plumbing

    private func copyValue<T>(attribute: String, as type: AXValueType, _: T.Type) -> T? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success,
              let ref,
              CFGetTypeID(ref) == AXValueGetTypeID()
        else { return nil }
        let axValue = ref as! AXValue
        var value = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { value.deallocate() }
        guard AXValueGetValue(axValue, type, value) else { return nil }
        return value.pointee
    }

    private func setValue<T>(_ value: T, type: AXValueType, attribute: String) -> Bool {
        var local = value
        guard let axValue = AXValueCreate(type, &local) else { return false }
        return AXUIElementSetAttributeValue(element, attribute as CFString, axValue) == .success
    }
}
