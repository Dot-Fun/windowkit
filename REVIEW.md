# WindowKit v0.1 — Code Review Findings

Reviewer: `reviewer` (task #6)
Date: 2026-04-19
Scope: full repo audit against `~/.claude/plans/do-it-structured-lantern.md`

## Summary

- HIGH severity: **0** (no in-place fixes required)
- MEDIUM severity: **1**
- LOW severity: **5**

All 10 focus areas from the team-lead brief verified clean: action coverage (39 cases), 3×3 grid tiling (integer-boundary math, tested at 1920×1080 / 1000×1000 / 4K / offset screens), AX↔Cocoa coordinate discipline (single conversion in `ActionRunner.performGeometry`, AX preserved through `Geometry` and `AXWindow`), Carbon hotkey rebind (`HotkeyManager.apply` calls `clear()` first, unregistering all prior refs), preferences round-trip (codable + export/import tests pass), no force-unwraps on fallible AX calls, `[weak self]` throughout, `.gitignore` adequate, README documents the unsigned-build re-grant workflow.

## MEDIUM

### M1. `PreferencesViewModel.set()` double-saves
- **File:** `Sources/PreferencesUI/PreferencesWindow.swift`
- **Issue:** `set(_:for:)` calls `store.set(...)` followed by `store.save()`. `PreferencesStore.set()` already invokes `commit()` which persists, so the explicit `store.save()` writes to `UserDefaults` twice on every shortcut edit.
- **Fix:** Remove the trailing `store.save()` in the view-model setter, or document that `store.set` is fire-and-forget.

## LOW

### L1. PreferencesUI bypasses store-level conflict detection
- **File:** `Sources/PreferencesUI/PreferencesWindow.swift`
- **Issue:** Recorder UI clears the existing binding owner before calling `store.set`, which means `Conflict?` is never observed at this call-site. Intended UX (last-writer-wins with implicit reassignment), but the store API supports a richer "show conflict marker" path that the UI doesn't use.
- **Fix:** Document the design choice in a one-line comment or surface conflicts in the UI per VERIFICATION step M12.

### L2. `HotkeyManager.deinit` touches MainActor state from arbitrary context
- **File:** `Sources/HotkeyManager/HotkeyManager.swift`
- **Issue:** `deinit` iterates `registrations` (MainActor-isolated) to call `UnregisterEventHotKey`. Carbon calls are documented thread-safe and the existing comment notes this, but Swift 6 strict concurrency will flag it.
- **Fix:** Hop to MainActor in deinit via `Task { @MainActor in ... }` capturing the refs by value, or annotate the storage `nonisolated(unsafe)`.

### L3. `AccessibilityTrust.trustPublisher` polls indefinitely
- **File:** `Sources/PermissionsCoordinator/AccessibilityTrust.swift`
- **Issue:** Combine `Timer.publish` runs for the lifetime of any subscriber. Currently only `OnboardingView` subscribes, so it stops with the view, but a future caller could leak a 1 Hz timer.
- **Fix:** Add a doc comment noting subscriber-lifecycle responsibility, or expose an explicit `start/stop` API.

### L4. Two `AXValueCreate` compiler warnings in `AXWindow.swift`
- **File:** `Sources/WindowEngine/AXWindow.swift`
- **Issue:** `UnsafeRawPointer` initialization warnings inherent to the Swift↔Carbon generic bridge. Pre-existing; called out in `VERIFICATION.md` P1.
- **Fix:** Wrap the AXValue creation in a typed helper that encapsulates the unsafe cast, or silence with a targeted `// swiftlint:disable` if SwiftLint is added later.

### L5. Redo stack lives outside `UndoStack`
- **File:** `App/ActionRunner.swift`
- **Issue:** `redoFrames: [CGRect]` is owned by `ActionRunner` instead of being a first-class `UndoStack` primitive. Acceptable for v0.1 per VERIFICATION known-limitations; promote to `UndoStack` when per-window keying lands.
- **Fix:** Future refactor — extend `UndoStack` with `redo()` returning `Snapshot?` and remove `redoFrames` from `ActionRunner`.

## Verified clean (no findings)

- Plan action set vs `WindowAction` enum: all 39 cases present and routed.
- `Geometry.boundaries(length:count:)` integer rounding guarantees exact tiling at all tested sizes including non-divisible widths.
- `CoordinateConverter.cocoaToAX`/`axToCocoa` is a true involution; round-trip test green.
- `HotkeyManager.apply(bindings:)` correctly invokes `clear()` before re-registering — no leaks across rebind.
- Preferences codable round-trip + export/import green; default bindings have no internal collisions.
- No force-unwraps on `AXUIElementCopy*` results — all use `guard let`.
- `[weak self]` in `HotkeyManager` event dispatcher and `WindowKitAppDelegate` Combine sinks — no retain cycles.
- `.gitignore` covers `.DS_Store`, `.build/`, `build/`, `.swiftpm/`, `DerivedData/`, xcuserdata, `Package.resolved`.
- README "Unsigned-build caveat" section accurately describes per-rebuild AX re-grant flow.

## Blockers for manual testing

**None.** Proceed with VERIFICATION.md M1–M14 on a real macOS 14+ session.
