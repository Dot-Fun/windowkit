import Carbon.HIToolbox
import XCTest
@testable import PreferencesStore

final class SequenceKeyLayoutTests: XCTestCase {
    private func isolatedDefaults() -> UserDefaults {
        let suite = "SequenceKeyLayoutTests.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }

    /// The whole point of the laptop fallback: same language, same cells, so a
    /// sequence means the same region whichever key set produced it.
    func testBothLayoutsCoverTheSameNineCells() {
        for layout in SequenceKeyLayout.allCases {
            XCTAssertEqual(Set(layout.keys.map(\.digit)), Set(1...9), "\(layout)")
            XCTAssertEqual(layout.keys.count, 9, "\(layout)")
        }
    }

    /// A duplicate keycode would silently drop a cell at registration time.
    func testNoLayoutRepeatsAKeyCode() {
        for layout in SequenceKeyLayout.allCases {
            let codes = layout.keys.map(\.keyCode)
            XCTAssertEqual(Set(codes).count, codes.count, "\(layout) repeats a key code")
        }
    }

    func testLettersLayoutIsSpatiallyArranged() {
        let map = Dictionary(uniqueKeysWithValues: SequenceKeyLayout.letters.keys.map { ($0.digit, $0.keyCode) })
        // Top row of the screen sits on the top row of the right hand.
        XCTAssertEqual(map[7], kVK_ANSI_U)
        XCTAssertEqual(map[8], kVK_ANSI_I)
        XCTAssertEqual(map[9], kVK_ANSI_O)
        XCTAssertEqual(map[4], kVK_ANSI_J)
        XCTAssertEqual(map[5], kVK_ANSI_K)
        XCTAssertEqual(map[6], kVK_ANSI_L)
        XCTAssertEqual(map[1], kVK_ANSI_M)
        XCTAssertEqual(map[2], kVK_ANSI_Comma)
        XCTAssertEqual(map[3], kVK_ANSI_Period)
    }

    func testNumpadLayoutIsSpatiallyArranged() {
        let map = Dictionary(uniqueKeysWithValues: SequenceKeyLayout.numpad.keys.map { ($0.digit, $0.keyCode) })
        XCTAssertEqual(map[7], kVK_ANSI_Keypad7)
        XCTAssertEqual(map[5], kVK_ANSI_Keypad5)
        XCTAssertEqual(map[3], kVK_ANSI_Keypad3)
    }

    /// The diagram renders `keycapRows`; if it drifted from `keys` the
    /// Preferences window would advertise keys that aren't registered.
    func testKeycapRowsMatchTheRegisteredKeyOrder() {
        for layout in SequenceKeyLayout.allCases {
            let flat = layout.keycapRows.flatMap { $0 }
            XCTAssertEqual(flat.count, 9, "\(layout)")
            XCTAssertEqual(layout.keycapRows.map(\.count), [3, 3, 3], "\(layout)")
            // Screen order is 7/8/9, 4/5/6, 1/2/3 — same order `keys` lists.
            XCTAssertEqual(flat, layout.keys.map { layout.keycap(forDigit: $0.digit) }, "\(layout)")
        }
    }

    func testKeycapForDigit() {
        XCTAssertEqual(SequenceKeyLayout.numpad.keycap(forDigit: 7), "7")
        XCTAssertEqual(SequenceKeyLayout.numpad.keycap(forDigit: 5), "5")
        XCTAssertEqual(SequenceKeyLayout.letters.keycap(forDigit: 7), "U")
        XCTAssertEqual(SequenceKeyLayout.letters.keycap(forDigit: 5), "K")
        XCTAssertEqual(SequenceKeyLayout.letters.keycap(forDigit: 3), ".")
    }

    // MARK: - Store toggle

    func testTenKeyDefaultsToAvailable() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        XCTAssertTrue(store.tenKeyAvailable)
        XCTAssertEqual(store.sequenceKeyLayout, .numpad)
    }

    func testTurningTenKeyOffSelectsTheLetterLayout() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        store.tenKeyAvailable = false
        XCTAssertEqual(store.sequenceKeyLayout, .letters)
    }

    func testTenKeyChoicePersists() {
        let defaults = isolatedDefaults()
        let store = PreferencesStore(defaults: defaults)
        store.tenKeyAvailable = false

        let reload = PreferencesStore(defaults: defaults)
        XCTAssertFalse(reload.tenKeyAvailable)
        XCTAssertEqual(reload.sequenceKeyLayout, .letters)
    }
}
