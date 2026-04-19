# WindowKit

A native macOS Spectacle-style window manager. Menubar utility that snaps the focused window to halves, quadrants, thirds, sixths, fullscreen, and across displays via global hotkeys.

## Requirements

- macOS 14+
- Swift 5.9+ / Xcode 15+
- Accessibility permission (for moving windows of other apps)

## Build

```bash
swift build -c release
```

Or open `Package.swift` in Xcode and build the `WindowKit` scheme.

## Run

```bash
swift run WindowKit
```

On first launch, the app will prompt for Accessibility access. Grant it in **System Settings → Privacy & Security → Accessibility**.

## Test

```bash
swift test
```

## Project Layout

- `App/` — SwiftUI `@main` app (MenuBarExtra), `Info.plist`, assets
- `Sources/WindowEngine/` — pure `Geometry`, `AXWindow` wrapper, `ScreenResolver`
- `Sources/HotkeyManager/` — Carbon global hotkeys
- `Sources/PreferencesStore/` — `Shortcut` model + `UserDefaults` persistence
- `Sources/PreferencesUI/` — Preferences window, shortcut recorder, onboarding
- `Sources/PermissionsCoordinator/` — Accessibility trust checks
- `Sources/UndoStack/` — per-window frame history
- `Tests/WindowEngineTests/` — geometry unit tests

## Permissions

WindowKit requires **Accessibility** access to query and set frames of other apps' windows via `AXUIElement`. Without it, no hotkeys will take effect.

## Distribution

Unsigned local build. Not notarized.
