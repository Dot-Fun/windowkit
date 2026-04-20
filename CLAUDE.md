# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# WindowKit — Claude notes

Native macOS window manager. SwiftPM project; the app target is `WindowKit` (in `App/`), libraries live under `Sources/`.

## Build + run

```
swift build                              # debug
swift test                               # 56 tests
swift test --filter GeometryTests        # single test class / method
scripts/build-app.sh                     # release build + assembles build/WindowKit.app
open build/WindowKit.app
```

No Xcode project — open `Package.swift` in Xcode if you want the IDE experience.

## 🚨 CRITICAL: After every rebuild, remind the user to re-grant Accessibility

The build is **unsigned / ad-hoc signed**. Every rebuild produces a fresh code identity. macOS's TCC (Privacy) database keeps the stale grant with the toggle showing ON in System Settings, but the kernel rejects real AX calls — hotkeys fire silently into the void.

**Whenever you rebuild `WindowKit.app` or tell the user to rebuild, proactively instruct them BEFORE they test:**

1. System Settings → Privacy & Security → Accessibility
2. Select **WindowKit** → click the **−** button to remove it
3. `killall WindowKit`
4. Drag `/Users/alvinycheung/sandbox/windowkit/build/WindowKit.app` back into the list
5. Toggle it on

Do not say "try it now" after a rebuild. Say "do the re-grant dance first, then try it."

The app now detects this state and shows a `StaleGrantView` window (orange warning) with the same instructions, but you should warn up-front to save a cycle.

This is intrinsic to unsigned macOS dev builds. It will go away if/when the app is signed with a stable Apple Developer ID.

## Brand

dotfun orange: `Color(red: 0.97, green: 0.32, blue: 0.12)` — exposed as `dotfunOrange` in `App/WindowKitApp.swift`. Menubar icon and Preferences logo use this color. Logo PNG lives at `Sources/PreferencesUI/Resources/DotfunLogo.png` and is bundled via the `PreferencesUI` target's `resources:` directive.

## Architecture quick map

- `Sources/WindowEngine/` — pure geometry + AX wrapper (no app-level state). `Geometry.targetFrame(for:screen:current:)` is the heart.
- `Sources/HotkeyManager/` — Carbon `RegisterEventHotKey` + `TapDetector` for multi-tap cycles (`TapCycles.resolve`).
- `Sources/PreferencesStore/` — `UserDefaults`-backed `ObservableObject`; `DefaultBindings.spectacle`, `tapWindowMs`.
- `Sources/PermissionsCoordinator/` — `AccessibilityTrust.statePublisher` → `.functional / .stale / .denied`. `TrustCanary` probes with a real AX call so stale grants surface.
- `Sources/PreferencesUI/` — SwiftUI Preferences window, `ShortcutRecorderView` (NSViewRepresentable), onboarding, stale-grant warning, About.
- `Sources/UndoStack/` — per-session window frame history.
- `App/WindowKitApp.swift` — composition root, `MenuBarExtra`, `LaunchAtLogin` via `SMAppService`.
- `App/ActionRunner.swift` — orchestrates WindowAction → AX write. Reconciles AX (top-left) vs NSScreen (bottom-left) coords via `CoordinateConverter`.

## License

Apache 2.0 (see `LICENSE`). Not our problem if someone yeets their windows off-screen.
