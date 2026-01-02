import SwiftUI

struct PhotoGridView: View {
    let photos: [Photo]
    @Binding var selectedPhotos: Set<UUID>
    @Binding var currentPhoto: Photo?
    var onDoubleClick: () -> Void

    @State private var thumbnailSize: CGFloat = 150
    @State private var hoveredPhoto: UUID?

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 8)]

    var body: some View {
        Group {
            if photos.isEmpty {
                EmptyStateView(systemImage: "tray", title: "当前没有内容")
            } else {
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
            }
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
            AsyncThumbnailView(photo: photo, size: size)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )

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
            .padding(4)

            if photo.colorLabel != .none {
                Circle()
                    .fill(Color(photo.colorLabel.color))
                    .frame(width: 12, height: 12)
                    .position(x: size - 10, y: 10)
            }

            if isHovered {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            QuickActionButton(icon: "star.fill") {}
                            QuickActionButton(icon: "checkmark") {}
                            QuickActionButton(icon: "xmark") {}
                        }
                        .padding(4)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipped()
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

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
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
            let thumbnail = await ThumbnailService.shared.getThumbnail(for: photo, size: size)
            await MainActor.run {
                self.image = thumbnail
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
