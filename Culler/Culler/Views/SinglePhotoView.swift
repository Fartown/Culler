import SwiftUI
import AppKit
import SwiftData

struct SinglePhotoView: View {
    let photo: Photo
    let photos: [Photo]
    @Binding var currentPhoto: Photo?
    var onBack: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var scale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var image: NSImage?
    @State private var loadError: ImageLoadError?
    @State private var previousImage: NSImage?
    @State private var isCrossfading: Bool = false
    @State private var prevImageOpacity: Double = 0
    @State private var newImageOpacity: Double = 1
    @State private var containerSize: CGSize = .zero
    @State private var rotationDegrees: Int = 0
    

    var currentIndex: Int {
        photos.firstIndex(where: { $0.id == photo.id }) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(NSColor(hex: "#1a1a1a"))

                ZStack {
                    if photo.isVideo {
                        VideoPlayerView(photo: photo)
                            .id(photo.id)
                    } else {
                        if let prev = previousImage {
                        Image(nsImage: prev)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .rotationEffect(.degrees(Double(rotationDegrees)))
                            .scaleEffect(scale)
                            .offset(offset)
                            .opacity(isCrossfading ? prevImageOpacity : 0)
                        }

                        if let image = image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .rotationEffect(.degrees(Double(rotationDegrees)))
                            .scaleEffect(scale)
                            .offset(offset)
                            .opacity(isCrossfading ? newImageOpacity : 1)
                            .id(photo.id)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(0.8, min(baseScale * value, 5.0))
                                    }
                                    .onEnded { value in
                                        baseScale = max(0.8, min(baseScale * value, 5.0))
                                        if baseScale <= 1.0 { offset = .zero }
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            offset = value.translation
                                        }
                                    }
                                    .onEnded { _ in
                                        if scale == 1 {
                                            offset = .zero
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if scale > 1 {
                                        scale = 1
                                        offset = .zero
                                    } else {
                                        scale = 2
                                    }
                                }
                            }
                            .contextMenu {
                                PhotoContextMenu(targets: [photo])
                            }
                        }
                        if previousImage != nil && image == nil {
                        ProgressView()
                            .scaleEffect(0.8)
                        }
                    }
                }
                .opacity(photo.isVideo ? 1 : ((image != nil || previousImage != nil) ? 1 : 0))
                
                if !photo.isVideo && image == nil && previousImage == nil, let error = loadError {
                     VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("无法加载图片")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if error == .permissionDenied {
                            Text("应用可能已失去该文件的访问权限。")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else if !photo.isVideo && image == nil && previousImage == nil {
                    ProgressView()
                }

                VStack {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("\(currentIndex + 1) / \(photos.count)")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)

                        Spacer()

                        
                    }
                    .padding()

                    Spacer()
                }

                HStack {
                    NavigationArrow(direction: .left) {
                        navigatePrevious()
                    }
                    .opacity(currentIndex > 0 ? 1 : 0.3)

                    Spacer()

                    NavigationArrow(direction: .right) {
                        navigateNext()
                    }
                    .opacity(currentIndex < photos.count - 1 ? 1 : 0.3)
                }
                .padding(.horizontal, 20)
                
                ScrollReader { delta in
                    let sensitivity: CGFloat = 0.01
                    let newScale = scale * (1 + delta * sensitivity)
                    let clampedScale = max(0.8, min(newScale, 5.0))
                    
                    if clampedScale != scale {
                        scale = clampedScale
                        baseScale = clampedScale
                        
                        if scale <= 1.0 {
                            if offset != .zero {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    offset = .zero
                                }
                            }
                        }
                    }
                }
            }
            .clipped()
            .onAppear {
                containerSize = geometry.size
            }
        }
        .onChange(of: photo.id) { _, _ in
            previousImage = image
            prevImageOpacity = 1
            newImageOpacity = 0
            isCrossfading = true
        }
        .task(id: photo.id) {
            if !photo.isVideo {
                await loadFullImage(crossfade: isCrossfading, containerSize: containerSize)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateLeft)) { _ in
            navigatePrevious()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateRight)) { _ in
            navigateNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            withAnimation {
                scale = min(scale * 1.2, 5.0)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            withAnimation {
                scale = max(scale / 1.2, 0.8)
                if scale <= 1.0 { offset = .zero }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
            withAnimation {
                scale = 1.0
                offset = .zero
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .rotateLeft)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                rotationDegrees = (rotationDegrees - 90 + 360) % 360
                offset = .zero
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .rotateRight)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                rotationDegrees = (rotationDegrees + 90) % 360
                offset = .zero
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deletePhoto)) { note in
            let mods = note.object as? NSEvent.ModifierFlags ?? []
            if mods.contains(.command) {
                deleteRawJpgPair(photo)
            } else if mods.contains(.shift) {
                deleteFromDisk(photo)
            } else {
                removeFromLibrary(photo)
            }
            if currentIndex > 0 {
                navigatePrevious()
            } else {
                navigateNext()
            }
        }
        .onKeyPress(.leftArrow) {
            navigatePrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateNext()
            return .handled
        }
    }

    @MainActor
    private func loadFullImage(crossfade: Bool, containerSize: CGSize) async {
        self.loadError = nil
        if !crossfade {
            self.image = nil
            self.previousImage = nil
            self.scale = 1.0
            self.baseScale = 1.0
            self.offset = .zero
            self.prevImageOpacity = 0
            self.newImageOpacity = 1
            self.isCrossfading = false
            self.rotationDegrees = 0
        }

        let maxSide = CGFloat(max(photo.width ?? 0, photo.height ?? 0))
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let containerMax = max(containerSize.width, containerSize.height) * scale
        let naturalMax = (maxSide > 0 ? maxSide : 3072)
        var target = min(3072, max(1024, min(containerMax, naturalMax)))

        if image == nil && previousImage == nil {
            let thumbSize = max(128, min(containerMax / 2, 1024))
            let thumbResult = await ThumbnailService.shared.getThumbnail(for: photo, size: thumbSize)
            if !Task.isCancelled, case .success(let thumb) = thumbResult, self.image == nil {
                self.image = thumb
            }
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        if baseScale > 1.5 {
            target = min(4096, target * 2)
        }
        
        let result = await ThumbnailService.shared.getDisplayImage(for: photo, maxPixelSize: target)
        
        if Task.isCancelled { return }

        switch result {
        case .success(let nsImage):
            if crossfade {
                self.image = nsImage
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.prevImageOpacity = 0
                    self.newImageOpacity = 1
                }
                try? await Task.sleep(nanoseconds: 220_000_000)
                if !Task.isCancelled {
                    self.previousImage = nil
                    self.isCrossfading = false
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.scale = 1.0
                        self.baseScale = 1.0
                        self.offset = .zero
                        self.rotationDegrees = 0
                    }
                }
            } else {
                self.image = nsImage
            }
            
            try? await Task.sleep(nanoseconds: 150_000_000)
            await preloadNeighbors(maxPixelSize: target)
            
        case .failure(let error):
            self.loadError = error
            print("Error loading full image: \(error.localizedDescription)")
        }
    }

    private func preloadNeighbors(maxPixelSize: CGFloat) async {
        if Task.isCancelled { return }
        let idx = currentIndex
        if idx > 0 {
            let prevPhoto = photos[idx - 1]
            _ = await ThumbnailService.shared.getDisplayImage(for: prevPhoto, maxPixelSize: maxPixelSize)
        }
        if Task.isCancelled { return }
        if idx < photos.count - 1 {
            let nextPhoto = photos[idx + 1]
            _ = await ThumbnailService.shared.getDisplayImage(for: nextPhoto, maxPixelSize: maxPixelSize)
        }
    }

    private func navigatePrevious() {
        if currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPhoto = photos[currentIndex - 1]
            }
        }
    }

    private func navigateNext() {
        if currentIndex < photos.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPhoto = photos[currentIndex + 1]
            }
        }
    }

    private func removeFromLibrary(_ photo: Photo) {
        modelContext.delete(photo)
    }

    private func deleteFromDisk(_ photo: Photo) {
        let url = photo.fileURL
        var didStart = false
        if photo.bookmarkData != nil {
            didStart = url.startAccessingSecurityScopedResource()
        }
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        modelContext.delete(photo)
    }

    private func deleteRawJpgPair(_ photo: Photo) {
        let knownPhotosByPath: [String: Photo] = {
            var map: [String: Photo] = [:]
            map[photo.filePath] = photo
            map[photo.fileURL.path] = photo
            return map
        }()

        var candidatePaths = Set<String>()
        candidatePaths.formUnion(pairedPaths(for: photo))

        var deletedPhotoIDs = Set<UUID>()
        for path in candidatePaths {
            let matchedPhoto = knownPhotosByPath[path] ?? fetchPhotoByPath(path)
            let deleteTargetURL = matchedPhoto?.fileURL ?? URL(fileURLWithPath: path)
            deleteFileFromDisk(url: deleteTargetURL, bookmarkData: matchedPhoto?.bookmarkData)

            if let matchedPhoto, !deletedPhotoIDs.contains(matchedPhoto.id) {
                deletedPhotoIDs.insert(matchedPhoto.id)
                modelContext.delete(matchedPhoto)
            }
        }
    }

    private func pairedPaths(for photo: Photo) -> Set<String> {
        let rawExtensions = ["raw", "cr2", "cr3", "nef", "arw", "dng", "orf", "rw2"]
        let jpgExtensions = ["jpg", "jpeg"]

        let url = photo.fileURL
        let baseURL = url.deletingPathExtension()
        let ext = url.pathExtension.lowercased()

        var paths = Set<String>()
        paths.insert(url.path)

        if rawExtensions.contains(ext) {
            for jpgExt in jpgExtensions {
                let jpgURL = baseURL.appendingPathExtension(jpgExt)
                if FileManager.default.fileExists(atPath: jpgURL.path) {
                    paths.insert(jpgURL.path)
                }
            }
        } else if jpgExtensions.contains(ext) {
            for rawExt in rawExtensions {
                let rawURL = baseURL.appendingPathExtension(rawExt)
                if FileManager.default.fileExists(atPath: rawURL.path) {
                    paths.insert(rawURL.path)
                    break
                }
            }
        }

        return paths
    }

    private func fetchPhotoByPath(_ path: String) -> Photo? {
        let descriptor = FetchDescriptor<Photo>(predicate: #Predicate { $0.filePath == path })
        return try? modelContext.fetch(descriptor).first
    }

    private func deleteFileFromDisk(url: URL, bookmarkData: Data?) {
        var didStart = false
        if bookmarkData != nil {
            didStart = url.startAccessingSecurityScopedResource()
        }
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

struct NavigationArrow: View {
    enum Direction {
        case left, right
    }

    let direction: Direction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.title)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct ScrollReader: NSViewRepresentable {
    var onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> ScrollHandlingNSView {
        let view = ScrollHandlingNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollHandlingNSView, context: Context) {
        nsView.onScroll = onScroll
    }

    class ScrollHandlingNSView: NSView {
        var onScroll: ((CGFloat) -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }

        deinit {
            stopMonitoring()
        }

        private func startMonitoring() {
            if monitor != nil { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self = self, self.window != nil else { return event }
                
                let location = event.locationInWindow
                let localPoint = self.convert(location, from: nil)
                if self.bounds.contains(localPoint) {
                    // Use scrollingDeltaY for trackpad precision, fallback to deltaY
                    let delta = event.scrollingDeltaY != 0 ? event.scrollingDeltaY : event.deltaY
                    // Invert check or logic if needed, but usually positive deltaY means scroll up (content down)
                    // For zoom: Wheel UP (deltaY > 0) -> Zoom IN
                    self.onScroll?(delta)
                    return nil // Consume event to prevent scrolling parent views
                }
                return event
            }
        }

        private func stopMonitoring() {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
        
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }
    }
}
