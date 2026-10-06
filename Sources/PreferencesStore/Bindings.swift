import Foundation
import Carbon.HIToolbox
import WindowEngine

public enum DefaultBindings {
    private static let ctrlOpt: UInt32 = UInt32(controlKey | optionKey)
    private static let ctrlOptShift: UInt32 = UInt32(controlKey | optionKey | shiftKey)

    private static func sc(_ keyCode: Int, _ modifiers: UInt32) -> Shortcut {
        Shortcut(keyCode: UInt32(keyCode), modifiers: modifiers)
    }

    /// All window *placement* is handled by the numpad sequence language
    /// (⌃⌥⌘ + numeric keypad — see `HotkeyManager.armNumpadSequence` /
    /// `NumpadRegionResolver`): one set of keys describes every region, half,
    /// quadrant, third, and fullscreen.
    ///
    /// The only discrete global hotkeys are undo/redo, which the numpad can't
    /// express. Keeping this surface tiny avoids colliding with other apps'
    /// shortcuts (the old ⌃⌥+arrows, ⌃⌥+1–4, ⌃⌥F, ⌃⌥⌘+arrows/brackets are gone).
    /// Every other `WindowAction` still exists and can be bound manually in
    /// Preferences if you want a dedicated key.
    public static let spectacle: [WindowAction: Shortcut] = [
        .undo: sc(kVK_ANSI_Z, ctrlOpt),
        .redo: sc(kVK_ANSI_Z, ctrlOptShift),
    ]
}
