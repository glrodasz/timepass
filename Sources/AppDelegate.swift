import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let zones = ZoneStore()
    let prefs = PreferencesStore()
    let loginItem = LoginItemService()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private var outsideClickMonitor: Any?
    private var dismissObservers: [NSObjectProtocol] = []
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        if let button = statusItem.button {
            // Empty 1×1 image anchors the item in the third-party status zone
            // on macOS 26; title-only items get placed inside the system-icons
            // slot and render invisibly behind battery/wifi/clock.
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

        // Defer: button.bounds doesn't reflect the new title width until
        // AppKit lays out the resized status item on the next tick.
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

    func popoverDidShow(_ notification: Notification) {
        installDismissObservers()
    }

    func popoverWillClose(_ notification: Notification) {
        removeDismissObservers()
    }

    // `.transient` stops noticing outside clicks once the gear menu has run
    // its own tracking loop, leaving the popover stuck open. Close it
    // explicitly instead of relying on NSPopover alone.
    private func installDismissObservers() {
        guard outsideClickMonitor == nil else { return }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in self?.closePopover() }
        }

        let center = NotificationCenter.default
        dismissObservers.append(center.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.closePopover() }
        })

        // A click outside an open menu only dismisses the menu, so the click
        // never reaches another app. If tracking ended with a button still
        // held down outside the popover, that was such a click.
        dismissObservers.append(center.addObserver(
            forName: NSMenu.didEndTrackingNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard NSEvent.pressedMouseButtons != 0, let self else { return }
                let location = NSEvent.mouseLocation
                let insideApp = [
                    self.popover?.contentViewController?.view.window,
                    self.statusItem.button?.window,
                ].contains { $0?.frame.contains(location) == true }
                if !insideApp { self.closePopover() }
            }
        })
    }

    private func removeDismissObservers() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
        dismissObservers.forEach { NotificationCenter.default.removeObserver($0) }
        dismissObservers.removeAll()
    }

    private func closePopover() {
        guard let popover, popover.isShown else { return }
        popover.performClose(nil)
    }

    private func ensurePopover() -> NSPopover {
        if let popover { return popover }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        let hosting = NSHostingController(
            rootView: TimeZonePickerView()
                .environmentObject(zones)
                .environmentObject(prefs)
                .environmentObject(loginItem)
        )
        // Size the popover from the SwiftUI layout instead of a hard-coded height.
        hosting.sizingOptions = .preferredContentSize
        popover.contentViewController = hosting
        self.popover = popover
        return popover
    }
}
