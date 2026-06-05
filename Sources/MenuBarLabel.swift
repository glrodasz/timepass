import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject var zones: ZoneStore
    @EnvironmentObject var prefs: PreferencesStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
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
                    let time = ClockFormatter.format(context.date, in: tz, options: opts)
                    return "\(flag) \(time)"
                }
                Text(parts.joined(separator: "  "))
            }
        }
    }
}
