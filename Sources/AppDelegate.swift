import AppKit
import Combine
import SwiftUI

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
        statusItem.isVisible = true
        if let button = statusItem.button {
            // 1x1 transparent anchor image keeps the item classified as a
            // third-party status item (placed left of system icons on macOS 26)
            // without occupying visible space.
            button.image = NSImage(size: NSSize(width: 1, height: 1))
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePopover)
        }

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
        button.title = identifiers.map { identifier -> String in
            let iso = TimeZoneCatalog.shared.iso(for: identifier) ?? ""
            let flag = FlagEmoji.from(isoCode: iso)
            let tz = TimeZone(identifier: identifier) ?? .current
            return "\(flag) \(ClockFormatter.format(now, in: tz, options: opts))"
        }.joined(separator: "  ")

        // Re-anchor an open popover after the button width changes so its
        // arrow keeps pointing at the (now wider/narrower) status item.
        // Deferred so AppKit has laid out the new bounds before we read them.
        if let popover, popover.isShown {
            DispatchQueue.main.async { [weak self] in
                guard let self, popover.isShown, let button = self.statusItem.button else { return }
                popover.positioningRect = button.bounds
            }
        }
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

    private func ensurePopover() -> NSPopover {
        if let popover { return popover }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 460)
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
