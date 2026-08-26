import CoreGraphics
import Foundation
import XCTest
@testable import LayoutProfiles

final class LayoutMatcherTests: XCTestCase {
    private func record(
        _ bundleID: String, _ title: String,
        x: CGFloat = 0, y: CGFloat = 0, w: CGFloat = 100, h: CGFloat = 100
    ) -> WindowRecord {
        WindowRecord(
            bundleID: bundleID, appName: bundleID, title: title,
            frame: CGRect(x: x, y: y, width: w, height: h)
        )
    }

    func testExactTitleMatchWinsOverOrder() {
        let records = [
            record("com.apple.Terminal", "alpha", x: 0),
            record("com.apple.Terminal", "beta", x: 500),
        ]
        // Live order reversed — titles must still pair correctly.
        let live = [
            record("com.apple.Terminal", "beta", x: 999),
            record("com.apple.Terminal", "alpha", x: 999),
        ]
        let plan = LayoutMatcher.plan(records: records, live: live)
        XCTAssertEqual(plan, [
            .init(recordIndex: 0, liveIndex: 1),
            .init(recordIndex: 1, liveIndex: 0),
        ])
    }

    func testChangedTitlesFallBackToOrder() {
        // The terminal case: titles at save time are gone, pairing is 1:1 by order.
        let records = [
            record("com.apple.Terminal", "~/dev — zsh", x: 0),
            record("com.apple.Terminal", "make — 80×24", x: 500),
        ]
        let live = [
            record("com.apple.Terminal", "vim notes.md", x: 999),
            record("com.apple.Terminal", "ssh prod", x: 999),
        ]
        let plan = LayoutMatcher.plan(records: records, live: live)
        XCTAssertEqual(plan, [
            .init(recordIndex: 0, liveIndex: 0),
            .init(recordIndex: 1, liveIndex: 1),
        ])
    }

    func testNoCrossAppMatching() {
        let records = [record("com.apple.Terminal", "same title")]
        let live = [record("com.apple.Safari", "same title")]
        XCTAssertTrue(LayoutMatcher.plan(records: records, live: live).isEmpty)
    }

    func testDuplicateTitlesConsumeGreedily() {
        let records = [
            record("app", "dup", x: 0),
            record("app", "dup", x: 500),
        ]
        let live = [
            record("app", "dup", x: 999),
            record("app", "dup", x: 998),
        ]
        let plan = LayoutMatcher.plan(records: records, live: live)
        // Each live window used exactly once.
        XCTAssertEqual(Set(plan.map(\.liveIndex)), [0, 1])
        XCTAssertEqual(plan.count, 2)
    }

    func testMoreRecordsThanLiveLeavesUnmatched() {
        let records = [
            record("app", "a"),
            record("app", "b"),
            record("app", "c"),
        ]
        let live = [record("app", "b")]
        let plan = LayoutMatcher.plan(records: records, live: live)
        XCTAssertEqual(plan, [.init(recordIndex: 1, liveIndex: 0)])
    }

    func testMoreLiveThanRecordsLeavesExtrasAlone() {
        let records = [record("app", "only")]
        let live = [
            record("app", "x"),
            record("app", "only"),
            record("app", "y"),
        ]
        let plan = LayoutMatcher.plan(records: records, live: live)
        XCTAssertEqual(plan, [.init(recordIndex: 0, liveIndex: 1)])
    }

    func testMixedTitleAndOrderWithinOneApp() {
        let records = [
            record("app", "stable", x: 0),
            record("app", "was-1", x: 100),
            record("app", "was-2", x: 200),
        ]
        let live = [
            record("app", "now-1"),
            record("app", "stable"),
            record("app", "now-2"),
        ]
        let plan = LayoutMatcher.plan(records: records, live: live)
        // "stable" pairs by title; the other two pair positionally with the rest.
        XCTAssertEqual(plan, [
            .init(recordIndex: 0, liveIndex: 1),
            .init(recordIndex: 1, liveIndex: 0),
            .init(recordIndex: 2, liveIndex: 2),
        ])
    }

    func testEmptyTitleNeverTitleMatches() {
        let records = [record("app", "", x: 0), record("app", "", x: 100)]
        let live = [record("app", ""), record("app", "")]
        let plan = LayoutMatcher.plan(records: records, live: live)
        XCTAssertEqual(plan, [
            .init(recordIndex: 0, liveIndex: 0),
            .init(recordIndex: 1, liveIndex: 1),
        ])
    }

    func testNeedsMoveEpsilon() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertFalse(LayoutMatcher.needsMove(
            current: a, target: CGRect(x: 0.5, y: 0.5, width: 100.5, height: 99.5)))
        XCTAssertTrue(LayoutMatcher.needsMove(
            current: a, target: CGRect(x: 2, y: 0, width: 100, height: 100)))
        XCTAssertTrue(LayoutMatcher.needsMove(
            current: a, target: CGRect(x: 0, y: 0, width: 100, height: 103)))
    }
}

