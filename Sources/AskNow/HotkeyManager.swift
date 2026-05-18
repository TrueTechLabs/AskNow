import Carbon
import Foundation

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private let handler: () -> Void

    private static var sharedHandler: (() -> Void)?
    private static var eventHandler: EventHandlerRef?

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func registerShortcut(keyCode: UInt32, modifiers: UInt32) {
        unregister()

        HotkeyManager.sharedHandler = handler

        if HotkeyManager.eventHandler == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, event, _ in
                    var hotKeyID = EventHotKeyID()
                    let status = GetEventParameter(
                        event,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotKeyID
                    )

                    if status == noErr && hotKeyID.id == 1 {
                        DispatchQueue.main.async {
                            HotkeyManager.sharedHandler?()
                        }
                    }

                    return noErr
                },
                1,
                &eventType,
                nil,
                &HotkeyManager.eventHandler
            )
        }

        let hotKeyID = EventHotKeyID(signature: OSType("ASKN".fourCharCode), id: 1)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func registerDefaultShortcut() {
        registerShortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        var result: FourCharCode = 0
        for scalar in unicodeScalars.prefix(4) {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        return result
    }
}
