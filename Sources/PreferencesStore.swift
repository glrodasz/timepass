import SwiftUI

@MainActor
final class PreferencesStore: ObservableObject {
    @AppStorage("useAMPM") var useAMPM: Bool = false
    @AppStorage("showDate") var showDate: Bool = false
    @AppStorage("showDay") var showDay: Bool = false
}
