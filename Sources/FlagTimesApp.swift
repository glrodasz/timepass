import SwiftUI

@main
struct FlagTimesApp: App {
    @StateObject private var zones = ZoneStore()
    @StateObject private var prefs = PreferencesStore()
    @StateObject private var loginItem = LoginItemService()
    @StateObject private var clock = ClockTicker()

    var body: some Scene {
        MenuBarExtra {
            TimeZonePickerView()
                .environmentObject(zones)
                .environmentObject(prefs)
                .environmentObject(loginItem)
        } label: {
            MenuBarLabel()
                .environmentObject(zones)
                .environmentObject(prefs)
                .environmentObject(clock)
        }
        .menuBarExtraStyle(.window)
    }
}
