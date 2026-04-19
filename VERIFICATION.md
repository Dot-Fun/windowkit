# WindowKit v0.1 — Integration Verification

Date: 2026-04-19
Integrator: `integrator` (task #5)

Verification is split into **programmatic** (deterministic, re-runnable in CI) and **manual** (requires a GUI session, Accessibility permission, and a human clicking through the UI). Manual items are marked ⚠ — they have not been executed by the integrator agent and must be signed off by a human tester before release.

## Programmatic

| # | Check | Result | Evidence |
|---|---|---|---|
| P1 | `swift build` (debug) succeeds | ✅ PASS | Clean link, no errors. Two pre-existing `UnsafeRawPointer` warnings in `AXWindow.swift` (inherent to `AXValueCreate` generics; not regressions). |
| P2 | `swift build -c release` succeeds | ✅ PASS | Executed via `scripts/build-app.sh`; `Build complete!` |
| P3 | `swift test` — all targets | ✅ PASS | **36 tests, 0 failures** (`WindowEngineTests`: 31 · `PreferencesStoreTests`: 5). Total 0.012 s. |
| P4 | `.app` bundle assembles | ✅ PASS | `build/WindowKit.app/Contents/{MacOS/WindowKit, Info.plist, Resources/Assets.xcassets, _CodeSignature}` present. |
| P5 | Bundle has ad-hoc signature | ✅ PASS | `codesign -dv` → `Identifier=co.dotfun.WindowKit`, `flags=0x2(adhoc)`, Mach-O thin arm64. |
| P6 | `Info.plist` has `LSUIElement=true` and `NSAccessibilityUsageDescription` | ✅ PASS | Inspected; menubar-only app with AX usage string. |
| P7 | `DefaultBindings.spectacle` covers every `WindowAction` that expects a default | ✅ PASS | Covered by `PreferencesStoreTests.testDefaultBindingsHaveNoInternalConflict`. |
| P8 | No shortcut collisions in defaults | ✅ PASS | Same test. `.lastThird` (⌃⌥⌘→) and display jumps (⌃⌥⌘]/[) deliberately disambiguated per plan. |
| P9 | Preferences round-trip (set/clear/export/import) | ✅ PASS | `testShortcutCodableRoundTrip`, `testExportImportRoundTrip`, `testSetNilClearsBinding`, `testConflictDetection` all green. |

## Module wiring (code-review, programmatic)

| # | Wiring | Result |
|---|---|---|
| W1 | `WindowKitAppDelegate` composes `PreferencesStore`, `HotkeyManager`, `UndoStack(limit:20)`, `ActionRunner` as single shared instances | ✅ |
| W2 | `hotkeys.onAction` is set once in `applicationDidFinishLaunching` and routes to `runner.perform` | ✅ |
| W3 | `store.$bindings.dropFirst().sink` re-applies hotkeys on preference changes (gated by `hotkeysArmed`) | ✅ |
| W4 | `AccessibilityTrust.trustPublisher(interval: 1.0)` drives arm/disarm + onboarding show/hide | ✅ |
| W5 | `ActionRunner.performGeometry` converts `screen.visibleFrame` (Cocoa) → AX once, passes AX rect to `Geometry.targetFrame`, writes AX result via `AXWindow.setFrame` | ✅ |
| W6 | `.undo`/`.redo`/`.nextDisplay`/`.previousDisplay` branch to dedicated methods (they return `nil` from `Geometry.targetFrame`) | ✅ |
| W7 | `apply(target:window:current:)` guards `target != current`, pushes snapshot, clears redo, writes frame | ✅ |
| W8 | `PreferencesWindow(store:)` requires store injection (no default/global) | ✅ |

## Manual (⚠ requires human tester)

These steps must be performed on a real macOS 14+ session and ticked off before release.

| # | Scenario | Status |
|---|---|---|
| M1 | Double-click `build/WindowKit.app` → menu-bar icon appears, no Dock icon | ⚠ Not yet performed |
| M2 | First launch with AX not granted → Onboarding window appears, "Open System Settings" opens the correct pane | ⚠ |
| M3 | After granting AX → onboarding dismisses within ~1 s (poll interval) | ⚠ |
| M4 | Halves: focus a window, press ⌃⌥←/→/↑/↓ → window snaps correctly on primary display | ⚠ |
| M5 | Quadrants: ⌃⌥ 1/2/3/4 → correct corners | ⚠ |
| M6 | Thirds: ⌃⌥⌘ ←/↑/→ → left/center/right thirds | ⚠ |
| M7 | 3×3 grid: ⌘⌥ U/I/O/J/K/L/M/,/. → matches on-screen cell | ⚠ |
| M8 | Fullscreen ⌃⌥F, Center ⌃⌥C, Almost-max ⌃⌥= | ⚠ |
| M9 | Undo ⌃⌥Z restores previous frame; Redo ⌃⌥⇧Z reapplies | ⚠ |
| M10 | Multi-display: ⌃⌥⌘ ] / [ moves window across displays preserving proportional frame | ⚠ Requires ≥2 displays |
| M11 | Preferences → ⌘, opens window; rebinding a shortcut takes effect without relaunch | ⚠ |
| M12 | Assigning a conflicting shortcut clears it from the prior action and shows conflict marker | ⚠ |
| M13 | Revoking AX mid-session disarms hotkeys and re-shows onboarding | ⚠ |
| M14 | Quit via menu bar → process exits cleanly (no leaked Carbon event handlers observed via Console) | ⚠ |

## Known limitations / future work

- `UndoStack` is a single global stack, not per-window. Undoing after switching focus replays the last frame change on whatever window is currently focused. Acceptable for v0.1; per-window keying is tracked as future work.
- `ActionRunner.redoFrames` is kept in-process on the runner (UndoStack has no redo primitive). Redo is cleared whenever a new non-undo action runs — matches typical editor UX.
- Ad-hoc signature means every rebuild invalidates AX trust; README documents the re-grant workflow.
- Two `AXValueCreate`-related compiler warnings in `AXWindow.swift` pre-exist this task and are inherent to the Swift↔Carbon generic bridge.

## Bundle

- Path: `build/WindowKit.app`
- Identifier: `co.dotfun.WindowKit`
- Architecture: arm64 (Apple Silicon)
- Signature: ad-hoc
- Version: 0.1.0 (1)

---

# WindowKit v0.2 — Integration Verification

Date: 2026-04-19
Integrator: `integrator` (task #4)

v0.2 adds multi-tap cycles on the 3×3 grid keys, four new horizontal-band actions (`topThird`, `bottomThird`, `topTwoThirds`, `bottomTwoThirds`), a configurable tap-window preference (150–700 ms, default 400), dock-aware placement (via `NSScreen.visibleFrame`), and move-only fallback for non-resizable apps.

## Programmatic (v0.2)

| # | Check | Result | Evidence |
|---|---|---|---|
| P1 | `swift build` (debug) succeeds | ✅ PASS | Clean link, same two pre-existing `UnsafeRawPointer` warnings in `AXWindow.swift`. No new warnings. |
| P2 | `swift build -c release` succeeds | ✅ PASS | Via `scripts/build-app.sh`; `Build complete! (6.21s)`. |
| P3 | `swift test` — all targets | ✅ PASS | **56 tests, 0 failures** in 0.031 s. Breakdown: `WindowEngineTests` 33 · `PreferencesStoreTests` 9 · `HotkeyManagerTests.TapCyclesTests` 8 · `HotkeyManagerTests.TapDetectorTests` 6. |
| P4 | `.app` bundle assembles | ✅ PASS | `build/WindowKit.app` rebuilt cleanly. |
| P5 | `.app` launches without crashing | ✅ PASS | `open build/WindowKit.app` → process `WindowKit` appears in `System Events`; `killall WindowKit` cleanly terminates. |
| P6 | No duplicate/stale `tapWindowMs` declarations | ✅ PASS | Single definition in `Sources/PreferencesStore/PreferencesStore.swift:16` with clamp [150,700] and UserDefaults persistence under `WindowKit.tapWindowMs`. |

## Module wiring (v0.2, code-review)

| # | Wiring | Result |
|---|---|---|
| W1 | `PreferencesStore.tapWindowMs` → `HotkeyManager.tapWindowSeconds` closure wired in `WindowKitApp.applicationDidFinishLaunching` (reads fresh value per press, ms→s conversion) | ✅ |
| W2 | `HotkeyManager` hotkey callback → `TapDetector.register(action, window: tapWindowSeconds())` → 1-based tap count → `onAction(action, count)` | ✅ |
| W3 | `ActionRunner.perform(_:tapCount:)` → `TapCycles.resolve(action, tapCount:)` → branch on `.undo / .redo / nextDisplay / previousDisplay` or `performGeometry(resolved)` | ✅ |
| W4 | `performGeometry` feeds `screen.visibleFrame` (already dock-aware) via `CoordinateConverter.cocoaToAX` → `Geometry.targetFrame` → `AXWindow.setFrame(target)` | ✅ |
| W5 | `AXWindow.setFrame` sequences position→size→position, returns `SetFrameResult(positionApplied, sizeApplied)`; marked `@discardableResult` | ✅ |
| W6 | `ActionRunner.apply` discards `SetFrameResult` — no beep, no revert on `sizeApplied=false`. Move-only fallback for non-resizable apps is the intended silent behavior. | ✅ |
| W7 | `TapCycles.default` covers all 9 grid actions; wrap-after-last via modulo `((tapCount-1) % n + n) % n` | ✅ |
| W8 | Preferences UI "Tap Behavior" slider binds `store.tapWindowMs` (150…700, step 10); cycle captions rendered under each grid row | ✅ |

## Manual (v0.2, ⚠ requires human tester)

Numbered V2-M1..V2-M12 to avoid clashing with v0.1's M1–M14.

| # | Scenario | Status |
|---|---|---|
| V2-M1 | Launch rebuilt `build/WindowKit.app` → menu-bar icon, no Dock icon, no crash on cold start | ⚠ |
| V2-M2 | Preferences → new "Tap Behavior" card at top of Shortcuts tab; slider shows current ms value; dragging updates live | ⚠ |
| V2-M3 | Each of the 9 grid rows shows a small read-only caption listing its cycle steps (e.g., "1× cell · 2× 1/3 band · 3× half · 4× 2/3") | ⚠ |
| V2-M4 | Focus Safari. ⌘⌥U once → top-left 1/9 cell. ⌘⌥U again within 400 ms → top-left quadrant (1/4). Wait 1 s, press again → back to 1/9. | ⚠ |
| V2-M5 | ⌘⌥I four times rapidly → cycles 1/9 → top 1/3 → top 1/2 → top 2/3. 5th press within window wraps back to 1/9. | ⚠ |
| V2-M6 | ⌘⌥L three times rapidly → 1/9 → right 1/3 → right 1/2. | ⚠ |
| V2-M7 | ⌘⌥K twice rapidly → 1/9 → fullscreen. | ⚠ |
| V2-M8 | Set slider to 200 ms. Double-taps at ~300 ms gap now count as separate single-taps (each fires 1/9). | ⚠ |
| V2-M9 | Interleave ⌘⌥I then ⌘⌥, — each grid key maintains its own independent cycle state; no cross-contamination. | ⚠ |
| V2-M10 | **Dock awareness (pinned)**: with Dock pinned at bottom, ⌘⌥, → snapped window's bottom edge is flush with Dock's TOP edge, not the screen bottom. Repeat with Dock on left (⌘⌥J) and right (⌘⌥L). | ⚠ |
| V2-M11 | **Dock awareness (auto-hide)**: with auto-hide Dock, ⌘⌥, → window extends to screen bottom (expected); Dock overlays on hover (expected). | ⚠ |
| V2-M12 | **Non-resizable apps still move**: open a fixed-size System Settings pane and focus it. Press ⌘⌥U. Window MOVES to top-left 1/9 cell origin but keeps its intrinsic size. No beep, no error, no revert. | ⚠ |

## Bundle (v0.2)

- Path: `build/WindowKit.app`
- Identifier: `co.dotfun.WindowKit`
- Architecture: arm64 (Apple Silicon)
- Signature: ad-hoc
- Rebuilt: 2026-04-19
