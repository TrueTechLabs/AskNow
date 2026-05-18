import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private lazy var chatViewModel = ChatViewModel(settingsStore: settingsStore)
    private lazy var assistantPanelController = AssistantPanelController(
        viewModel: chatViewModel,
        onOpenSettings: { [weak self] in self?.openSettings() }
    )
    private lazy var settingsWindowController = SettingsWindowController(settingsStore: settingsStore)
    private lazy var menuBarController = MenuBarController(
        onToggleAssistant: { [weak self] in self?.toggleAssistant() },
        onOpenSettings: { [weak self] in self?.openSettings() }
    )
    private lazy var hotkeyManager = HotkeyManager { [weak self] in
        self?.toggleAssistant()
    }
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        menuBarController.install()
        registerConfiguredHotkey(settingsStore.settings)
        settingsStore.$settings
            .removeDuplicates()
            .sink { [weak self] settings in
                self?.registerConfiguredHotkey(settings)
                self?.refreshLocalizedChrome()
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
    }

    private func toggleAssistant() {
        if assistantPanelController.isVisible {
            assistantPanelController.hide()
        } else {
            assistantPanelController.show()
        }
    }

    private func openSettings() {
        settingsWindowController.show()
    }

    private func registerConfiguredHotkey(_ settings: ModelSettings) {
        hotkeyManager.registerShortcut(
            keyCode: settings.shortcutKeyCode,
            modifiers: settings.shortcutModifiers
        )
    }

    private func refreshLocalizedChrome() {
        menuBarController.refreshTitles()
        settingsWindowController.refreshTitle()
        installMainMenu()
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let editMenuItem = NSMenuItem()

        mainMenu.addItem(appMenuItem)
        mainMenu.addItem(editMenuItem)

        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: AppText.quitAskNow, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: AppText.cut, action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: AppText.copy, action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: AppText.paste, action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: AppText.selectAll, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }
}
