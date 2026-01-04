import AppKit

final class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private var monitor: Any?
    private var scrollMonitor: Any?

    private var videoController: VideoPlaybackControlling?
    private var videoPlaybackActive: Bool = false

    func start() {
        if monitor != nil { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.handle(event)
        }
        if scrollMonitor == nil {
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self = self else { return event }
                return self.handleScroll(event)
            }
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            self.scrollMonitor = nil
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

        if let chars = event.charactersIgnoringModifiers?.lowercased() {
            if mods == [.command] {
                if chars == "a" {
                    NotificationCenter.default.post(name: .selectAll, object: nil)
                    return nil
                }
                if chars == "=" {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                    return nil
                }
                if chars == "-" {
                    NotificationCenter.default.post(name: .zoomOut, object: nil)
                    return nil
                }
                if chars == "0" {
                    NotificationCenter.default.post(name: .zoomReset, object: nil)
                    return nil
                }
            }
            if mods == [.command, .shift] {
                if chars == "=" {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                    return nil
                }
            }
        }

        if !mods.isEmpty { return event }

        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return event }

        if let vc = videoController {
            if chars == " " || event.keyCode == 49 {
                vc.togglePlayPause()
                return nil
            }
        }

        if let vc = videoController, videoPlaybackActive {
            let enableJKL = UserDefaults.standard.object(forKey: "enableJKLShortcuts") as? Bool ?? true
            let step = UserDefaults.standard.object(forKey: "seekStepSeconds") as? Int ?? 5
            switch chars {
            case "j" where enableJKL:
                vc.seekBackward(10)
                return nil
            case "k" where enableJKL:
                vc.togglePlayPause()
                return nil
            case "l" where enableJKL:
                vc.seekForward(10)
                return nil
            case "m":
                vc.toggleMuted()
                return nil
            case "f":
                vc.toggleFullscreen()
                return nil
            default:
                break
            }
            if event.keyCode == 123 { // 左箭头
                vc.seekBackward(Double(step))
                return nil
            }
            if event.keyCode == 124 { // 右箭头
                vc.seekForward(Double(step))
                return nil
            }
            if event.keyCode == 126 { // 上箭头
                vc.volumeUp()
                return nil
            }
            if event.keyCode == 125 { // 下箭头
                vc.volumeDown()
                return nil
            }
            if event.keyCode == 53 { // Esc
                vc.toggleFullscreen()
                return nil
            }
        }

        switch chars {
        case "c":
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
        if event.keyCode == 51 { // Delete
            NotificationCenter.default.post(name: .deletePhoto, object: event.modifierFlags)
            return nil
        }
        return event
    }

    private func handleScroll(_ event: NSEvent) -> NSEvent? {
        if !NSApp.isActive { return event }
        if let window = NSApp.keyWindow, window.attachedSheet != nil { return event }
        if let responder = NSApp.keyWindow?.firstResponder {
            if responder is NSTextView || responder is NSTextField { return event }
        }
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if !mods.contains(.command) { return event }
        let dy = event.scrollingDeltaY != 0 ? event.scrollingDeltaY : event.deltaY
        if dy > 0 {
            NotificationCenter.default.post(name: .zoomIn, object: "scrollWheel")
        } else if dy < 0 {
            NotificationCenter.default.post(name: .zoomOut, object: "scrollWheel")
        }
        return event
    }
}

// 视频控制协议，由播放器视图实现并注册到 KeyboardShortcutManager
protocol VideoPlaybackControlling {
    func togglePlayPause()
    func seekForward(_ seconds: Double)
    func seekBackward(_ seconds: Double)
    func toggleMuted()
    func changeRate(_ rate: Float)
    func toggleFullscreen()
    func volumeUp()
    func volumeDown()
    var isPlaying: Bool { get }
}

extension KeyboardShortcutManager {
    func setVideoController(_ controller: VideoPlaybackControlling) {
        self.videoController = controller
    }
    func clearVideoController() {
        self.videoController = nil
        self.videoPlaybackActive = false
    }
    func setVideoPlaybackActive(_ active: Bool) {
        self.videoPlaybackActive = active
    }
}
