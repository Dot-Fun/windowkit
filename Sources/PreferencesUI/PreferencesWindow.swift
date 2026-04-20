import AppKit
import PreferencesStore
import SwiftUI
import WindowEngine

public struct PreferencesWindow: View {
    @StateObject private var model: PreferencesViewModel
    @ObservedObject private var store: PreferencesStore

    public init(store: PreferencesStore) {
        self.store = store
        _model = StateObject(wrappedValue: PreferencesViewModel(store: store))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                TapBehaviorCard(store: store)

                ForEach(ActionCatalog.groups) { group in
                    ActionGroupSection(
                        group: group,
                        bindings: model.bindings,
                        conflicts: model.conflicts,
                        onShortcutChange: { action, sc in
                            model.set(sc, for: action)
                        }
                    )
                }
            }
            .padding(20)
        }
        .frame(minWidth: 560, minHeight: 560)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            DotfunLogo(height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text("Keyboard Shortcuts")
                    .font(.title2.weight(.semibold))
                Text("Click a shortcut field, then press the key combination you want. Press ⌫ to clear, ⎋ to cancel.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
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

    var body: some View {
        if let url = Bundle.module.url(forResource: resourceName, withExtension: "png"),
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

@MainActor
final class PreferencesViewModel: ObservableObject {
    @Published var bindings: [WindowAction: Shortcut]
    @Published var conflicts: Set<WindowAction> = []

    private let store: PreferencesStore

    init(store: PreferencesStore) {
        self.store = store
        store.load()
        self.bindings = store.bindings
        recomputeConflicts()
    }

    func set(_ shortcut: Shortcut?, for action: WindowAction) {
        if let sc = shortcut {
            for (other, existing) in bindings where other != action && existing == sc {
                bindings[other] = nil
                store.set(nil, for: other)
            }
            bindings[action] = sc
        } else {
            bindings[action] = nil
        }
        store.set(shortcut, for: action)
        store.save()
        recomputeConflicts()
    }

    private func recomputeConflicts() {
        var seen: [Shortcut: [WindowAction]] = [:]
        for (action, sc) in bindings {
            seen[sc, default: []].append(action)
        }
        conflicts = Set(seen.values.filter { $0.count > 1 }.flatMap { $0 })
    }
}

private struct ActionGroupSection: View {
    let group: ActionGroup
    let bindings: [WindowAction: Shortcut]
    let conflicts: Set<WindowAction>
    let onShortcutChange: (WindowAction, Shortcut?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.title)
                    .font(.headline)
                if let subtitle = group.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if group.showsGridDiagram {
                ThreeByThreeGridDiagram()
                    .padding(.bottom, 4)
            }

            VStack(spacing: 0) {
                ForEach(Array(group.actions.enumerated()), id: \.element) { index, action in
                    if index > 0 { Divider() }
                    ActionRow(
                        action: action,
                        shortcut: bindings[action],
                        hasConflict: conflicts.contains(action),
                        onChange: { sc in onShortcutChange(action, sc) }
                    )
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }
}

private struct ActionRow: View {
    let action: WindowAction
    let shortcut: Shortcut?
    let hasConflict: Bool
    let onChange: (Shortcut?) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ActionCatalog.displayName(for: action))
                    .font(.body)
                if let caption = ActionCatalog.cycleCaption(for: action) {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if hasConflict {
                    Label("Conflicts with another shortcut", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            ShortcutRecorderView(shortcut: Binding(
                get: { shortcut },
                set: { onChange($0) }
            ))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Mini 3×3 diagram showing the U/I/O, J/K/L, M/,/. spatial mapping.
private struct ThreeByThreeGridDiagram: View {
    private let labels: [[String]] = [
        ["U", "I", "O"],
        ["J", "K", "L"],
        ["M", ",", "."],
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { col in
                            Text(labels[row][col])
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
                Text("3×3 Spatial Layout")
                    .font(.caption.weight(.medium))
                Text("Each key snaps the focused window to that cell. The keys mirror the cell's position on screen — top-left U, center K, bottom-right period.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// "Tap Behavior" card: explains multi-tap cycles and exposes the tap-window slider.
private struct TapBehaviorCard: View {
    @ObservedObject var store: PreferencesStore

    private var tapWindowBinding: Binding<Double> {
        Binding(
            get: { Double(store.tapWindowMs) },
            set: { store.tapWindowMs = Int($0.rounded()) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Multi-tap cycles")
                .font(.headline)

            Text("Tap the same spatial key again within the window below to cycle through larger sizes at that position. After the last step, another tap wraps back to the smallest.")
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
