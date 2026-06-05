import Foundation

struct ClockFormatOptions: Hashable {
    var useAMPM: Bool
    var showDate: Bool
    var showDay: Bool
}

enum ClockFormatter {
    private static var cache: [String: DateFormatter] = [:]

    static func format(_ date: Date, in timeZone: TimeZone, options: ClockFormatOptions) -> String {
        let key = "\(timeZone.identifier)|\(options.useAMPM)|\(options.showDate)|\(options.showDay)"
        let formatter: DateFormatter
        if let cached = cache[key] {
            formatter = cached
        } else {
            formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = timeZone

            var pattern = ""
            if options.showDay {
                pattern += "EEE "
            }
            if options.showDate {
                pattern += "MMM d "
            }
            pattern += options.useAMPM ? "h:mm a" : "HH:mm"
            formatter.dateFormat = pattern
            cache[key] = formatter
        }

        return formatter.string(from: date)
    }
}
