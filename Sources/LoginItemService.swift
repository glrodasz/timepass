import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class LoginItemService: ObservableObject {
    @Published private(set) var isEnabled: Bool

    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("LoginItemService toggle failed: \(error.localizedDescription)")
        }
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
}
