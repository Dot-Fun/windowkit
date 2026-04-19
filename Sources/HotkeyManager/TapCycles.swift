import Foundation
import WindowEngine

/// Maps a hotkey's primary action to the sequence of actions fired on
/// successive taps. Wrap-around: tap N where N > cycle.count wraps via modulo.
public enum TapCycles {
    public static let `default`: [WindowAction: [WindowAction]] = [
        .grid3TopLeft:      [.grid3TopLeft, .topLeft],
        .grid3TopCenter:    [.grid3TopCenter, .topThird, .topHalf, .topTwoThirds],
        .grid3TopRight:     [.grid3TopRight, .topRight],
        .grid3MiddleLeft:   [.grid3MiddleLeft, .firstThird, .leftHalf, .firstTwoThirds],
        .grid3MiddleCenter: [.grid3MiddleCenter, .fullscreen],
        .grid3MiddleRight:  [.grid3MiddleRight, .lastThird, .rightHalf, .lastTwoThirds],
        .grid3BottomLeft:   [.grid3BottomLeft, .bottomLeft],
        .grid3BottomCenter: [.grid3BottomCenter, .bottomThird, .bottomHalf, .bottomTwoThirds],
        .grid3BottomRight:  [.grid3BottomRight, .bottomRight],
    ]

    /// Resolves `action` for a 1-based `tapCount`. Non-cycle actions return self.
    public static func resolve(_ action: WindowAction, tapCount: Int) -> WindowAction {
        guard let cycle = self.default[action], !cycle.isEmpty else { return action }
        let n = cycle.count
        let idx = ((tapCount - 1) % n + n) % n
        return cycle[idx]
    }
}
