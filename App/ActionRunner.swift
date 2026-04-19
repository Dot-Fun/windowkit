import AppKit
import CoreGraphics
import Foundation
import UndoStack
import WindowEngine

/// Executes a `WindowAction` against the focused window: resolves its
/// screen, computes a target frame via `Geometry`, pushes the current
/// frame onto the undo stack, and writes the new frame back.
///
/// Coordinate discipline: AXWindow reports/accepts frames in AX coords
/// (top-left origin, primary display). NSScreen reports in Cocoa coords
/// (bottom-left origin). Geometry is origin-agnostic, so we feed it AX
/// rects throughout and its output is AX-ready for AXWindow.setFrame.
@MainActor
public final class ActionRunner {
    private let undo: UndoStack
    private var redoFrames: [CGRect] = []

    public init(undoStack: UndoStack) {
        self.undo = undoStack
    }

    public func perform(_ action: WindowAction) {
        switch action {
        case .undo:
            performUndo()
        case .redo:
            performRedo()
        case .nextDisplay:
            moveToAdjacentDisplay(next: true)
        case .previousDisplay:
            moveToAdjacentDisplay(next: false)
        default:
            performGeometry(action)
        }
    }

    // MARK: - Geometry actions

    private func performGeometry(_ action: WindowAction) {
        guard
            let window = AXWindow.focusedWindow(),
            let current = window.frame(),
            let screen = ScreenResolver.screen(containing: current)
        else { return }

        let visibleAX = CoordinateConverter.cocoaToAX(
            screen.visibleFrame,
            primaryHeight: ScreenResolver.primaryHeight
        )
        guard let target = Geometry.targetFrame(for: action, screen: visibleAX, current: current)
        else { return }

        apply(target: target, window: window, current: current)
    }

    // MARK: - Displays

    private func moveToAdjacentDisplay(next: Bool) {
        guard
            let window = AXWindow.focusedWindow(),
            let current = window.frame(),
            let currentScreen = ScreenResolver.screen(containing: current),
            let targetScreen = next
                ? ScreenResolver.nextScreen(after: currentScreen)
                : ScreenResolver.previousScreen(before: currentScreen),
            targetScreen !== currentScreen
        else { return }

        let h = ScreenResolver.primaryHeight
        let fromAX = CoordinateConverter.cocoaToAX(currentScreen.visibleFrame, primaryHeight: h)
        let toAX = CoordinateConverter.cocoaToAX(targetScreen.visibleFrame, primaryHeight: h)

        // Preserve position as a fraction of the source screen's visible area.
        let fx = fromAX.width > 0 ? (current.origin.x - fromAX.origin.x) / fromAX.width : 0
        let fy = fromAX.height > 0 ? (current.origin.y - fromAX.origin.y) / fromAX.height : 0
        let fw = fromAX.width > 0 ? current.width / fromAX.width : 1
        let fh = fromAX.height > 0 ? current.height / fromAX.height : 1

        let target = CGRect(
            x: toAX.origin.x + fx * toAX.width,
            y: toAX.origin.y + fy * toAX.height,
            width: min(toAX.width, fw * toAX.width),
            height: min(toAX.height, fh * toAX.height)
        )

        apply(target: target, window: window, current: current)
    }

    // MARK: - History

    private func performUndo() {
        guard
            let window = AXWindow.focusedWindow(),
            let current = window.frame(),
            let snap = undo.pop()
        else { return }
        redoFrames.append(current)
        window.setFrame(snap.frame)
    }

    private func performRedo() {
        guard
            let window = AXWindow.focusedWindow(),
            let current = window.frame(),
            let next = redoFrames.popLast()
        else { return }
        undo.push(UndoStack.Snapshot(frame: current))
        window.setFrame(next)
    }

    // MARK: - Apply

    private func apply(target: CGRect, window: AXWindow, current: CGRect) {
        guard target != current else { return }
        undo.push(UndoStack.Snapshot(frame: current))
        redoFrames.removeAll()
        window.setFrame(target)
    }
}
