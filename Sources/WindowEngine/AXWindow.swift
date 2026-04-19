import ApplicationServices
import CoreGraphics
import Foundation

/// Thin wrapper around an `AXUIElement` representing a window.
///
/// **Coordinate convention**: AX reports and accepts window position/size
/// in the global AX coordinate space — **top-left origin of the primary
/// display**, y grows downward. Multi-display positions may have
/// negative x/y for displays left-of or above the primary.
public struct AXWindow: Equatable {
    public let element: AXUIElement

    public init(element: AXUIElement) {
        self.element = element
    }

    public static func == (lhs: AXWindow, rhs: AXWindow) -> Bool {
        CFEqual(lhs.element, rhs.element)
    }

    /// Focused window of the frontmost application, or `nil` if none /
    /// no Accessibility trust.
    public static func focusedWindow() -> AXWindow? {
        let system = AXUIElementCreateSystemWide()
        var appRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            system, kAXFocusedApplicationAttribute as CFString, &appRef
        ) == .success, let appRef, CFGetTypeID(appRef) == AXUIElementGetTypeID() else {
            return nil
        }
        let app = appRef as! AXUIElement

        var winRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            app, kAXFocusedWindowAttribute as CFString, &winRef
        ) == .success, let winRef, CFGetTypeID(winRef) == AXUIElementGetTypeID() else {
            return nil
        }
        return AXWindow(element: winRef as! AXUIElement)
    }

    /// Current frame in AX coordinates, or `nil` on failure.
    public func frame() -> CGRect? {
        guard let pos = copyValue(attribute: kAXPositionAttribute, as: .cgPoint, CGPoint.self),
              let size = copyValue(attribute: kAXSizeAttribute, as: .cgSize, CGSize.self)
        else { return nil }
        return CGRect(origin: pos, size: size)
    }

    /// Set the window's frame in AX coordinates. Some windows refuse
    /// resize; callers should re-read `frame()` if exact positioning
    /// matters.
    @discardableResult
    public func setFrame(_ frame: CGRect) -> Bool {
        let posOK = setValue(CGPoint(x: frame.origin.x, y: frame.origin.y),
                             type: .cgPoint, attribute: kAXPositionAttribute)
        let sizeOK = setValue(CGSize(width: frame.width, height: frame.height),
                              type: .cgSize, attribute: kAXSizeAttribute)
        return posOK && sizeOK
    }

    // MARK: - AXValue plumbing

    private func copyValue<T>(attribute: String, as type: AXValueType, _: T.Type) -> T? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success,
              let ref,
              CFGetTypeID(ref) == AXValueGetTypeID()
        else { return nil }
        let axValue = ref as! AXValue
        var out = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { out.deallocate() }
        guard AXValueGetValue(axValue, type, out) else { return nil }
        return out.pointee
    }

    private func setValue<T>(_ value: T, type: AXValueType, attribute: String) -> Bool {
        var local = value
        guard let axValue = AXValueCreate(type, &local) else { return false }
        return AXUIElementSetAttributeValue(element, attribute as CFString, axValue) == .success
    }
}
