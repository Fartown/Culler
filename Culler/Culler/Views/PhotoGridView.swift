import SwiftUI
import SwiftData

struct PhotoGridView: View {
    let photos: [Photo]
    @Binding var selectedPhotos: Set<UUID>
    @Binding var currentPhoto: Photo?
    var scrollAnchor: UUID?
    var onDoubleClick: () -> Void

    @State private var thumbnailSize: CGFloat = 150
    @State private var hoveredPhoto: UUID?
    @State private var viewportWidth: CGFloat = 0

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 8)]

    var body: some View {
        Group {
            if photos.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("当前没有内容")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(photos) { photo in
                                PhotoThumbnail(
                                    photo: photo,
                                    isSelected: selectedPhotos.contains(photo.id),
                                    isHovered: hoveredPhoto == photo.id,
                                    size: thumbnailSize
                                )
                                .id(photo.id)
                            .accessibilityIdentifier("photo_thumbnail")
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
                        PhotoContextMenu(
                            targets: selectedPhotos.contains(photo.id)
                                ? photos.filter { selectedPhotos.contains($0.id) }
                                : [photo]
                        )
                    }
                            }
                        }
                        .padding(16)
                    }
                    .onAppear {
                        if let anchor = scrollAnchor {
                            DispatchQueue.main.async {
                                proxy.scrollTo(anchor, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: scrollAnchor) { _, newValue in
                        if let anchor = newValue {
                            DispatchQueue.main.async {
                                proxy.scrollTo(anchor, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: currentPhoto) { _, newPhoto in
                        if let photo = newPhoto {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                                proxy.scrollTo(photo.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(NSColor(hex: "#1a1a1a")))
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { viewportWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in viewportWidth = newValue }
            }
        )
        .onAppear {}
        .onReceive(NotificationCenter.default.publisher(for: .navigateLeft)) { _ in
            navigateBy(delta: -1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateRight)) { _ in
            navigateBy(delta: 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateUp)) { _ in
            navigateBy(delta: -gridStride())
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateDown)) { _ in
            navigateBy(delta: gridStride())
        }
        .onKeyPress(.leftArrow) {
            navigateBy(delta: -1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateBy(delta: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            navigateBy(delta: -gridStride())
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateBy(delta: gridStride())
            return .handled
        }
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

    private func currentIndex() -> Int {
        if let current = currentPhoto, let idx = photos.firstIndex(where: { $0.id == current.id }) { return idx }
        if let id = selectedPhotos.first, let idx = photos.firstIndex(where: { $0.id == id }) { return idx }
        return 0
    }

    private func navigateBy(delta: Int) {
        let count = photos.count
        if count == 0 { return }
        var idx = currentIndex() + delta
        idx = max(0, min(count - 1, idx))
        let target = photos[idx]
        selectedPhotos = [target.id]
        currentPhoto = target
    }

    private func gridStride() -> Int {
        let spacing: CGFloat = 8
        let padding: CGFloat = 32
        let usable = max(0, viewportWidth - padding + spacing)
        let perRow = Int(floor(usable / (thumbnailSize + spacing)))
        return max(1, perRow)
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

            // Video Indicator
            if photo.isVideo {
                ZStack {
                    Color.clear.frame(width: size, height: size)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: size * 0.28, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
                        .accessibilityLabel("视频")
                }
            }
            
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

extension ColorLabel {
    var sfSymbol: String {
        switch self {
        case .none: return "circle"
        case .red: return "circle.fill"
        case .yellow: return "circle.fill"
        case .green: return "circle.fill"
        case .blue: return "circle.fill"
        case .purple: return "circle.fill"
        }
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
        .task(id: photo.id) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        await MainActor.run {
            image = nil
            hasError = false
        }

        let result = await ThumbnailService.shared.getThumbnail(for: photo, size: size)
        await MainActor.run {
            switch result {
            case .success(let thumbnail):
                image = thumbnail
                hasError = false
            case .failure:
                image = nil
                hasError = true
            }
        }
    }
}

struct PhotoContextMenu: View {
    @Environment(\.modelContext) private var modelContext
    let targets: [Photo]
    
    private let rawExtensions = ["raw", "cr2", "cr3", "nef", "arw", "dng", "orf", "rw2"]
    private let jpgExtensions = ["jpg", "jpeg"]

    var body: some View {
        Group {
            Menu("旗标") {
                Button("已选") { targets.forEach { $0.flag = .pick } }
                Button("已拒") { targets.forEach { $0.flag = .reject } }
                Button("未标记") { targets.forEach { $0.flag = .none } }
            }

            Menu("评分") {
                ForEach(0...5, id: \.self) { rating in
                    Button(rating == 0 ? "清除" : String(repeating: "★", count: rating)) {
                        targets.forEach { $0.rating = rating }
                    }
                }
            }

            Menu("颜色标签") {
                ForEach(ColorLabel.allCases, id: \.rawValue) { label in
                    Button(label.name) {
                        targets.forEach { $0.colorLabel = label }
                    }
                }
            }

            Divider()

            Button("清除旗标") {
                targets.forEach { $0.flag = .none }
            }

            Button(role: .destructive) {
                targets.forEach { modelContext.delete($0) }
            } label: {
                Text("从库移除")
            }

            Button(role: .destructive) {
                targets.forEach { deleteFromDisk($0) }
            } label: {
                Text("从磁盘删除（仅当前文件）")
            }

            Button(role: .destructive) {
                deleteFromDiskWithRawJpgPair(targets)
            } label: {
                Text("从磁盘删除（RAW+JPG）")
            }

            if let single = targets.first, targets.count == 1 {
                Divider()
                Button("在 Finder 中显示") {
                    NSWorkspace.shared.selectFile(single.filePath, inFileViewerRootedAtPath: "")
                }
            }
        }
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
    
    private func deleteFromDiskWithRawJpgPair(_ photos: [Photo]) {
        let knownPhotosByPath: [String: Photo] = {
            var map: [String: Photo] = [:]
            for photo in photos {
                map[photo.filePath] = photo
                map[photo.fileURL.path] = photo
            }
            return map
        }()

        var candidatePaths = Set<String>()
        for photo in photos {
            candidatePaths.formUnion(pairedPaths(for: photo))
        }

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
