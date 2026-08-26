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
        for (action, shortcut) in DefaultBindings.grid3 {
            let fp = (UInt64(shortcut.keyCode) << 32) | UInt64(shortcut.modifiers)
            if let prior = seen[fp] {
                XCTFail("\(action) and \(prior) share shortcut \(shortcut.displayString)")
            }
            seen[fp] = action
        }
    }

    func testConflictDetection() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        let taken = store.bindings[.grid3MiddleLeft]!
        let conflict = store.set(taken, for: .grid3MiddleRight)
        XCTAssertEqual(conflict?.existingAction, .grid3MiddleLeft)
        XCTAssertEqual(conflict?.shortcut, taken)
        // Unchanged on conflict.
        XCTAssertEqual(store.bindings[.grid3MiddleRight], DefaultBindings.grid3[.grid3MiddleRight])
    }

    func testExportImportRoundTrip() throws {
        let store = PreferencesStore(defaults: isolatedDefaults())
        // Mutate a little so we're not just round-tripping defaults.
        store.set(Shortcut(keyCode: 7, modifiers: 0x100), for: .grid3MiddleCenter)
        let data = store.exportJSON()

        let fresh = PreferencesStore(defaults: isolatedDefaults())
        try fresh.importJSON(data)
        XCTAssertEqual(fresh.bindings, store.bindings)
    }

    func testSetNilClearsBinding() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        XCTAssertNotNil(store.bindings[.grid3TopLeft])
        store.set(nil, for: .grid3TopLeft)
        XCTAssertNil(store.bindings[.grid3TopLeft])
    }

    // MARK: - Defaults shape

    func testDefaultsBindOnlyTheThreeByThreeGrid() {
        let grid: Set<WindowAction> = [
            .grid3TopLeft, .grid3TopCenter, .grid3TopRight,
            .grid3MiddleLeft, .grid3MiddleCenter, .grid3MiddleRight,
            .grid3BottomLeft, .grid3BottomCenter, .grid3BottomRight,
        ]
        XCTAssertEqual(Set(DefaultBindings.grid3.keys), grid)
    }

    // MARK: - Empty-bindings regression

    /// A persisted `{}` decodes cleanly to an empty dictionary, which used to
    /// register zero hotkeys and leave the app inert with no keyboard route
    /// back. Empty must fall back to defaults.
    func testEmptyPersistedBindingsFallBackToDefaults() {
        let defaults = isolatedDefaults()
        defaults.set(Data("{}".utf8), forKey: "WindowKit.bindings.v1")
        let store = PreferencesStore(defaults: defaults)
        XCTAssertEqual(store.bindings, DefaultBindings.grid3)
    }

    func testCorruptPersistedBindingsFallBackToDefaults() {
        let defaults = isolatedDefaults()
        defaults.set(Data("not json".utf8), forKey: "WindowKit.bindings.v1")
        let store = PreferencesStore(defaults: defaults)
        XCTAssertEqual(store.bindings, DefaultBindings.grid3)
    }

    /// Clearing every shortcut by hand still self-heals on the next launch,
    /// which is the deliberate trade documented on `load()`.
    func testClearingEveryBindingSelfHealsOnReload() {
        let defaults = isolatedDefaults()
        let store = PreferencesStore(defaults: defaults)
        for action in store.bindings.keys { store.set(nil, for: action) }
        XCTAssertTrue(store.bindings.isEmpty)

        let reload = PreferencesStore(defaults: defaults)
        XCTAssertEqual(reload.bindings, DefaultBindings.grid3)
    }

    /// A real customisation must survive reload — the fallback triggers only
    /// on empty, never on a non-empty stored set.
    func testCustomBindingsSurviveReload() {
        let defaults = isolatedDefaults()
        let store = PreferencesStore(defaults: defaults)
        let custom = Shortcut(keyCode: 42, modifiers: 0x900)
        store.set(nil, for: .grid3TopLeft)
        store.set(custom, for: .grid3BottomRight)

        let reload = PreferencesStore(defaults: defaults)
        XCTAssertEqual(reload.bindings[.grid3BottomRight], custom)
        XCTAssertNil(reload.bindings[.grid3TopLeft])
    }

    func testTapWindowMsDefaultsToSpec() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        XCTAssertEqual(store.tapWindowMs, PreferencesStore.tapWindowDefaultMs)
        XCTAssertEqual(store.tapWindowMs, 700)
    }

    func testTapWindowMsClampsToBounds() {
        let store = PreferencesStore(defaults: isolatedDefaults())
        store.tapWindowMs = 50
        XCTAssertEqual(store.tapWindowMs, PreferencesStore.tapWindowMinMs)
        XCTAssertEqual(store.tapWindowMs, 150)
        store.tapWindowMs = 9_999
        XCTAssertEqual(store.tapWindowMs, PreferencesStore.tapWindowMaxMs)
        XCTAssertEqual(store.tapWindowMs, 1000)
        store.tapWindowMs = 300
        XCTAssertEqual(store.tapWindowMs, 300)
        store.tapWindowMs = 1000
        XCTAssertEqual(store.tapWindowMs, 1000)
    }

    func testTapWindowMsPersists() {
        let defaults = isolatedDefaults()
        let store = PreferencesStore(defaults: defaults)
        store.tapWindowMs = 250
        let reload = PreferencesStore(defaults: defaults)
        XCTAssertEqual(reload.tapWindowMs, 250)
    }

    func testTapWindowMsClampsOnLoad() {
        let defaults = isolatedDefaults()
        defaults.set(50, forKey: "WindowKit.tapWindowMs")
        let store = PreferencesStore(defaults: defaults)
        XCTAssertEqual(store.tapWindowMs, 150)
    }
}
