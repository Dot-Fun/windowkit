# WindowKit

A native macOS Spectacle-style window manager by [dotfun](https://dotfun.co). Menubar utility that snaps the focused window to halves, quadrants, thirds, sixths, a 3×3 spatial grid, fullscreen, and across displays via global hotkeys.

<p align="center">
  <img src="docs/images/dotfun-windowkit-menu.png" alt="WindowKit menubar menu" width="300" />
  &nbsp;&nbsp;
  <img src="docs/images/dotfun-windowkit-preferences.png" alt="WindowKit preferences window" width="420" />
</p>

**License**: Apache 2.0 — see [`LICENSE`](LICENSE). Provided "as is", without warranty of any kind, express or implied. The authors and dotfun are not liable for any damages arising from use of this software.

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

### Multi-tap cycles

Each 3×3 grid key starts a cycle. Tapping the same key again within the **tap window** (default 700 ms, configurable 150 ms – 1 s in **Preferences → Shortcuts → Tap Behavior**) advances to a larger size anchored at that position. After the last step, another tap wraps back to the 1/9 cell. After the tap window elapses with no press, the counter resets and the next tap is a 1-tap again.

| Position | Keys | Cycle (1-tap → last) |
|---|---|---|
| Corners | U, O, M, . | 1/9 cell → matching quadrant |
| Top / bottom edges | I, , | 1/9 cell → top/bottom 1/3 band → top/bottom 1/2 → top/bottom 2/3 |
| Side edges | J, L | 1/9 cell → left/right 1/3 column → left/right 1/2 → left/right 2/3 |
| Center | K | 1/9 cell → fullscreen |

Tapping a *different* key resets the cycle — each key tracks its own counter.

### Known behaviors

- **Non-resizable apps** (e.g. System Settings panels) will be **moved** to the target location but keep their intrinsic size. WindowKit does not beep or error on move-only outcomes.
- **The Dock is respected** — snapped windows will not overlap a pinned Dock. The target frame is computed against `NSScreen.visibleFrame`, which excludes the Dock and menu bar.
- **Auto-hide Dock** lets windows use the full screen; the Dock overlays on hover (standard macOS behavior).

## Permissions

WindowKit requires **Accessibility** access to query and set frames of other apps' windows via `AXUIElement`. Without it, no hotkeys will take effect. On first launch the app shows an onboarding window with a button that opens **System Settings → Privacy & Security → Accessibility**.

### Unsigned-build caveat

Because this build is unsigned (and ad-hoc signatures change on every rebuild), macOS treats each new build of `WindowKit.app` as a distinct identity for Accessibility purposes. **After every rebuild you must:**

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Remove any stale `WindowKit` entry.
3. Add the freshly built `WindowKit.app` and enable its toggle.

The onboarding window reappears whenever trust is revoked or invalidated, and hotkeys automatically disarm until trust is restored.

## Known app compatibility

- **Fully supported**: all native Cocoa apps (Finder, Safari, iTerm, Xcode, Terminal, Preview, Mail, Messages, etc.).
- **Electron / Chromium apps** (Chrome, Discord, Cursor, VSCode, Slack, etc.): supported via a multi-tier window resolver and a one-time `AXEnhancedUserInterface` nudge per app per launch. The first hotkey press on such an app may feel ~30 ms slower while Chromium rebuilds its AX tree; subsequent presses are instant.
- **Fixed-size apps** (EMEET Studio, System Settings panels, 1Password mini, Spotify mini): these will be **moved** to the target cell's origin but keep their intrinsic size — by design. No beep, no error.
- **Apps running as root or with full-screen space privileges** (most games, some installers): unreachable via the Accessibility API. This is a macOS limitation, not a WindowKit bug.

If a specific app doesn't respond, open the menubar menu → **Debug → Copy Focused Window Info** and share the clipboard contents — it contains the bundle ID, AX role/subrole, and which attributes are settable, which is enough to triage.

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
