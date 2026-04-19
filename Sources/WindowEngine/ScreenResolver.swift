import AppKit
import CoreGraphics
import Foundation

public enum ScreenResolver {
    public static func screen(for frame: CGRect) -> NSScreen? {
        // TODO: implement in engine-dev task.
        return NSScreen.main
    }

    public static func nextScreen(after frame: CGRect) -> NSScreen? {
        // TODO: implement in engine-dev task.
        return nil
    }

    public static func previousScreen(before frame: CGRect) -> NSScreen? {
        // TODO: implement in engine-dev task.
        return nil
    }
}
