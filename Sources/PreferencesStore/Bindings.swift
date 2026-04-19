import Foundation
import Carbon.HIToolbox
import WindowEngine

public enum DefaultBindings {
    private static let cmdOpt: UInt32 = UInt32(cmdKey | optionKey)
    private static let ctrlOpt: UInt32 = UInt32(controlKey | optionKey)
    private static let ctrlOptCmd: UInt32 = UInt32(controlKey | optionKey | cmdKey)
    private static let ctrlOptShift: UInt32 = UInt32(controlKey | optionKey | shiftKey)

    private static func sc(_ keyCode: Int, _ modifiers: UInt32) -> Shortcut {
        Shortcut(keyCode: UInt32(keyCode), modifiers: modifiers)
    }

    public static let spectacle: [WindowAction: Shortcut] = [
        // Halves
        .leftHalf:    sc(kVK_LeftArrow,  ctrlOpt),
        .rightHalf:   sc(kVK_RightArrow, ctrlOpt),
        .topHalf:     sc(kVK_UpArrow,    ctrlOpt),
        .bottomHalf:  sc(kVK_DownArrow,  ctrlOpt),

        // 2x2 Quadrants
        .topLeft:     sc(kVK_ANSI_1, ctrlOpt),
        .topRight:    sc(kVK_ANSI_2, ctrlOpt),
        .bottomLeft:  sc(kVK_ANSI_3, ctrlOpt),
        .bottomRight: sc(kVK_ANSI_4, ctrlOpt),

        // Thirds (⌃⌥⌘ + arrows). lastThird keeps ⌃⌥⌘→; nextDisplay uses
        // ⌃⌥⌘] / previousDisplay ⌃⌥⌘[ to avoid the collision.
        .firstThird:  sc(kVK_LeftArrow,  ctrlOptCmd),
        .centerThird: sc(kVK_UpArrow,    ctrlOptCmd),
        .lastThird:   sc(kVK_RightArrow, ctrlOptCmd),

        // Sizing
        .fullscreen:      sc(kVK_ANSI_F,     ctrlOpt),
        .center:          sc(kVK_ANSI_C,     ctrlOpt),
        .almostMaximize:  sc(kVK_ANSI_Equal, ctrlOpt),

        // History
        .undo: sc(kVK_ANSI_Z, ctrlOpt),
        .redo: sc(kVK_ANSI_Z, ctrlOptShift),

        // Displays — nextDisplay/previousDisplay use ⌃⌥⌘] / ⌃⌥⌘[ to avoid
        // arrow-key conflict with lastThird per plan.
        .nextDisplay:     sc(kVK_ANSI_RightBracket, ctrlOptCmd),
        .previousDisplay: sc(kVK_ANSI_LeftBracket,  ctrlOptCmd),

        // 3x3 spatial grid: ⌘⌥ + U/I/O, J/K/L, M/,/.
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
