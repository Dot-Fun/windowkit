import AppKit
import LayoutProfiles
import SwiftUI

/// "Window Layouts" card: save the current windows under a name, restore or
/// update saved layouts, and opt profiles into auto-restore on display
/// reconnect.
public struct LayoutsCard: View {
    @ObservedObject var store: LayoutProfileStore
    @State private var newName: String = ""
    @State private var feedback: String?

    public init(store: LayoutProfileStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Window Layouts")
                .font(.headline)

            Text("A layout saves the position of every visible window (all displays, the Spaces you're currently on). macOS can't reach windows on hidden Spaces, so make one layout per Space — switch to it, save, and later switch to it and restore.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !store.profiles.isEmpty {
                VStack(spacing: 0) {
                    ForEach(store.profiles) { profile in
                        if profile.id != store.profiles.first?.id { Divider() }
                        LayoutRow(store: store, profile: profile, feedback: $feedback)
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            }

            HStack(spacing: 8) {
                TextField("Name — e.g. Monitor 1: Space A", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveNew)
                Button("Save Current Windows") { saveNew() }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let feedback {
                Text(feedback)
                    .font(.caption)
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

    private func saveNew() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let profile = LayoutEngine.makeProfile(name: name)
        store.add(profile)
        newName = ""
        feedback = "Saved “\(name)” — \(profile.windows.count) windows."
    }
}

private struct LayoutRow: View {
    @ObservedObject var store: LayoutProfileStore
    let profile: LayoutProfile
    @Binding var feedback: String?

    private var signatureMatches: Bool {
        profile.signature.matches(.current())
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                TextField("Name", text: Binding(
                    get: { profile.name },
                    set: { store.rename(id: profile.id, to: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.body)

                Text(detailLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if !signatureMatches {
                    Label("Saved on a different display setup", systemImage: "display.trianglebadge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Toggle("Auto", isOn: Binding(
                get: { profile.autoRestore },
                set: { store.setAutoRestore(id: profile.id, $0) }
            ))
            .toggleStyle(.checkbox)
            .help("Restore this layout automatically a few seconds after its display arrangement reconnects (wake from sleep, cable re-plug).")

            Button("Restore") {
                let outcome = LayoutEngine.restore(profile)
                feedback = "Restored “\(profile.name)” — \(outcome.moved) moved, \(outcome.alreadyInPlace) already in place\(outcome.unmatched > 0 ? ", \(outcome.unmatched) not found" : "")."
            }
            .disabled(!signatureMatches)

            Menu {
                Button("Update With Current Windows") {
                    let windows = LayoutEngine.captureRecords()
                    store.replaceWindows(id: profile.id, windows: windows, signature: .current())
                    feedback = "Updated “\(profile.name)” — \(windows.count) windows."
                }
                Divider()
                Button("Delete", role: .destructive) {
                    store.remove(id: profile.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var detailLine: String {
        let date = profile.savedAt.formatted(date: .abbreviated, time: .shortened)
        return "\(profile.windows.count) windows · \(profile.signature.summary) · saved \(date)"
    }
}
