# Flag Times

A native Apple Silicon menu bar app that shows multiple timezones, each with its country flag and current time.

Replaces older non-ARM "world clock" menu bar utilities. Pure AppKit `NSStatusItem` for the menu bar item, SwiftUI hosted in an `NSPopover` for the picker UI. No Electron, no Chromium.

## Requirements

- macOS 13.0+ (Ventura)
- **Xcode 15+** (full Xcode.app — Command Line Tools alone are not enough). Install from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & run

```sh
brew install xcodegen        # first time only
xcodegen generate            # produces FlagTimes.xcodeproj
open FlagTimes.xcodeproj     # ⌘R in Xcode
```

Or from the command line:

```sh
xcodebuild -project FlagTimes.xcodeproj -scheme FlagTimes -configuration Release build
```

To install for daily use:

1. Product → Archive → Distribute App → Custom → Copy App → drag into `/Applications`.
2. First launch: right-click → Open (Gatekeeper accepts unsigned builds with explicit consent).

## Features

- Searchable country/timezone picker
- Multiple flag + time entries in the menu bar
- AM/PM, Show Date, Show Day toggles
- Start at Login (modern `SMAppService`)

## Architecture

| File | Role |
|---|---|
| `Sources/main.swift` | Pure-AppKit entry point: `NSApplication.shared.run()` after wiring `AppDelegate`. No SwiftUI `App`/`Settings` scene — that wrapper turns `NSStatusItem` into `NSSceneStatusItem` and triggers placement bugs on macOS 26. |
| `Sources/AppDelegate.swift` | Owns the `NSStatusItem`, a 30 s `Timer`, the lazy `NSPopover`, and the three `ObservableObject`s. Updates the menu bar title on timer ticks and on `objectWillChange` from `ZoneStore` / `PreferencesStore`. |
| `Sources/ZoneStore.swift` | Persisted list of enabled zone identifiers (UserDefaults). Seeds the local zone on first launch. |
| `Sources/TimeZoneCatalog.swift` | Loads `Resources/timezone_catalog.json`, maps IANA zone → ISO 3166-1 alpha-2, powers picker search. |
| `Sources/TimeZonePickerView.swift` | SwiftUI picker shown inside the popover. |
| `Sources/PreferencesStore.swift` | `@AppStorage` toggles for AM/PM, date, weekday. |
| `Sources/PreferencesView.swift` | SwiftUI menu shown via the gear button in the picker footer. |
| `Sources/LoginItemService.swift` | `SMAppService` wrapper for "start at login". |
| `Sources/ClockFormatter.swift` | Cached `DateFormatter`s for the menu bar title. |
| `Sources/FlagEmoji.swift` | ISO alpha-2 → Unicode flag emoji. |
| `Resources/Info.plist` | `LSUIElement=true` (no Dock icon). |
| `Resources/timezone_catalog.json` | Generated catalog of countries → IANA zones. |
| `Scripts/generate_catalog.sh` | Regenerator for the catalog. |
| `project.yml` | XcodeGen config — single source of truth. |

## macOS 26 notes

Two non-obvious workarounds live in this project. Both are documented in the code next to where they're applied; this section explains the why.

1. **The status item carries an empty 1×1 image** (`AppDelegate.applicationDidFinishLaunching`). On macOS 26, title-only `NSStatusItem`s are sometimes placed inside the system-icons slot (right of the Control Center pill) instead of the third-party status zone, where they render invisibly behind battery/wifi/clock. Setting an image — even a transparent one — anchors the item in the correct zone.

2. **Bundle id has a `.dev1` suffix** (`project.yml`). The previous bundle id (`com.guillermorodas.flagtimes`) ended up with a stuck Control Center slot on the development Mac that kept the icon hidden even after the empty-image fix. A fresh bundle id got a fresh slot. If the icon ever vanishes again after a clean reinstall, bump to `.dev2`.

If you ship the app outside this dev machine, the `.dev1` suffix can almost certainly be dropped — it's a workaround for stale local state, not a code-level issue.

## Regenerating the timezone catalog

`Resources/timezone_catalog.json` is derived from macOS's bundled tzdata. Re-run only when you bump tzdata:

```sh
./Scripts/generate_catalog.sh
```