final class DisplaySignatureTests: XCTestCase {
    private let main = CGRect(x: 0, y: 0, width: 3840, height: 2160)
    private let side = CGRect(x: 3840, y: 500, width: 1440, height: 2560)

    func testMatchIsOrderInsensitive() {
        let a = DisplaySignature(screens: [main, side])
        let b = DisplaySignature(screens: [side, main])
        XCTAssertTrue(a.matches(b))
    }

    func testDifferentArrangementDoesNotMatch() {
        let a = DisplaySignature(screens: [main, side])
        let moved = DisplaySignature(screens: [main, side.offsetBy(dx: 0, dy: -500)])
        XCTAssertFalse(a.matches(moved))
        XCTAssertFalse(a.matches(DisplaySignature(screens: [main])))
    }

    func testSummary() {
        XCTAssertEqual(
            DisplaySignature(screens: [main, side]).summary,
            "2 displays — 3840×2160, 1440×2560"
        )
        XCTAssertEqual(
            DisplaySignature(screens: [main]).summary,
            "1 display — 3840×2160"
        )
    }
}

final class LayoutProfileStoreTests: XCTestCase {
    private func isolatedDefaults() -> UserDefaults {
        let suite = "LayoutProfilesTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func profile(
        _ name: String,
        autoRestore: Bool = false,
        savedAt: Date = Date(),
        screens: [CGRect] = [CGRect(x: 0, y: 0, width: 1920, height: 1080)]
    ) -> LayoutProfile {
        LayoutProfile(
            name: name,
            signature: DisplaySignature(screens: screens),
            windows: [WindowRecord(
                bundleID: "com.apple.Terminal", appName: "Terminal",
                title: "t", frame: CGRect(x: 1, y: 2, width: 3, height: 4)
            )],
            autoRestore: autoRestore,
            savedAt: savedAt
        )
    }

    func testPersistRoundTrip() {
        let defaults = isolatedDefaults()
        let store = LayoutProfileStore(defaults: defaults)
        let p = profile("Monitor 1: Space A")
        store.add(p)

        let reloaded = LayoutProfileStore(defaults: defaults)
        XCTAssertEqual(reloaded.profiles.count, 1)
        XCTAssertEqual(reloaded.profiles[0].id, p.id)
        XCTAssertEqual(reloaded.profiles[0].name, "Monitor 1: Space A")
        XCTAssertEqual(reloaded.profiles[0].windows, p.windows)
    }

    func testRenameSetAutoRestoreRemovePersist() {
        let defaults = isolatedDefaults()
        let store = LayoutProfileStore(defaults: defaults)
        let a = profile("A")
        let b = profile("B")
        store.add(a)
        store.add(b)

        store.rename(id: a.id, to: "A2")
        store.setAutoRestore(id: b.id, true)
        store.remove(id: a.id)

        let reloaded = LayoutProfileStore(defaults: defaults)
        XCTAssertEqual(reloaded.profiles.map(\.name), ["B"])
        XCTAssertTrue(reloaded.profiles[0].autoRestore)
    }

    func testReplaceWindowsUpdatesSnapshotAndDate() {
        let defaults = isolatedDefaults()
        let store = LayoutProfileStore(defaults: defaults)
        let old = Date(timeIntervalSinceNow: -3600)
        let p = profile("P", savedAt: old)
        store.add(p)

        let newWindows = [WindowRecord(
            bundleID: "com.apple.Safari", appName: "Safari",
            title: "s", frame: CGRect(x: 9, y: 9, width: 9, height: 9)
        )]
        let newSig = DisplaySignature(screens: [CGRect(x: 0, y: 0, width: 800, height: 600)])
        store.replaceWindows(id: p.id, windows: newWindows, signature: newSig)

        let updated = store.profiles[0]
        XCTAssertEqual(updated.windows, newWindows)
        XCTAssertTrue(updated.signature.matches(newSig))
        XCTAssertGreaterThan(updated.savedAt, old)
        XCTAssertEqual(updated.name, "P")
    }

    func testAutoRestorePicksMostRecentMatching() {
        let store = LayoutProfileStore(defaults: isolatedDefaults())
        let screens = [CGRect(x: 0, y: 0, width: 1920, height: 1080)]
        let otherScreens = [CGRect(x: 0, y: 0, width: 800, height: 600)]

        store.add(profile("old auto", autoRestore: true,
                          savedAt: Date(timeIntervalSinceNow: -100), screens: screens))
        store.add(profile("new auto", autoRestore: true,
                          savedAt: Date(), screens: screens))
        store.add(profile("manual", autoRestore: false,
                          savedAt: Date(), screens: screens))
        store.add(profile("other config", autoRestore: true,
                          savedAt: Date(), screens: otherScreens))

        let picked = store.autoRestoreProfile(matching: DisplaySignature(screens: screens))
        XCTAssertEqual(picked?.name, "new auto")

        XCTAssertNil(store.autoRestoreProfile(
            matching: DisplaySignature(screens: [CGRect(x: 0, y: 0, width: 1, height: 1)])))
    }
}
