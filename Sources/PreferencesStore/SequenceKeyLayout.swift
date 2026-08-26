import Carbon.HIToolbox
import Foundation

/// Which physical keys drive the sequence language.
///
/// The language itself never changes — a sequence is always described in
/// numpad-style cell numbers (7/8/9 top row, 4/5/6 middle, 1/2/3 bottom), which
/// is what `NumpadRegionResolver` consumes. Only the keys you press to produce
/// those numbers differ, so a laptop without a 10-key gets the identical grid.
///
/// `keys` and `keycapRows` are deliberately the same source of truth: the
/// Preferences diagram renders from the same value that `HotkeyManager`
/// registers, so the diagram cannot drift from what is actually bound.
public enum SequenceKeyLayout: String, Codable, CaseIterable, Sendable {
    /// Full-size keyboard: the numeric keypad, which *is* a 3×3 map of the screen.
    case numpad
    /// Laptop: U/I/O · J/K/L · M/,/. — the same 3×3 shape under the right hand.
    case letters

    /// `(keyCode, digit)` pairs, where `digit` is the numpad-style cell id.
    public var keys: [(keyCode: Int, digit: Int)] {
        switch self {
        case .numpad:
            return [
                (kVK_ANSI_Keypad7, 7), (kVK_ANSI_Keypad8, 8), (kVK_ANSI_Keypad9, 9),
                (kVK_ANSI_Keypad4, 4), (kVK_ANSI_Keypad5, 5), (kVK_ANSI_Keypad6, 6),
                (kVK_ANSI_Keypad1, 1), (kVK_ANSI_Keypad2, 2), (kVK_ANSI_Keypad3, 3),
            ]
        case .letters:
            return [
                (kVK_ANSI_U, 7), (kVK_ANSI_I, 8), (kVK_ANSI_O, 9),
                (kVK_ANSI_J, 4), (kVK_ANSI_K, 5), (kVK_ANSI_L, 6),
                (kVK_ANSI_M, 1), (kVK_ANSI_Comma, 2), (kVK_ANSI_Period, 3),
            ]
        }
    }

    /// Keycaps in screen order (top row first), for the Preferences diagram.
    public var keycapRows: [[String]] {
        switch self {
        case .numpad:  return [["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"]]
        case .letters: return [["U", "I", "O"], ["J", "K", "L"], ["M", ",", "."]]
        }
    }

    /// The cell a keycap stands for, e.g. "7" or "U" → 7. Used for prose that
    /// names example keys ("7 = top-left") without hardcoding a layout.
    public func keycap(forDigit digit: Int) -> String {
        let flat = keycapRows.flatMap { $0 }
        let order = [7, 8, 9, 4, 5, 6, 1, 2, 3]
        guard let idx = order.firstIndex(of: digit), idx < flat.count else { return "\(digit)" }
        return flat[idx]
    }
}
