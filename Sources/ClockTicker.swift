import SwiftUI

/// Publishes the current time on a steady timer so the menu bar label can
/// refresh without `TimelineView`, which spins at 100% CPU when used as a
/// `MenuBarExtra` label.
@MainActor
final class ClockTicker: ObservableObject {
    @Published private(set) var now: Date = Date()
    private var timer: Timer?

    init() {
        // Displayed granularity is minutes, so a 30s tick keeps HH:mm within a
        // minute of wall-clock time. Tolerance lets the OS coalesce wake-ups.
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
