import SwiftUI
import AppKit

struct SinglePhotoView: View {
    let photo: Photo
    let photos: [Photo]
    @Binding var currentPhoto: Photo?
    var onBack: () -> Void

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
    

    var currentIndex: Int {
        photos.firstIndex(where: { $0.id == photo.id }) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(NSColor(hex: "#1a1a1a"))

                ZStack {
                    if let prev = previousImage {
                        Image(nsImage: prev)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .opacity(isCrossfading ? prevImageOpacity : 0)
                    }

                    if let image = image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .opacity(isCrossfading ? newImageOpacity : 1)
                            .id(photo.id)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(0.5, min(baseScale * value, 5.0))
                                    }
                                    .onEnded { value in
                                        baseScale = max(0.5, min(baseScale * value, 5.0))
                                        if baseScale == 1.0 { offset = .zero }
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
                    }
                    if previousImage != nil && image == nil {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .opacity((image != nil || previousImage != nil) ? 1 : 0)
                
                if image == nil && previousImage == nil, let error = loadError {
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
                } else if image == nil && previousImage == nil {
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
            }
            .clipped()
            .onAppear {
                containerSize = geometry.size
                loadFullImage(crossfade: false, containerSize: geometry.size)
            }
        }
        .onChange(of: photo.id) { _, _ in
            previousImage = image
            prevImageOpacity = 1
            newImageOpacity = 0
            isCrossfading = true
            loadFullImage(crossfade: true, containerSize: containerSize)
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
                scale = max(scale / 1.2, 0.5)
                if scale == 1.0 { offset = .zero }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
            withAnimation {
                scale = 1.0
                offset = .zero
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

    private func loadFullImage(crossfade: Bool, containerSize: CGSize) {
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
        }

        Task {
            let maxSide = CGFloat(max(photo.width ?? 0, photo.height ?? 0))
            let scale = NSScreen.main?.backingScaleFactor ?? 2.0
            let containerMax = max(containerSize.width, containerSize.height) * scale
            let naturalMax = (maxSide > 0 ? maxSide : 4096)
            let target = min(4096, max(1024, min(containerMax, naturalMax)))

            if image == nil && previousImage == nil {
                let thumbSize = max(128, min(containerMax / 2, 1024))
                let thumbResult = await ThumbnailService.shared.getThumbnail(for: photo, size: thumbSize)
                await MainActor.run {
                    if case .success(let thumb) = thumbResult, self.image == nil {
                        self.image = thumb
                    }
                }
            }
            let result = await ThumbnailService.shared.getDisplayImage(for: photo, maxPixelSize: target)
            
            await MainActor.run {
                switch result {
                case .success(let nsImage):
                    if crossfade {
                        self.image = nsImage
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.prevImageOpacity = 0
                            self.newImageOpacity = 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            self.previousImage = nil
                            self.isCrossfading = false
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.scale = 1.0
                                self.baseScale = 1.0
                                self.offset = .zero
                            }
                        }
                        preloadNeighbors(maxPixelSize: target)
                    } else {
                        self.image = nsImage
                        preloadNeighbors(maxPixelSize: target)
                    }
                case .failure(let error):
                    self.loadError = error
                    print("Error loading full image: \(error.localizedDescription)")
                }
            }
        }
    }

    private func preloadNeighbors(maxPixelSize: CGFloat) {
        let idx = currentIndex
        if idx > 0 {
            let prevPhoto = photos[idx - 1]
            Task {
                _ = await ThumbnailService.shared.getDisplayImage(for: prevPhoto, maxPixelSize: maxPixelSize)
            }
        }
        if idx < photos.count - 1 {
            let nextPhoto = photos[idx + 1]
            Task {
                _ = await ThumbnailService.shared.getDisplayImage(for: nextPhoto, maxPixelSize: maxPixelSize)
            }
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
