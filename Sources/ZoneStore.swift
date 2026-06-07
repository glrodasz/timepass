import Foundation
import SwiftUI

@MainActor
final class ZoneStore: ObservableObject {
    @Published private(set) var identifiers: [String]

    private let defaultsKey = "enabledZoneIdentifiers"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let stored = try? JSONDecoder().decode([String].self, from: data) {
            self.identifiers = stored
        } else {
            // Fresh install (no stored key yet): seed a sensible default so the
            // menu bar shows a real flag + time instead of just the 🌐 globe.
            self.identifiers = Self.defaultIdentifiers()
            persist()
        }
    }

    private static func defaultIdentifiers() -> [String] {
        let local = TimeZone.current.identifier
        // Only seed if the local zone maps to a country/flag in our catalog;
        // otherwise fall back to the empty state.
        if TimeZoneCatalog.shared.iso(for: local) != nil {
            return [local]
        }
        return []
    }

    func isEnabled(_ identifier: String) -> Bool {
        identifiers.contains(identifier)
    }

    func toggle(_ identifier: String) {
        if let index = identifiers.firstIndex(of: identifier) {
            identifiers.remove(at: index)
        } else {
            identifiers.append(identifier)
        }
        persist()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        identifiers.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func remove(at offsets: IndexSet) {
        identifiers.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(identifiers) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
