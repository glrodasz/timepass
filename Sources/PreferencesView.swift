import SwiftUI

struct PreferencesMenuContent: View {
    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var loginItem: LoginItemService

    var body: some View {
        Toggle("AM/PM", isOn: $prefs.useAMPM)
        Toggle("Show Date", isOn: $prefs.showDate)
        Toggle("Show Day", isOn: $prefs.showDay)

        Divider()

        Toggle("Start at Login", isOn: Binding(
            get: { loginItem.isEnabled },
            set: { loginItem.setEnabled($0) }
        ))

        Divider()

        Button("Quit Flag Times") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
