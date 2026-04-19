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
