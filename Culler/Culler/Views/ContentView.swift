import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [Photo]
    @Query private var albums: [Album]

    @State private var selectedPhotos: Set<UUID> = []
    @State private var currentPhoto: Photo?
    @State private var viewMode: ViewMode = .grid
    @State private var showImportSheet = false
    @State private var showFilterPanel = true
    @State private var sidebarWidth: CGFloat = 200

    @State private var filterRating: Int = 0
    @State private var filterFlag: Flag? = nil
    @State private var filterColorLabel: ColorLabel? = nil
    @State private var filterFolder: String? = nil

    enum ViewMode {
        case grid, single, fullscreen, folderManagement
    }

    var filteredPhotos: [Photo] {
        photos.filter { photo in
            if let folder = filterFolder {
                let photoDir = URL(fileURLWithPath: photo.filePath).deletingLastPathComponent().path
                if photoDir != folder {
                    return false
                }
            }
            if filterRating > 0 && photo.rating < filterRating {
                return false
            }
            if let flag = filterFlag, photo.flag != flag {
                return false
            }
            if let colorLabel = filterColorLabel, photo.colorLabel != colorLabel {
                return false
            }
            return true
        }
    }

    var body: some View {
        HSplitView {
            SidebarView(
                albums: albums,
                showImportSheet: $showImportSheet,
                filterRating: $filterRating,
                filterFlag: $filterFlag,
                filterColorLabel: $filterColorLabel,
                filterFolder: $filterFolder,
                viewMode: $viewMode
            )
            .frame(minWidth: 180, idealWidth: 180, maxWidth: 300)

            VStack(spacing: 0) {
                ToolbarView(
                    viewMode: $viewMode,
                    photoCount: filteredPhotos.count,
                    selectedCount: selectedPhotos.count
                )

                ZStack {
                    switch viewMode {
                    case .grid:
                        PhotoGridView(
                            photos: filteredPhotos,
                            selectedPhotos: $selectedPhotos,
                            currentPhoto: $currentPhoto,
                            onDoubleClick: { viewMode = .single }
                        )
                    case .single:
                        if let photo = currentPhoto {
                            SinglePhotoView(
                                photo: photo,
                                photos: filteredPhotos,
                                currentPhoto: $currentPhoto,
                                onBack: { viewMode = .grid }
                            )
                        } else {
                            VStack {
                                Spacer()
                                Text("Select a photo")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    case .fullscreen:
                        if let photo = currentPhoto {
                            FullscreenView(
                                photo: photo,
                                photos: filteredPhotos,
                                currentPhoto: $currentPhoto,
                                onExit: { viewMode = .single }
                            )
                        }
                    case .folderManagement:
                        ImportManagementView(
                            filterFolder: $filterFolder,
                            viewMode: $viewMode
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

                MarkingToolbar(
                    selectedPhotos: selectedPhotos,
                    photos: photos,
                    modelContext: modelContext
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if viewMode != .fullscreen, let photo = currentPhoto ?? selectedPhotos.first.flatMap({ id in photos.first { $0.id == id } }) {
                InfoPanelView(photo: photo)
                    .frame(minWidth: 220, idealWidth: 220, maxWidth: 450)
                    .layoutPriority(2)
            }
        }
        .background(Color(NSColor(hex: "#1a1a1a")))
        .sheet(isPresented: $showImportSheet) {
            ImportView(isPresented: $showImportSheet)
        }
        .onChange(of: viewMode) { _, newValue in
            if (newValue == .single || newValue == .fullscreen), currentPhoto == nil {
                if let id = selectedPhotos.first, let photo = photos.first(where: { $0.id == id }) {
                    currentPhoto = photo
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .importPhotos)) { _ in
            showImportSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .setFlag)) { notification in
            if let flag = notification.object as? Flag {
                setFlagForSelected(flag)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .setRating)) { notification in
            if let rating = notification.object as? Int {
                setRatingForSelected(rating)
            }
        }
        .onAppear {
            KeyboardShortcutManager.shared.start()
        }
        .onDisappear {
            KeyboardShortcutManager.shared.stop()
        }
    }

    private func setFlagForSelected(_ flag: Flag) {
        if let photo = currentPhoto {
            photo.flag = flag
            return
        }
        if selectedPhotos.isEmpty {
            return
        }
        for id in selectedPhotos {
            if let photo = photos.first(where: { $0.id == id }) {
                photo.flag = flag
            }
        }
    }

    private func setRatingForSelected(_ rating: Int) {
        if let photo = currentPhoto {
            photo.rating = rating
            return
        }
        if selectedPhotos.isEmpty {
            return
        }
        for id in selectedPhotos {
            if let photo = photos.first(where: { $0.id == id }) {
                photo.rating = rating
            }
        }
    }
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1
        )
    }
}
