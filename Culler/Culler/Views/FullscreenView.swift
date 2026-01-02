import SwiftUI

struct FullscreenView: View {
    let photo: Photo
    let photos: [Photo]
    @Binding var currentPhoto: Photo?
    var onExit: () -> Void

    @State private var image: NSImage?
    @State private var loadError: ImageLoadError?
    @State private var showControls = true

    var currentIndex: Int {
        photos.firstIndex(where: { $0.id == photo.id }) ?? 0
    }

    var body: some View {
        ZStack {
            Color.black

            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }

            if showControls {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onExit) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding()
                        .onTapGesture { }
                    }

                    Spacer()

                    HStack {
                        Text(photo.fileName)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(currentIndex + 1) / \(photos.count)")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                }
            }

            HStack {
                Color.clear
                    .frame(width: 100)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if currentIndex > 0 {
                            currentPhoto = photos[currentIndex - 1]
                        }
                    }

                Spacer()

                Color.clear
                    .frame(width: 100)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if currentIndex < photos.count - 1 {
                            currentPhoto = photos[currentIndex + 1]
                        }
                    }
            }
        }
        .clipped()
        .onAppear {
            loadImage()
        }
        .onChange(of: photo.id) { _, _ in
            loadImage()
        }
        .onTapGesture {
            showControls.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateLeft)) { _ in
            if currentIndex > 0 {
                currentPhoto = photos[currentIndex - 1]
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateRight)) { _ in
            if currentIndex < photos.count - 1 {
                currentPhoto = photos[currentIndex + 1]
            }
        }
        .onKeyPress(.escape) {
            onExit()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            if currentIndex > 0 {
                currentPhoto = photos[currentIndex - 1]
            }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            if currentIndex < photos.count - 1 {
                currentPhoto = photos[currentIndex + 1]
            }
            return .handled
        }
    }

    private func loadImage() {
        self.image = nil
        self.loadError = nil
        
        Task {
            let maxSide = CGFloat(max(photo.width ?? 0, photo.height ?? 0))
            let target = maxSide > 0 ? min(maxSide, 4096) : 4096
            let result = await ThumbnailService.shared.getDisplayImage(for: photo, maxPixelSize: target)
            
            await MainActor.run {
                switch result {
                case .success(let nsImage):
                    self.image = nsImage
                case .failure(let error):
                    self.loadError = error
                }
            }
        }
    }
}
