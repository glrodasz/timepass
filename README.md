# Flag Times

A native Apple Silicon menu bar app that shows multiple timezones with their country flag.

Replaces the older non-ARM "world clock"-style menu bar utilities. SwiftUI + `MenuBarExtra`, no Electron, no Chromium, no native bridge.

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

Or from the command line (after Xcode is installed and selected):

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

## Regenerating the timezone catalog

`Resources/timezone_catalog.json` is derived from macOS's bundled tzdata. Re-run only when you bump tzdata:

```sh
./Scripts/generate_catalog.sh
```

## Layout

| Path | Purpose |
|---|---|
| `project.yml` | XcodeGen config — single source of truth for the project |
| `Sources/` | SwiftUI app code |
| `Resources/Info.plist` | `LSUIElement=true` (no Dock icon) |
| `Resources/timezone_catalog.json` | ISO 3166-1 alpha-2 → IANA zones |
| `Scripts/generate_catalog.sh` | Catalog regenerator |
