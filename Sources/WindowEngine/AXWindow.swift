import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// AX attribute names we read/write. Centralized so a typo can't silently
/// disable Electron handling — the original Discord bug came from leaning on
/// the wrong attribute (`AXEnhancedUserInterface` instead of
/// `AXManualAccessibility`).
public enum AXAttr {
    /// VoiceOver's attribute. When on, AppKit applies AX position/size writes
    /// asynchronously/animated/ignored, which breaks keyboard window managers.
    public static let enhancedUserInterface = "AXEnhancedUserInterface"
    /// Chromium/Electron's opt-in for non-VoiceOver clients — wakes the a11y
    /// tree with no window-positioning side-effect.
    public static let manualAccessibility = "AXManualAccessibility"
}

/// Steps of the "neutralize AXEnhancedUserInterface around a frame write"
/// sequence (Rectangle's technique). Modeled as a value so the policy and its
/// ordering are unit-testable without touching the live AX API.
public enum FrameWriteStep: Equatable {
    case disableEnhancedUI
    case writeFrame
    case restoreEnhancedUI
}

/// Pure decisions for the enhanced-UI dance. Driven by `AXWindow.setFrame`.
public enum EnhancedUIPolicy {
    /// Only dance when EUI is actually on. `nil` (attribute absent) and `false`
    /// both mean "leave it alone" — normal apps take the no-op path.
    public static func shouldToggle(currentlyEnabled: Bool?) -> Bool {
        currentlyEnabled == true
    }

    /// Ordered steps for a frame write given the app's current EUI state.
    public static func framePlan(euiEnabled: Bool) -> [FrameWriteStep] {
        euiEnabled
            ? [.disableEnhancedUI, .writeFrame, .restoreEnhancedUI]
            : [.writeFrame]
    }
}

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

    /// Process ID of the app owning this window. Used to reach the owning
    /// application element (enhanced-UI toggle, Electron a11y wake).
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
    /// If the owning app has `AXEnhancedUserInterface` on (VoiceOver users, or
    /// Electron/Chromium apps that turned it on), AppKit applies position/size
    /// writes asynchronously/animated/ignored and the window won't land where
    /// we ask. So we follow Rectangle's technique: disable it, write, restore.
    /// Normal apps (attribute absent or false) take the plain write path with
    /// zero behavior change. The plan is restored on every path because the
    /// `.restoreEnhancedUI` step is the last element of `framePlan`.
    @discardableResult
    public func setFrame(_ frame: CGRect) -> SetFrameResult {
        let euiOn = EnhancedUIPolicy.shouldToggle(currentlyEnabled: enhancedUserInterfaceEnabled())
        var result = SetFrameResult(positionApplied: false, sizeApplied: false)
        for step in EnhancedUIPolicy.framePlan(euiEnabled: euiOn) {
            switch step {
            case .disableEnhancedUI: setEnhancedUserInterface(false)
            case .writeFrame: result = writeFrame(frame)
            case .restoreEnhancedUI: setEnhancedUserInterface(true)
            }
        }
        return result
    }

    /// The actual frame write. Set size before position so a bottom-anchored
    /// target is not clamped using the window's previous taller size. Position
    /// twice because some apps shift it while applying size; `sizeApplied ==
    /// false` is legitimate and the caller decides what to do with it.
    private func writeFrame(_ frame: CGRect) -> SetFrameResult {
        let pt = CGPoint(x: frame.origin.x, y: frame.origin.y)
        let sizeOK = setValue(CGSize(width: frame.width, height: frame.height),
                              type: .cgSize, attribute: kAXSizeAttribute)
        let posOK1 = setValue(pt, type: .cgPoint, attribute: kAXPositionAttribute)
        let posOK2 = setValue(pt, type: .cgPoint, attribute: kAXPositionAttribute)
        return SetFrameResult(positionApplied: posOK1 || posOK2, sizeApplied: sizeOK)
    }

    // MARK: - Enhanced-UI (app element)

    private func appElement() -> AXUIElement {
        AXUIElementCreateApplication(ownerPid)
    }

    /// `AXEnhancedUserInterface` on the owning app, or `nil` when the attribute
    /// is absent/unreadable (most plain AppKit apps).
    public func enhancedUserInterfaceEnabled() -> Bool? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement(), AXAttr.enhancedUserInterface as CFString, &ref) == .success,
            let ref
        else { return nil }
        return ref as? Bool
    }

    @discardableResult
    public func setEnhancedUserInterface(_ enabled: Bool) -> Bool {
        AXUIElementSetAttributeValue(
            appElement(),
            AXAttr.enhancedUserInterface as CFString,
            enabled ? kCFBooleanTrue : kCFBooleanFalse
        ) == .success
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
