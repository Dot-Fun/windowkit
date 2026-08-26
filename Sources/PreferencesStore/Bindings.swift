import Foundation
import Carbon.HIToolbox
import WindowEngine

public enum DefaultBindings {
    private static let cmdOpt: UInt32 = UInt32(cmdKey | optionKey)

    private static func sc(_ keyCode: Int, _ modifiers: UInt32) -> Shortcut {
        Shortcut(keyCode: UInt32(keyCode), modifiers: modifiers)
    }

    /// The only bound hotkeys: the 3×3 spatial grid on ⌘⌥ + U/I/O, J/K/L, M/,/.
    ///
    /// Every other layout (halves, thirds, quadrants, two-thirds, fullscreen)
    /// is still reachable — not as its own hotkey, but as a later step in a
    /// grid key's multi-tap cycle. See `TapCycles`.
    public static let grid3: [WindowAction: Shortcut] = [
        .grid3TopLeft:      sc(kVK_ANSI_U,      cmdOpt),
        .grid3TopCenter:    sc(kVK_ANSI_I,      cmdOpt),
        .grid3TopRight:     sc(kVK_ANSI_O,      cmdOpt),
        .grid3MiddleLeft:   sc(kVK_ANSI_J,      cmdOpt),
        .grid3MiddleCenter: sc(kVK_ANSI_K,      cmdOpt),
        .grid3MiddleRight:  sc(kVK_ANSI_L,      cmdOpt),
        .grid3BottomLeft:   sc(kVK_ANSI_M,      cmdOpt),
        .grid3BottomCenter: sc(kVK_ANSI_Comma,  cmdOpt),
        .grid3BottomRight:  sc(kVK_ANSI_Period, cmdOpt),
    ]
}
