# Timepass

A native Apple Silicon menu bar app that shows multiple timezones, each with its country flag and current time.

Replaces older non-ARM "world clock" menu bar utilities. Pure AppKit `NSStatusItem` for the menu bar item, SwiftUI hosted in an `NSPopover` for the picker UI. No Electron, no Chromium.

## Requirements

- macOS 13.0+ (Ventura)
- **Xcode 15+** (full Xcode.app — Command Line Tools alone are not enough). Install from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & run

```sh
brew install xcodegen        # first time only
make build                   # generate project + Release build
```

`make help` lists every target. Common ones:

```sh
make generate   # regenerate Timepass.xcodeproj from project.yml
make build      # Release build into build/DerivedData
make install    # build, then copy Timepass.app into /Applications
make run        # launch the installed app
make clean      # remove build/ and Timepass.xcodeproj
```

To work in Xcode instead:

```sh
make generate
open Timepass.xcodeproj       # ⌘R in Xcode
```

To install for daily use:

1. `make install` (copies `Timepass.app` into `/Applications`).
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

One non-obvious workaround lives in this project, documented in the code next to where it's applied; this section explains the why.

**The status item carries an empty 1×1 image** (`AppDelegate.applicationDidFinishLaunching`). On macOS 26, title-only `NSStatusItem`s are sometimes placed inside the system-icons slot (right of the Control Center pill) instead of the third-party status zone, where they render invisibly behind battery/wifi/clock. Setting an image — even a transparent one — anchors the item in the correct zone.

If the menu bar icon ever vanishes after a clean reinstall, a stuck Control Center slot cached against the bundle id can be the cause; adding a temporary suffix to `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` forces a fresh slot.

## Regenerating the timezone catalog

`Resources/timezone_catalog.json` is derived from macOS's bundled tzdata. Re-run only when you bump tzdata:

```sh
./Scripts/generate_catalog.sh
```
