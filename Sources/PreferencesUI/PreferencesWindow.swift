import AppKit
import LayoutProfiles
import PreferencesStore
import SwiftUI
import WindowEngine

public struct PreferencesWindow: View {
    @ObservedObject private var store: PreferencesStore
    private let layouts: LayoutProfileStore

    public init(store: PreferencesStore, layouts: LayoutProfileStore) {
        self.store = store
        self.layouts = layouts
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                GridKeysCard(store: store)
                TapBehaviorCard(store: store)
                LayoutsCard(store: layouts)
            }
            .padding(20)
        }
        .frame(minWidth: 560, minHeight: 480)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            DotfunLogo(height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text("WindowKit")
                    .font(.title2.weight(.semibold))
                Text("Every layout comes from one grid: hold ⌃⌥⌘ and tap cells. There are no other shortcuts to learn.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

struct DotfunLogo: View {
    let height: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    private var resourceName: String {
        colorScheme == .dark ? "DotfunLogoDark" : "DotfunLogo"
    }

    /// Resolve the logo without ever reaching outside the app.
    ///
    /// SwiftPM's generated `Bundle.module` accessor checks
    /// `Bundle.main.bundleURL/<name>.bundle` and then an **absolute path into
    /// .build** — and `fatalError`s if neither exists. In an installed .app
    /// that means either reading from the source checkout at runtime (macOS
    /// prompts for the volume) or crashing outright when that volume is gone.
    /// So inside an .app we look only at our own Resources and accept the
    /// text fallback; `Bundle.module` is consulted only when running straight
    /// from SwiftPM, where it resolves locally.
    private var logoURL: URL? {
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "png") {
            return url
        }
        if let nested = Bundle.main.url(forResource: "WindowKit_PreferencesUI", withExtension: "bundle"),
           let bundle = Bundle(url: nested),
           let url = bundle.url(forResource: resourceName, withExtension: "png") {
            return url
        }
        guard Bundle.main.bundleURL.pathExtension != "app" else { return nil }
        return Bundle.module.url(forResource: resourceName, withExtension: "png")
    }

    var body: some View {
        if let url = logoURL,
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .accessibilityLabel("dotfun")
        } else {
            Text("dotfun")
                .font(.system(size: height * 0.8, weight: .heavy))
        }
    }
}

/// The grid card: the 10-key toggle, the keycaps it selects, and how to read them.
private struct GridKeysCard: View {
    @ObservedObject var store: PreferencesStore

    private var layout: SequenceKeyLayout { store.sequenceKeyLayout }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grid keys")
                .font(.headline)

            Toggle(isOn: $store.tenKeyAvailable) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Numeric keypad available")
                    Text(store.tenKeyAvailable
                         ? "Using the 10-key, which is already a 3×3 map of the screen."
                         : "Laptop mode — the grid moves to U/I/O · J/K/L · M/,/. under your right hand.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)

            Divider()

            GridDiagram(layout: layout)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

/// Mini 3×3 diagram of the active key set. Renders from `SequenceKeyLayout`, so
/// the keycaps shown are always the keys actually registered.
private struct GridDiagram: View {
    let layout: SequenceKeyLayout

    /// Example keys in prose, resolved through the layout rather than hardcoded.
    private var topLeft: String { layout.keycap(forDigit: 7) }
    private var center: String { layout.keycap(forDigit: 5) }
    private var topRight: String { layout.keycap(forDigit: 9) }
    private var bottomLeft: String { layout.keycap(forDigit: 1) }
    private var bottomRight: String { layout.keycap(forDigit: 3) }
    private var middleLeft: String { layout.keycap(forDigit: 4) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 3) {
                ForEach(Array(layout.keycapRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 3) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cap in
                            Text(cap)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .frame(width: 28, height: 22)
                                .background(Color(nsColor: .quaternaryLabelColor).opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("These keys are the screen")
                    .font(.caption.weight(.medium))
                Text("""
                     Hold ⌃⌥⌘ and tap cells, then release (or pause):
                     • One key → that 1/9 cell (\(topLeft) = top-left, \(center) = center).
                     • Two keys → the box between them: \(topLeft)·\(topRight) = top third, \(topLeft)·\(bottomLeft) = left third, \(topLeft)·\(center) = top-left 2×2, \(topLeft)·\(bottomRight) = fullscreen.
                     • Double-tap an edge for a half (\(middleLeft)·\(middleLeft) = left), a corner for a quarter (\(topLeft)·\(topLeft)). \(center)·\(center) = maximize.
                     """)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

/// "Tap Behavior" card: how long a sequence stays open before it commits.
private struct TapBehaviorCard: View {
    @ObservedObject var store: PreferencesStore

    private var tapWindowBinding: Binding<Double> {
        Binding(
            get: { Double(store.tapWindowMs) },
            set: { store.tapWindowMs = Int($0.rounded()) }
        )
    }

    private var example: String {
        let l = store.sequenceKeyLayout
        return "\(l.keycap(forDigit: 7)) then \(l.keycap(forDigit: 3))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sequence timing")
                .font(.headline)

            Text("When you type a region (e.g. \(example)), WindowKit snaps as soon as you release ⌃⌥⌘ — or after this pause, whichever comes first.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Text("Tap window")
                    .frame(width: 100, alignment: .leading)
                Slider(value: tapWindowBinding, in: Double(PreferencesStore.tapWindowMinMs)...Double(PreferencesStore.tapWindowMaxMs), step: 10)
                Text("\(store.tapWindowMs) ms")
                    .font(.body.monospacedDigit())
                    .frame(width: 70, alignment: .trailing)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}
