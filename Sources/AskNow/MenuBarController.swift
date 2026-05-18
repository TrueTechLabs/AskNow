import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let showItem = NSMenuItem()
    private let settingsItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private let onToggleAssistant: () -> Void
    private let onOpenSettings: () -> Void

    init(onToggleAssistant: @escaping () -> Void, onOpenSettings: @escaping () -> Void) {
        self.onToggleAssistant = onToggleAssistant
        self.onOpenSettings = onOpenSettings
        super.init()
    }

    func install() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "AskNow")
            button.target = self
            button.action = #selector(toggleAssistant)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        showItem.action = #selector(toggleAssistant)
        settingsItem.action = #selector(openSettings)
        settingsItem.keyEquivalent = ","
        quitItem.action = #selector(quit)
        quitItem.keyEquivalent = "q"

        menu.addItem(showItem)
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        for item in menu.items {
            item.target = self
        }
        refreshTitles()
    }

    func refreshTitles() {
        showItem.title = AppText.showAskNow
        settingsItem.title = AppText.settings
        quitItem.title = AppText.quitAskNow
    }

    @objc private func toggleAssistant() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            if let button = statusItem.button {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
            }
            return
        }

        onToggleAssistant()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
