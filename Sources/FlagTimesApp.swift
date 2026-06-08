import SwiftUI

@main
struct FlagTimesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // A SwiftUI scene is required so the AppKit `NSStatusItem` (which is a
        // scene-bound `NSSceneStatusItem` once SwiftUI is linked) has a host
        // scene to render into. The menu bar item itself is managed by
        // `AppDelegate`; this Settings scene is otherwise empty.
        Settings {
            EmptyView()
        }
    }
}
