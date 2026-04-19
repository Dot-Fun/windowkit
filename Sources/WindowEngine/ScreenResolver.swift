import AppKit
import CoreGraphics
import Foundation

/// Resolves `NSScreen` instances for window frames and provides next/prev
/// navigation for multi-display actions.
///
/// **Coordinate conventions**:
/// - `NSScreen.frame` is in **Cocoa** coordinates (bottom-left origin,
///   primary display at (0,0), y grows upward).
/// - Window frames from `AXWindow.frame()` are in **AX** coordinates
///   (top-left origin, y grows downward).
///
/// `screen(containing:)` accepts an **AX-coord** window frame and converts
/// internally before matching against NSScreen. Callers that already hold
/// a Cocoa-coord frame should use `screen(containingCocoa:)`.
public enum ScreenResolver {

    /// Height of the primary display in Cocoa coords — used to convert
    /// AX frames to Cocoa frames for NSScreen matching.
    public static var primaryHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    /// Return the `NSScreen` whose frame contains the center of the
    /// given window frame (AX coords). Falls back to `NSScreen.main`.
    public static func screen(containing windowFrameAX: CGRect) -> NSScreen? {
        let cocoa = CoordinateConverter.axToCocoa(windowFrameAX, primaryHeight: primaryHeight)
        return screen(containingCocoa: cocoa)
    }

    /// Same as `screen(containing:)` but accepts a Cocoa-coord frame.
    public static func screen(containingCocoa windowFrame: CGRect) -> NSScreen? {
        let center = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        for screen in NSScreen.screens where screen.frame.contains(center) {
            return screen
        }
        return NSScreen.main
    }

    /// Next screen (by horizontal position, wrapping) after `current`.
    public static func nextScreen(after current: NSScreen) -> NSScreen? {
        let ordered = screensOrderedHorizontally()
        guard let i = ordered.firstIndex(of: current), !ordered.isEmpty else { return nil }
        return ordered[(i + 1) % ordered.count]
    }

    /// Previous screen (by horizontal position, wrapping) before `current`.
    public static func previousScreen(before current: NSScreen) -> NSScreen? {
        let ordered = screensOrderedHorizontally()
        guard let i = ordered.firstIndex(of: current), !ordered.isEmpty else { return nil }
        return ordered[(i - 1 + ordered.count) % ordered.count]
    }

    static func screensOrderedHorizontally() -> [NSScreen] {
        NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }
    }
}
