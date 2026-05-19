import AppKit
import SwiftUI

@MainActor
final class AssistantPanelController: NSObject {
    private static let compactSize = NSSize(width: 680, height: 560)

    private let viewModel: ChatViewModel
    private let onOpenSettings: () -> Void
    private var panel: AskNowPanel?
    private var compactFrame: NSRect?
    private var isZoomedToVisibleFrame = false

    var isVisible: Bool {
        panel?.isVisible == true
    }

    init(viewModel: ChatViewModel, onOpenSettings: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onOpenSettings = onOpenSettings
        super.init()
    }

    func show() {
        if panel == nil {
            makePanel()
        }

        guard let panel else { return }
        if isZoomedToVisibleFrame {
            zoomToVisibleFrame(panel)
        } else {
            center(panel)
            compactFrame = panel.frame
        }
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
            contentRect: NSRect(origin: .zero, size: Self.compactSize),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "AskNow"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.minSize = Self.compactSize
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenNone]
        panel.hidesOnDeactivate = false
        panel.delegate = self
        panel.onZoom = { [weak self, weak panel] in
            guard let self, let panel else { return }
            self.toggleVisibleFrameZoom(panel)
        }
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

    private func toggleVisibleFrameZoom(_ panel: NSPanel) {
        if isZoomedToVisibleFrame {
            restoreCompactFrame(panel)
        } else {
            compactFrame = panel.frame
            zoomToVisibleFrame(panel)
        }
    }

    private func zoomToVisibleFrame(_ panel: NSPanel) {
        let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else { return }
        panel.setFrame(frame, display: true, animate: true)
        isZoomedToVisibleFrame = true
    }

    private func restoreCompactFrame(_ panel: NSPanel) {
        if let compactFrame {
            panel.setFrame(compactFrame, display: true, animate: true)
        } else {
            panel.setContentSize(Self.compactSize)
            center(panel)
        }
        isZoomedToVisibleFrame = false
        compactFrame = panel.frame
    }
}

extension AssistantPanelController: NSWindowDelegate {
    nonisolated func windowShouldClose(_ sender: NSWindow) -> Bool {
        Task { @MainActor [weak self] in
            self?.hide()
        }
        return false
    }

    nonisolated func windowDidResignKey(_ notification: Notification) {
        Task { @MainActor [weak self] in
            guard let self, !self.viewModel.isPanelPinned else { return }
            self.panel?.orderOut(nil)
        }
    }
}

@MainActor
final class AskNowPanel: NSPanel {
    var onZoom: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func zoom(_ sender: Any?) {
        if let onZoom {
            onZoom()
        } else {
            super.zoom(sender)
        }
    }

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
