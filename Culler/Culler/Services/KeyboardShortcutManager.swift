import AppKit

final class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private var monitor: Any?

    func start() {
        if monitor != nil { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.handle(event)
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        if !NSApp.isActive { return event }
        if let window = NSApp.keyWindow, window.attachedSheet != nil { return event }

        if let responder = NSApp.keyWindow?.firstResponder {
            if responder is NSTextView || responder is NSTextField { return event }
        }

        var mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        mods.remove(.numericPad)
        mods.remove(.function)
        if !mods.isEmpty { return event }

        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return event }

        switch chars {
        case "p":
            NotificationCenter.default.post(name: .setFlag, object: Flag.pick)
            return nil
        case "x":
            NotificationCenter.default.post(name: .setFlag, object: Flag.reject)
            return nil
        case "u":
            NotificationCenter.default.post(name: .setFlag, object: Flag.none)
            return nil
        case "0":
            NotificationCenter.default.post(name: .setRating, object: 0)
            return nil
        case "1", "2", "3", "4", "5":
            if let rating = Int(chars) {
                NotificationCenter.default.post(name: .setRating, object: rating)
                return nil
            }
            return event
        default:
            break
        }

        if event.keyCode == 123 {
            NotificationCenter.default.post(name: .navigateLeft, object: nil)
            return nil
        }
        if event.keyCode == 124 {
            NotificationCenter.default.post(name: .navigateRight, object: nil)
            return nil
        }
        if event.keyCode == 125 {
            NotificationCenter.default.post(name: .navigateDown, object: nil)
            return nil
        }
        if event.keyCode == 126 {
            NotificationCenter.default.post(name: .navigateUp, object: nil)
            return nil
        }
        return event
    }
}
