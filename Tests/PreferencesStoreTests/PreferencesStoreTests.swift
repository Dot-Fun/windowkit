import XCTest
@testable import PreferencesStore
import WindowEngine

final class PreferencesStoreTests: XCTestCase {
    private func isolatedDefaults() -> UserDefaults {
        let suite = "PreferencesStoreTests.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }

    func testShortcutCodableRoundTrip() throws {
        let original = Shortcut(keyCode: 123, modifiers: 0xDEAD)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Shortcut.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testDefaultBindingsHaveNoInternalConflict() {
        var seen: [UInt64: WindowAction] = [:]
        for (action, shortcut) in DefaultBindings.spectacle {
            let fp = (UInt64(shortcut.keyCode) << 32) | UInt64(shortcut.modifiers)
            if let prior = seen[fp] {
                XCTFail("\(action) and \(prior) share shortcut \(shortcut.displayString)")
            }
            seen[fp] = action
        }
    }

    func testConflictDetection() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        let taken = store.bindings[.leftHalf]!
        let conflict = store.set(taken, for: .rightHalf)
        XCTAssertEqual(conflict?.existingAction, .leftHalf)
        XCTAssertEqual(conflict?.shortcut, taken)
        // Unchanged on conflict.
        XCTAssertEqual(store.bindings[.rightHalf], DefaultBindings.spectacle[.rightHalf])
    }

    func testExportImportRoundTrip() throws {
        let store = PreferencesStore(defaults: isolatedDefaults())
        // Mutate a little so we're not just round-tripping defaults.
        store.set(Shortcut(keyCode: 7, modifiers: 0x100), for: .center)
        let data = store.exportJSON()

        let fresh = PreferencesStore(defaults: isolatedDefaults())
        try fresh.importJSON(data)
        XCTAssertEqual(fresh.bindings, store.bindings)
    }

    func testSetNilClearsBinding() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        XCTAssertNotNil(store.bindings[.leftHalf])
        store.set(nil, for: .leftHalf)
        XCTAssertNil(store.bindings[.leftHalf])
    }
}
