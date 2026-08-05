import CoreGraphics
import Foundation
import WindowEngine

/// Maps a hotkey's primary action to the sequence of sizes it cycles through
/// on successive presses. Which step a press lands on is a function of where
/// the focused window currently sits (`next`), not how fast keys are tapped —
/// so the first press from any non-cycle layout is always the cycle's first
/// step, and repeats advance deterministically and wrap at the end.
public enum TapCycles {
    public static let `default`: [WindowAction: [WindowAction]] = [
        .grid3TopLeft:      [.topLeft, .grid3TopLeft, .topLeftTwoThirds],
        .grid3TopCenter:    [.topHalf, .topThird, .topTwoThirds, .grid3TopCenter],
        .grid3TopRight:     [.topRight, .grid3TopRight, .topRightTwoThirds],
        .grid3MiddleLeft:   [.leftHalf, .firstThird, .firstTwoThirds, .grid3MiddleLeft],
        .grid3MiddleCenter: [.fullscreen, .grid3MiddleCenter, .centerThird],
        .grid3MiddleRight:  [.rightHalf, .lastThird, .lastTwoThirds, .grid3MiddleRight],
        .grid3BottomLeft:   [.bottomLeft, .grid3BottomLeft, .bottomLeftTwoThirds],
        .grid3BottomCenter: [.bottomHalf, .bottomThird, .bottomTwoThirds, .grid3BottomCenter],
        .grid3BottomRight:  [.bottomRight, .grid3BottomRight, .bottomRightTwoThirds],
    ]

    /// Resolves the action to apply for a press of `action`, based on the
    /// focused window's `current` frame within `screen` (both in the same
    /// coordinate space).
    ///
    /// If the window is occupying one of the cycle's steps — i.e. the nearest
    /// step's target frame is within `matchThreshold(for:)` — the press
    /// advances to the following step (wrapping after the last). Otherwise the
    /// press starts the cycle at its first step. Non-cycle actions return
    /// themselves unchanged.
    public static func next(
        _ action: WindowAction,
        current: CGRect,
        screen: CGRect
    ) -> WindowAction {
        guard let cycle = self.default[action], !cycle.isEmpty else { return action }

        // Classify the window as occupying the nearest cycle step (by frame).
        var nearest: (index: Int, distance: CGFloat)?
        for (index, step) in cycle.enumerated() {
            guard let frame = Geometry.targetFrame(for: step, screen: screen, current: current)
            else { continue }
            let distance = Geometry.frameDistance(current, frame)
            if nearest == nil || distance < nearest!.distance {
                nearest = (index, distance)
            }
        }

        if let nearest, nearest.distance <= matchThreshold(for: screen) {
            return cycle[(nearest.index + 1) % cycle.count]
        }
        return cycle[0]
    }

    /// Distance (in `screen` units) within which a window counts as
    /// "occupying" a cycle step. Scales with the screen so it holds across
    /// resolutions. Cycle steps differ by at least ~1/6 of a screen dimension,
    /// so 10% reliably distinguishes adjacent steps while tolerating imperfect
    /// placement (Chromium/Electron rounding, terminals that snap to character
    /// cells) — the slack is what lets those apps advance instead of being
    /// re-classified as "off the cycle" and restarted at step 0.
    static func matchThreshold(for screen: CGRect) -> CGFloat {
        0.10 * min(screen.width, screen.height)
    }
}
