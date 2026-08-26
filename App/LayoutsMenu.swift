import LayoutProfiles
import SwiftUI

/// Menubar "Layouts" submenu: one-click restore per profile, quick save with a
/// default name (rename in Preferences), and a jump to the management card.
struct LayoutsMenu: View {
    @ObservedObject var store: LayoutProfileStore
    var onManage: () -> Void

    var body: some View {
        Menu("Layouts") {
            if store.profiles.isEmpty {
                Text("No saved layouts")
            }
            ForEach(store.profiles) { profile in
                Button(profile.name) {
                    LayoutEngine.restore(profile)
                }
                .disabled(!profile.signature.matches(.current()))
            }
            Divider()
            Button("Save Current Windows as Layout") {
                store.add(LayoutEngine.makeProfile(name: "Layout \(store.profiles.count + 1)"))
            }
            Button("Manage Layouts…") {
                onManage()
            }
        }
    }
}
