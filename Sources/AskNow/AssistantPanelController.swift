import AppKit
import SwiftUI

@MainActor
final class AssistantPanelController {
    private let viewModel: ChatViewModel
    private let onOpenSettings: () -> Void
    private var panel: AskNowPanel?

    var isVisible: Bool {
        panel?.isVisible == true
    }

    init(viewModel: ChatViewModel, onOpenSettings: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onOpenSettings = onOpenSettings
    }

    func show() {
        if panel == nil {
            makePanel()
        }

        guard let panel else { return }
        center(panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        viewModel.focusInput()
    }

    func hide() {
        viewModel.cancelStreaming()
        panel?.orderOut(nil)
    }

    private func makePanel() {
        let rootView = AssistantView(
            viewModel: viewModel,
            onOpenSettings: onOpenSettings,
            onDismiss: { [weak self] in self?.hide() }
        )

        let hosting = NSHostingController(rootView: rootView)
        let panel = AskNowPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 560),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "AskNow"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hosting
        self.panel = panel
    }

    private func center(_ panel: NSPanel) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else { return }
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

@MainActor
final class AskNowPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
              let characters = event.charactersIgnoringModifiers?.lowercased() else {
            return super.performKeyEquivalent(with: event)
        }

        switch characters {
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
        case "a":
            return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self)
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}
