import SwiftUI

struct PhotoGridView: View {
    let photos: [Photo]
    @Binding var selectedPhotos: Set<UUID>
    @Binding var currentPhoto: Photo?
    var onDoubleClick: () -> Void

    @State private var thumbnailSize: CGFloat = 150
    @State private var hoveredPhoto: UUID?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 8)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    PhotoThumbnail(
                        photo: photo,
                        isSelected: selectedPhotos.contains(photo.id),
                        isHovered: hoveredPhoto == photo.id,
                        size: thumbnailSize
                    )
                    .onTapGesture {
                        handleSelection(photo: photo, shiftKey: NSEvent.modifierFlags.contains(.shift))
                    }
                    .onTapGesture(count: 2) {
                        currentPhoto = photo
                        onDoubleClick()
                    }
                    .onHover { isHovered in
                        hoveredPhoto = isHovered ? photo.id : nil
                    }
                    .contextMenu {
                        PhotoContextMenu(photo: photo)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(NSColor(hex: "#1a1a1a")))
    }

    private func handleSelection(photo: Photo, shiftKey: Bool) {
        if shiftKey {
            if selectedPhotos.contains(photo.id) {
                selectedPhotos.remove(photo.id)
            } else {
                selectedPhotos.insert(photo.id)
            }
        } else {
            selectedPhotos = [photo.id]
        }
        currentPhoto = photo
    }
}

struct PhotoThumbnail: View {
    let photo: Photo
    let isSelected: Bool
    let isHovered: Bool
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Layer 1: Image
            AsyncThumbnailView(photo: photo, size: size)
                .frame(width: size, height: size)
                .clipped()
                .cornerRadius(4)
            
            // Layer 2: Selection Border
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                .frame(width: size, height: size)
            
            // Layer 3: Top Left Status Icons
            VStack(alignment: .leading, spacing: 4) {
                if photo.flag == .pick {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(.black.opacity(0.5)))
                } else if photo.flag == .reject {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(.black.opacity(0.5)))
                }

                if photo.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(1...photo.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(2)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(2)
                }
            }
            .padding(12) // Increased padding
            
            // Layer 4: Top Right Color Label
            if photo.colorLabel != .none {
                ZStack(alignment: .topTrailing) {
                    Color.clear.frame(width: size, height: size)
                    Circle()
                        .fill(Color(photo.colorLabel.color))
                        .frame(width: 12, height: 12)
                        .padding(12)
                }
            }
            
            // Layer 5: Bottom Right Hover Actions
            if isHovered {
                ZStack(alignment: .bottomTrailing) {
                    Color.clear.frame(width: size, height: size)
                    HStack(spacing: 4) {
                        QuickActionButton(icon: "star.fill") {
                            photo.rating = (photo.rating == 5) ? 0 : 5
                        }
                        QuickActionButton(icon: "checkmark") {
                            photo.flag = (photo.flag == .pick) ? .none : .pick
                        }
                        QuickActionButton(icon: "xmark") {
                            photo.flag = (photo.flag == .reject) ? .none : .reject
                        }
                    }
                    .padding(12) // Increased padding
                }
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

struct QuickActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct AsyncThumbnailView: View {
    let photo: Photo
    let size: CGFloat
    let contentMode: ContentMode

    init(photo: Photo, size: CGFloat, contentMode: ContentMode = .fill) {
        self.photo = photo
        self.size = size
        self.contentMode = contentMode
    }

    @State private var image: NSImage?
    @State private var hasError: Bool = false

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if hasError {
                Rectangle()
                    .fill(Color(NSColor(hex: "#2a2a2a")))
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.secondary)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        Task {
            let result = await ThumbnailService.shared.getThumbnail(for: photo, size: size)
            await MainActor.run {
                switch result {
                case .success(let thumbnail):
                    self.image = thumbnail
                    self.hasError = false
                case .failure:
                    self.image = nil
                    self.hasError = true
                }
            }
        }
    }
}

struct PhotoContextMenu: View {
    let photo: Photo

    var body: some View {
        Group {
            Menu("Flag") {
                Button("Pick") { photo.flag = .pick }
                Button("Reject") { photo.flag = .reject }
                Button("Unflag") { photo.flag = .none }
            }

            Menu("Rating") {
                ForEach(0...5, id: \.self) { rating in
                    Button(rating == 0 ? "Clear" : String(repeating: "★", count: rating)) {
                        photo.rating = rating
                    }
                }
            }

            Menu("Color Label") {
                ForEach(ColorLabel.allCases, id: \.rawValue) { label in
                    Button(label.name) {
                        photo.colorLabel = label
                    }
                }
            }

            Divider()

            Button("Show in Finder") {
                NSWorkspace.shared.selectFile(photo.filePath, inFileViewerRootedAtPath: "")
            }
        }
    }
}
