import Foundation
import WindowEngine

/// Maps a hotkey's primary action to the sequence of actions fired on
/// successive taps. Wrap-around: tap N where N > cycle.count wraps via modulo.
public enum TapCycles {
    public static let `default`: [WindowAction: [WindowAction]] = [
        .grid3TopLeft:      [.topLeft, .grid3TopLeft, .topLeftTwoThirds],
        .grid3TopCenter:    [.topHalf, .topThird, .grid3TopCenter, .topTwoThirds],
        .grid3TopRight:     [.topRight, .grid3TopRight, .topRightTwoThirds],
        .grid3MiddleLeft:   [.leftHalf, .firstThird, .grid3MiddleLeft, .firstTwoThirds],
        .grid3MiddleCenter: [.fullscreen, .grid3MiddleCenter, .centerThird],
        .grid3MiddleRight:  [.rightHalf, .lastThird, .grid3MiddleRight, .lastTwoThirds],
        .grid3BottomLeft:   [.bottomLeft, .grid3BottomLeft, .bottomLeftTwoThirds],
        .grid3BottomCenter: [.bottomHalf, .bottomThird, .grid3BottomCenter, .bottomTwoThirds],
        .grid3BottomRight:  [.bottomRight, .grid3BottomRight, .bottomRightTwoThirds],
    ]

    /// Resolves `action` for a 1-based `tapCount`. Non-cycle actions return self.
    public static func resolve(_ action: WindowAction, tapCount: Int) -> WindowAction {
        guard let cycle = self.default[action], !cycle.isEmpty else { return action }
        let n = cycle.count
        let idx = ((tapCount - 1) % n + n) % n
        return cycle[idx]
    }
}
