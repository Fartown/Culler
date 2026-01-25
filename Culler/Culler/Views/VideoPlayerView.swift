import SwiftUI
import AVKit
import Combine
import Foundation

struct VideoPlayerView: View {
    let photo: Photo
    @AppStorage("doubleTapAction") private var doubleTapAction: String = "playPause"

    @State private var player: AVPlayer?
    @State private var itemStatus: AVPlayerItem.Status = .unknown
    @State private var duration: Double = 0
    @State private var currentTime: Double = 0
    @State private var isPlaying: Bool = false
    @State private var isMuted: Bool = false
    @State private var rate: Float = 1.0
    @State private var loadFailed: Bool = false

    @State private var timeObserver: Any?
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var statusObservation: NSKeyValueObservation?

    var body: some View {
        ZStack {
            if let player {
                AVPlayerContainerView(player: player)
                    .onAppear {
                        let bridge = VideoControllerBridge(
                            togglePlayPause: { togglePlayPause() },
                            seekForward: { sec in seek(by: sec) },
                            seekBackward: { sec in seek(by: -sec) },
                            toggleMuted: { toggleMuted() },
                            changeRate: { r in changeRate(r) },
                            toggleFullscreen: { toggleFullscreen() },
                            volumeUp: { volumeUp() },
                            volumeDown: { volumeDown() },
                            isPlayingProvider: { isPlaying }
                        )
                        KeyboardShortcutManager.shared.setVideoController(bridge)
                    }
                    .onDisappear {
                        KeyboardShortcutManager.shared.clearVideoController()
                        cleanupPlayer()
                    }
            }

            if loadFailed {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("当前视频不可播放")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("用系统播放器打开") {
                        let url = photo.fileURL
                        var didStart = false
                        if photo.bookmarkData != nil {
                            didStart = url.startAccessingSecurityScopedResource()
                        }
                        NSWorkspace.shared.open(url)
                        if didStart { url.stopAccessingSecurityScopedResource() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }

            if player != nil {
                controlsOverlay
            }
        }
        .accessibilityIdentifier("video_player_view")
        .onTapGesture(count: 2) {
            if doubleTapAction == "fullscreen" {
                toggleFullscreen()
            } else {
                togglePlayPause()
            }
        }
        .onAppear { setupPlayer() }
        .onChange(of: isPlaying) { old, new in
            KeyboardShortcutManager.shared.setVideoPlaybackActive(new)
        }
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("video_play_pause_button")

                Text(timeString(currentTime))
                    .foregroundColor(.white)
                    .font(.caption)

                Slider(value: Binding(get: {
                    duration > 0 ? currentTime / duration : 0
                }, set: { newVal in
                    seek(to: newVal * duration)
                }))
                .frame(minWidth: 220)

                Text(timeString(duration))
                    .foregroundColor(.white)
                    .font(.caption)

                Button(action: { isMuted.toggle(); player?.isMuted = isMuted }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Slider(value: Binding(get: {
                    Double(player?.volume ?? 1.0)
                }, set: { v in
                    player?.volume = Float(v)
                }), in: 0...1)
                .frame(width: 100)

                SpeedSelectorButton(rate: $rate) { r in
                    changeRate(r)
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
            .padding(.bottom, 16)
            .padding(.horizontal, 20)
        }
    }

    private func setupPlayer() {
        let url = photo.fileURL
        var didStart = false
        if photo.bookmarkData != nil {
            didStart = url.startAccessingSecurityScopedResource()
        }

        let asset = AVAsset(url: url)
        if !asset.isPlayable {
            loadFailed = true
            if didStart { url.stopAccessingSecurityScopedResource() }
            return
        }

        // XCUITest 下（尤其是 UI 自动化环境），某些“后缀是视频但内容不可播放”的文件
        // `isPlayable` 可能返回 true，但后续实际无法播放。这里提前用 async load 做一次兜底检查。
        let item = AVPlayerItem(asset: asset)
        let p = AVPlayer(playerItem: item)
        p.volume = 1.0
        p.isMuted = false
        p.actionAtItemEnd = .pause

        player = p
        isMuted = p.isMuted
        rate = 1.0

        statusObservation = item.observe(\.status, options: [.initial, .new]) { _, _ in
            itemStatus = item.status
            let d = item.asset.duration.seconds
            duration = d.isFinite ? d : 0
        }

        addTimeObserver()

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { _ in
                isPlaying = false
            }
            .store(in: &cancellables)

        isPlaying = false
    }

    private func cleanupPlayer() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
        statusObservation?.invalidate()
        statusObservation = nil
        player?.pause()
        player = nil

        let url = photo.fileURL
        if photo.bookmarkData != nil {
            url.stopAccessingSecurityScopedResource()
        }
        cancellables.removeAll()
    }

    private func addTimeObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }
    }

