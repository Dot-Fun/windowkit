import SwiftUI
import PreferencesStore

public struct ShortcutRecorderView: View {
    @Binding public var shortcut: Shortcut?

    public init(shortcut: Binding<Shortcut?>) {
        self._shortcut = shortcut
    }

    public var body: some View {
        // TODO: implement in ui-dev task.
        Text("Record…")
    }
}
