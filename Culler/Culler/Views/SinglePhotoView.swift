import SwiftUI

struct SinglePhotoView: View {
    let photo: Photo
    let photos: [Photo]
    @Binding var currentPhoto: Photo?
    var onBack: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var image: NSImage?
    

    var currentIndex: Int {
        photos.firstIndex(where: { $0.id == photo.id }) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(NSColor(hex: "#1a1a1a"))

                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, min(value, 5.0))
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
                } else {
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

                        Button(action: {}) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
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
        }
        .onAppear {
            loadFullImage()
        }
        .onChange(of: photo.id) { _, _ in
            loadFullImage()
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

    private func loadFullImage() {
        Task {
            let maxSide = CGFloat(max(photo.width ?? 0, photo.height ?? 0))
            let target = maxSide > 0 ? min(maxSide, 4096) : 4096
            let nsImage = await ThumbnailService.shared.getDisplayImage(for: photo, maxPixelSize: target)
            if let nsImage = nsImage {
                await MainActor.run {
                    self.image = nsImage
                    self.scale = 1.0
                    self.offset = .zero
                }
            }
        }
    }

    private func navigatePrevious() {
        if currentIndex > 0 {
            currentPhoto = photos[currentIndex - 1]
        }
    }

    private func navigateNext() {
        if currentIndex < photos.count - 1 {
            currentPhoto = photos[currentIndex + 1]
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