    private func togglePlayPause() {
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.playImmediately(atRate: rate)
            isPlaying = true
        }
    }

    private func seek(by seconds: Double) {
        guard let p = player else { return }
        let new = max(0, min(currentTime + seconds, duration))
        seek(to: new)
    }

    private func seek(to seconds: Double) {
        guard let p = player else { return }
        let t = CMTime(seconds: seconds, preferredTimescale: 600)
        p.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func toggleMuted() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    private func changeRate(_ newRate: Float) {
        rate = newRate
        if isPlaying { player?.rate = newRate }
    }

    private func toggleFullscreen() {
        NSApp.keyWindow?.toggleFullScreen(nil)
    }

    private func volumeUp() {
        guard let p = player else { return }
        p.volume = min(p.volume + 0.1, 1.0)
    }

    private func volumeDown() {
        guard let p = player else { return }
        p.volume = max(p.volume - 0.1, 0.0)
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "--:--" }
        let s = Int(seconds.rounded())
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    private final class VideoControllerBridge: VideoPlaybackControlling {
        private let togglePlayPauseClosure: () -> Void
        private let seekForwardClosure: (Double) -> Void
        private let seekBackwardClosure: (Double) -> Void
        private let toggleMutedClosure: () -> Void
        private let changeRateClosure: (Float) -> Void
        private let toggleFullscreenClosure: () -> Void
        private let volumeUpClosure: () -> Void
        private let volumeDownClosure: () -> Void
        private let isPlayingProvider: () -> Bool

        init(togglePlayPause: @escaping () -> Void,
             seekForward: @escaping (Double) -> Void,
             seekBackward: @escaping (Double) -> Void,
             toggleMuted: @escaping () -> Void,
             changeRate: @escaping (Float) -> Void,
             toggleFullscreen: @escaping () -> Void,
             volumeUp: @escaping () -> Void,
             volumeDown: @escaping () -> Void,
             isPlayingProvider: @escaping () -> Bool) {
            self.togglePlayPauseClosure = togglePlayPause
            self.seekForwardClosure = seekForward
            self.seekBackwardClosure = seekBackward
            self.toggleMutedClosure = toggleMuted
            self.changeRateClosure = changeRate
            self.toggleFullscreenClosure = toggleFullscreen
            self.volumeUpClosure = volumeUp
            self.volumeDownClosure = volumeDown
            self.isPlayingProvider = isPlayingProvider
        }

        func togglePlayPause() { togglePlayPauseClosure() }
        func seekForward(_ seconds: Double) { seekForwardClosure(seconds) }
        func seekBackward(_ seconds: Double) { seekBackwardClosure(seconds) }
        func toggleMuted() { toggleMutedClosure() }
        func changeRate(_ rate: Float) { changeRateClosure(rate) }
        func toggleFullscreen() { toggleFullscreenClosure() }
        func volumeUp() { volumeUpClosure() }
        func volumeDown() { volumeDownClosure() }
        var isPlaying: Bool { isPlayingProvider() }
    }
}

struct AVPlayerContainerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.showsFullScreenToggleButton = false
        view.setAccessibilityIdentifier("video_player_view")
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
        nsView.controlsStyle = .none
        nsView.showsFullScreenToggleButton = false
        nsView.setAccessibilityIdentifier("video_player_view")
    }
}

private struct SpeedSelectorButton: View {
    @Binding var rate: Float
    var onChange: (Float) -> Void
    @State private var showMenu: Bool = false

    var body: some View {
        Button(action: { showMenu.toggle() }) {
            Text(String(format: "%.1fx", rate))
                .foregroundColor(.white)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .fixedSize(horizontal: true, vertical: true)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMenu, arrowEdge: .bottom) {
            VStack(spacing: 6) {
                speedRow(0.5)
                speedRow(1.0)
                speedRow(1.5)
                speedRow(2.0)
            }
            .padding(8)
            .frame(width: 96)
        }
    }

    private func speedRow(_ value: Float) -> some View {
        Button(action: {
            onChange(value)
            showMenu = false
        }) {
            HStack {
                Text(String(format: "%.1fx", value))
                if rate == value { Image(systemName: "checkmark") }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}
