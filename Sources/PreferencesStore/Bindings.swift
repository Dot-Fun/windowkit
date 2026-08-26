import Foundation
import WindowEngine

public enum DefaultBindings {
    /// All window *placement* is handled by the numpad sequence language
    /// (⌃⌥⌘ + numeric keypad — see `HotkeyManager.armNumpadSequence` /
    /// `NumpadRegionResolver`): one set of keys describes every region, half,
    /// quadrant, third, and fullscreen.
    ///
    /// There are no discrete global hotkeys by default — not even undo/redo.
    /// The numpad sequence is the entire keyboard surface, so nothing here can
    /// collide with another app's shortcuts (the old ⌃⌥+arrows, ⌃⌥+1–4, ⌃⌥F,
    /// ⌃⌥⌘+arrows/brackets are gone). Every `WindowAction` still exists and can
    /// be bound manually in Preferences if you want a dedicated key.
    ///
    /// Empty is a valid, working state here: `HotkeyManager.apply` re-arms the
    /// numpad keys on every call, so placement never depends on this map.
    public static let spectacle: [WindowAction: Shortcut] = [:]
}
