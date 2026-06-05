import Foundation

struct CountryEntry: Identifiable, Hashable {
    let iso: String
    let zones: [String]
    var id: String { iso }

    var localizedName: String {
        Locale.current.localizedString(forRegionCode: iso) ?? iso
    }

    var flag: String { FlagEmoji.from(isoCode: iso) }
}

struct ZoneRow: Identifiable, Hashable {
    let identifier: String
    let iso: String
    var id: String { identifier }

    var flag: String { FlagEmoji.from(isoCode: iso) }

    var prettyLabel: String {
        identifier.replacingOccurrences(of: "_", with: " ")
    }
}

@MainActor
final class TimeZoneCatalog {
    static let shared = TimeZoneCatalog()

    let countries: [CountryEntry]
    private let zoneToISO: [String: String]

    private init() {
        let countries = Self.loadCatalog()
        self.countries = countries.sorted { $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending }

        var map: [String: String] = [:]
        for country in countries {
            for zone in country.zones {
                map[zone] = country.iso
            }
        }
        self.zoneToISO = map
    }

    func iso(for zoneIdentifier: String) -> String? {
        zoneToISO[zoneIdentifier]
    }

    func search(_ query: String) -> [CountryEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return countries }
        let needle = trimmed.lowercased()

        return countries.compactMap { country in
            let nameMatch = country.localizedName.lowercased().contains(needle)
            let isoMatch = country.iso.lowercased().contains(needle)
            let zoneHits = country.zones.filter { $0.lowercased().contains(needle) }

            if nameMatch || isoMatch {
                return country
            }
            if !zoneHits.isEmpty {
                return CountryEntry(iso: country.iso, zones: zoneHits)
            }
            return nil
        }
    }

    private static func loadCatalog() -> [CountryEntry] {
        guard let url = Bundle.main.url(forResource: "timezone_catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("timezone_catalog.json missing from bundle")
            return []
        }

        struct RawEntry: Decodable {
            let iso: String
            let zones: [String]
        }

        do {
            let raw = try JSONDecoder().decode([RawEntry].self, from: data)
            return raw.map { CountryEntry(iso: $0.iso, zones: $0.zones) }
        } catch {
            assertionFailure("Failed to decode timezone_catalog.json: \(error)")
            return []
        }
    }
}
