import SwiftUI

enum PickerScope: String, CaseIterable, Identifiable {
    case all = "All"
    case enabled = "Enabled"
    var id: String { rawValue }
}

struct TimeZonePickerView: View {
    @EnvironmentObject var zones: ZoneStore
    @EnvironmentObject var prefs: PreferencesStore

    @State private var query: String = ""
    @State private var scope: PickerScope = .all
    @State private var expandedISO: String?

    private var results: [CountryEntry] {
        let base = TimeZoneCatalog.shared.search(query)
        switch scope {
        case .all:
            return base
        case .enabled:
            return base.compactMap { country in
                let kept = country.zones.filter { zones.isEnabled($0) }
                return kept.isEmpty ? nil : CountryEntry(iso: country.iso, zones: kept)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Divider()

            list

            Divider()

            footer
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .frame(width: 320, height: 460)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search", text: $query)
                .textFieldStyle(.plain)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1.5)
        )
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if results.isEmpty {
                    Text("No matches")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(results) { country in
                        countrySection(country)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func countrySection(_ country: CountryEntry) -> some View {
        let isExpanded = expandedISO == country.iso || country.zones.count == 1 || !query.isEmpty

        Button {
            if country.zones.count == 1 {
                zones.toggle(country.zones[0])
            } else if expandedISO == country.iso {
                expandedISO = nil
            } else {
                expandedISO = country.iso
            }
        } label: {
            HStack(spacing: 8) {
                Text(country.flag).font(.system(size: 16))
                Text(country.localizedName)
                    .foregroundStyle(.primary)
                Spacer()
                if country.zones.count == 1 {
                    Toggle("", isOn: Binding(
                        get: { zones.isEnabled(country.zones[0]) },
                        set: { _ in zones.toggle(country.zones[0]) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                } else {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if isExpanded && country.zones.count > 1 {
            ForEach(country.zones, id: \.self) { zone in
                zoneRow(zone)
            }
        }
    }

    private func zoneRow(_ identifier: String) -> some View {
        let tz = TimeZone(identifier: identifier) ?? .current
        let opts = ClockFormatOptions(useAMPM: prefs.useAMPM, showDate: false, showDay: false)
        let time = ClockFormatter.format(.now, in: tz, options: opts)
        let pretty = identifier.replacingOccurrences(of: "_", with: " ")

        return Button {
            zones.toggle(identifier)
        } label: {
            HStack {
                Text("\(pretty) (\(time))")
                    .foregroundStyle(zones.isEnabled(identifier) ? Color.accentColor : .secondary)
                    .font(.system(size: 12))
                Spacer()
                if zones.isEnabled(identifier) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .font(.caption)
                }
            }
            .padding(.leading, 36)
            .padding(.trailing, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var footer: some View {
        HStack {
            Menu {
                PreferencesMenuContent()
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Spacer()

            Picker("", selection: $scope) {
                ForEach(PickerScope.allCases) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
    }
}
