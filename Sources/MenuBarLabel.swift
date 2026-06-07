import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject var zones: ZoneStore
    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var clock: ClockTicker

    var body: some View {
        let opts = ClockFormatOptions(
            useAMPM: prefs.useAMPM,
            showDate: prefs.showDate,
            showDay: prefs.showDay
        )

        if zones.identifiers.isEmpty {
            Text("🌐")
        } else {
            let parts: [String] = zones.identifiers.map { identifier in
                let iso = TimeZoneCatalog.shared.iso(for: identifier) ?? ""
                let flag = FlagEmoji.from(isoCode: iso)
                let tz = TimeZone(identifier: identifier) ?? .current
                let time = ClockFormatter.format(clock.now, in: tz, options: opts)
                return "\(flag) \(time)"
            }
            Text(parts.joined(separator: "  "))
        }
    }
}
