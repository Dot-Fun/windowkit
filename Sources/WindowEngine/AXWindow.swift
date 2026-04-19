import ApplicationServices
import CoreGraphics
import Foundation

public struct AXWindow {
    public let element: AXUIElement

    public init(element: AXUIElement) {
        self.element = element
    }

    public static func focusedWindow() -> AXWindow? {
        // TODO: implement in engine-dev task.
        return nil
    }

    public func frame() -> CGRect? {
        // TODO: implement in engine-dev task.
        return nil
    }

    public func setFrame(_ frame: CGRect) {
        // TODO: implement in engine-dev task.
    }
}
