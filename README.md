# WindowKit

A native macOS Spectacle-style window manager. Menubar utility that snaps the focused window to halves, quadrants, thirds, sixths, a 3×3 spatial grid, fullscreen, and across displays via global hotkeys.

## Requirements

- macOS 14+
- Swift 5.9+ / Xcode 15+
- Accessibility permission (for moving windows of other apps)

## Build

```bash
swift build -c release
```

Or open `Package.swift` in Xcode and build the `WindowKit` scheme.

### Package as .app

```bash
scripts/build-app.sh
```

Produces `build/WindowKit.app`. Double-click to launch; a menu-bar icon appears (the app is `LSUIElement`, no Dock presence).

## Run (dev)

```bash
swift run WindowKit
```

## Test

```bash
swift test
```

## Default Hotkeys

Legend: ⌃ = Control, ⌥ = Option, ⌘ = Command, ⇧ = Shift.

### Halves
| Action | Shortcut |
|---|---|
| Left half | ⌃⌥ ← |
| Right half | ⌃⌥ → |
| Top half | ⌃⌥ ↑ |
| Bottom half | ⌃⌥ ↓ |

### Quadrants
| Action | Shortcut |
|---|---|
| Top-left | ⌃⌥ 1 |
| Top-right | ⌃⌥ 2 |
| Bottom-left | ⌃⌥ 3 |
| Bottom-right | ⌃⌥ 4 |

### Thirds
| Action | Shortcut |
|---|---|
| First third | ⌃⌥⌘ ← |
| Center third | ⌃⌥⌘ ↑ |
| Last third | ⌃⌥⌘ → |

### 3×3 Spatial Grid (⌘⌥ + key)
Keys mirror the cell's on-screen position:

```
U I O
J K L
M , .
```

| Action | Shortcut |
|---|---|
| Top-left | ⌘⌥ U |
| Top-center | ⌘⌥ I |
| Top-right | ⌘⌥ O |
| Middle-left | ⌘⌥ J |
| Middle-center | ⌘⌥ K |
| Middle-right | ⌘⌥ L |
| Bottom-left | ⌘⌥ M |
| Bottom-center | ⌘⌥ , |
| Bottom-right | ⌘⌥ . |

### Sizing
| Action | Shortcut |
|---|---|
| Fullscreen | ⌃⌥ F |
| Center | ⌃⌥ C |
| Almost maximize (90%) | ⌃⌥ = |

### History
| Action | Shortcut |
|---|---|
| Undo window change | ⌃⌥ Z |
| Redo | ⌃⌥⇧ Z |

### Displays
| Action | Shortcut |
|---|---|
| Move to next display | ⌃⌥⌘ ] |
| Move to previous display | ⌃⌥⌘ [ |

All shortcuts are configurable in **Preferences → Keyboard Shortcuts** (⌘, from the menu bar).

## Permissions

WindowKit requires **Accessibility** access to query and set frames of other apps' windows via `AXUIElement`. Without it, no hotkeys will take effect. On first launch the app shows an onboarding window with a button that opens **System Settings → Privacy & Security → Accessibility**.

### Unsigned-build caveat

Because this build is unsigned (and ad-hoc signatures change on every rebuild), macOS treats each new build of `WindowKit.app` as a distinct identity for Accessibility purposes. **After every rebuild you must:**

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Remove any stale `WindowKit` entry.
3. Add the freshly built `WindowKit.app` and enable its toggle.

The onboarding window reappears whenever trust is revoked or invalidated, and hotkeys automatically disarm until trust is restored.

## Project Layout

- `App/` — SwiftUI `@main` app (MenuBarExtra), `ActionRunner`, `Info.plist`, assets
- `Sources/WindowEngine/` — pure `Geometry`, `AXWindow` wrapper, `ScreenResolver`, coordinate converter
- `Sources/HotkeyManager/` — Carbon global hotkeys
- `Sources/PreferencesStore/` — `Shortcut` model, `UserDefaults` persistence, default bindings
- `Sources/PreferencesUI/` — Preferences window, shortcut recorder, onboarding
- `Sources/PermissionsCoordinator/` — Accessibility trust checks + publisher
- `Sources/UndoStack/` — window frame history
- `Tests/WindowEngineTests/` — geometry unit tests
- `Tests/PreferencesStoreTests/` — store/shortcut tests
- `scripts/build-app.sh` — release bundle assembly

## Distribution

Unsigned local build. Not notarized. See unsigned-build caveat above.
