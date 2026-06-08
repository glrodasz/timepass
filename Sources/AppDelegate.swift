import AppKit
import Combine
import SwiftUI

/// Drives the menu bar item with an AppKit `NSStatusItem` instead of SwiftUI's
/// `MenuBarExtra`, which on macOS 26 spins at 100% CPU (when its label uses
/// `TimelineView`) and is prone to the RenderBox status-item registration bug.
/// The picker UI is still SwiftUI, hosted on demand in an `NSPopover`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let zones = ZoneStore()
    let prefs = PreferencesStore()
    let loginItem = LoginItemService()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Give the item a stable, explicit autosave name so its visibility/
        // position persist under a key we control (rather than an auto-generated
        // "Item-0" slot that can get stuck hidden/off-screen).
        statusItem.autosaveName = "FlagTimesMenuBarItem"
        // macOS persists status-item visibility; force it on so a previously
        // hidden state can't keep the icon from ever appearing.
        statusItem.isVisible = true
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover)
        }

        // Refresh the title roughly on the minute and whenever the user's
        // zone/format choices change.
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateTitle() }
        }
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        for publisher in [zones.objectWillChange, prefs.objectWillChange] {
            publisher
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.updateTitle() }
                .store(in: &cancellables)
        }

        updateTitle()
    }

    private func updateTitle() {
        guard let button = statusItem.button else { return }
        let identifiers = zones.identifiers

        guard !identifiers.isEmpty else {
            button.title = "🌐"
            return
        }

        let opts = ClockFormatOptions(
            useAMPM: prefs.useAMPM,
            showDate: prefs.showDate,
            showDay: prefs.showDay
        )
        let now = Date()
        let parts: [String] = identifiers.map { identifier in
            let iso = TimeZoneCatalog.shared.iso(for: identifier) ?? ""
            let flag = FlagEmoji.from(isoCode: iso)
            let tz = TimeZone(identifier: identifier) ?? .current
            let time = ClockFormatter.format(now, in: tz, options: opts)
            return "\(flag) \(time)"
        }
        button.title = parts.joined(separator: "  ")
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        let popover = ensurePopover()
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    /// Builds the popover and its SwiftUI content on first use, keeping SwiftUI
    /// view construction out of the launch path.
    private func ensurePopover() -> NSPopover {
        if let popover { return popover }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: TimeZonePickerView()
                .environmentObject(zones)
                .environmentObject(prefs)
                .environmentObject(loginItem)
        )
        self.popover = popover
        return popover
    }
}
