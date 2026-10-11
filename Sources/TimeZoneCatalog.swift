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
    private let searchIndex: [SearchEntry]

    private struct SearchEntry {
        let country: CountryEntry
        let words: [String]
        let zones: [(identifier: String, words: [String])]
    }

    private init() {
        let countries = Self.loadCatalog()
        let sorted = countries.sorted { $0.localizedName.localizedCompare($1.localizedName) == .orderedAscending }
        self.countries = sorted

        var map: [String: String] = [:]
        for country in countries {
            for zone in country.zones {
                map[zone] = country.iso
            }
        }
        self.zoneToISO = map
        self.searchIndex = sorted.map { Self.searchEntry(for: $0) }
    }

    func iso(for zoneIdentifier: String) -> String? {
        zoneToISO[zoneIdentifier]
    }

    /// Matches country names, ISO codes and zone identifiers word by word, so
    /// "new york" finds "America/New_York" and "united states york" narrows to it.
    /// Falls back to mid-word and typo-tolerant matching ("new yrok") only when
    /// no word starts with the query.
    func search(_ query: String) -> [CountryEntry] {
        let tokens = FuzzySearch.words(query)
        guard !tokens.isEmpty else { return countries }

        let exact = matches(tokens, using: FuzzySearch.prefixesAll)
        return exact.isEmpty ? matches(tokens, using: FuzzySearch.approximatelyMatchesAll) : exact
    }

    private func matches(_ tokens: [String], using match: ([String], [String]) -> Bool) -> [CountryEntry] {
        searchIndex.compactMap { entry in
            if match(tokens, entry.words) {
                return entry.country
            }
            let hits = entry.zones.filter { match(tokens, $0.words) }.map { $0.identifier }
            return hits.isEmpty ? nil : CountryEntry(iso: entry.country.iso, zones: hits)
        }
    }

    private static let aliases: [String: [String]] = [
        "US": ["usa"],
        "GB": ["uk", "britain", "england"],
        "AE": ["uae"],
    ]

    private static func searchEntry(for country: CountryEntry) -> SearchEntry {
        let countryWords = FuzzySearch.withJoinedRuns(FuzzySearch.words(country.localizedName))
            + [country.iso.lowercased()]
            + (aliases[country.iso] ?? [])
        let zones: [(identifier: String, words: [String])] = country.zones.map { zone in
            (identifier: zone, words: FuzzySearch.withJoinedRuns(FuzzySearch.words(zone)) + countryWords)
        }
        return SearchEntry(country: country, words: countryWords, zones: zones)
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
