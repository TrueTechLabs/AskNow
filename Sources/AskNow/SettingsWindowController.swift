import AppKit
import Combine
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let settingsStore: SettingsStore
    private var window: NSWindow?
    private var cancellable: AnyCancellable?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        cancellable = settingsStore.$settings
            .sink { [weak self] _ in
                self?.refreshTitle()
            }
    }

    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: SettingsView(settingsStore: settingsStore))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 620),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.contentViewController = controller
            window.isReleasedWhenClosed = false
            self.window = window
        }

        refreshTitle()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func refreshTitle() {
        window?.title = AppText.settingsTitle
    }
}
