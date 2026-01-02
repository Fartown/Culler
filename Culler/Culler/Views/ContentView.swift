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
    @State private var gridScrollAnchor: UUID?

    @State private var filterRating: Int = 0
    @State private var filterFlag: Flag? = nil
    @State private var filterColorLabel: ColorLabel? = nil
    @State private var filterFolder: String? = nil
    @State private var showAlbumManager = false
    @State private var includeSubfolders: Bool = false
    @State private var showLeftNav: Bool = true
    @State private var showRightPanel: Bool = true

    enum ViewMode {
        case grid, single, fullscreen, folderManagement, folderBrowser
    }

    var filteredPhotos: [Photo] {
        photos.filter { photo in
            if let folder = filterFolder {
                let folderPath = URL(fileURLWithPath: folder).standardizedFileURL.path
                let photoDir = URL(fileURLWithPath: photo.filePath).deletingLastPathComponent().standardizedFileURL.path
                if includeSubfolders {
                    let base = folderPath.hasSuffix("/") ? folderPath : folderPath + "/"
                    if !(photoDir == folderPath || photoDir.hasPrefix(base)) { return false }
                } else {
                    if photoDir != folderPath { return false }
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
            if showLeftNav {
                SidebarView(
                    albums: albums,
                    showImportSheet: $showImportSheet,
                    filterRating: $filterRating,
                    filterFlag: $filterFlag,
                    filterColorLabel: $filterColorLabel,
                    filterFolder: $filterFolder,
                    viewMode: $viewMode,
                    showLeftNav: $showLeftNav
                )
                .frame(minWidth: 160, idealWidth: 180, maxWidth: 300)
                .layoutPriority(0)
            }

            if viewMode == .folderBrowser {
                let nodes = FolderNode.buildTreeWithFiles(from: photos)
                FoldersTreeView(
                    nodes: nodes,
                    onSelect: { node in
                        filterFolder = node.fullPath
                    },
                    onRevealInFinder: { node in
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: node.fullPath)
                    },
                    onDeleteRecursively: { node in
                        deleteNodeRecursively(node)
                    },
                    onDeleteFromDisk: { node in
                        deleteNodeFromDisk(node)
                    },
                    onImport: {
                        NotificationCenter.default.post(name: .importPhotos, object: nil)
                    }
                )
                .frame(minWidth: 220, idealWidth: 280, maxWidth: 400)
                .layoutPriority(0)
            }

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
                            scrollAnchor: gridScrollAnchor,
                            onDoubleClick: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .single } }
                        )
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                    case .single:
                        if let photo = currentPhoto {
                            SinglePhotoView(
                                photo: photo,
                                photos: filteredPhotos,
                                currentPhoto: $currentPhoto,
                                onBack: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .grid } }
                            )
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                        } else {
                            if filteredPhotos.isEmpty {
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
                                VStack {
                                    Spacer()
                                    Text("Select a photo")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    case .fullscreen:
                        if let photo = currentPhoto {
                            FullscreenView(
                                photo: photo,
                                photos: filteredPhotos,
                                currentPhoto: $currentPhoto,
                                onExit: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .single } }
                            )
                            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                        } else if filteredPhotos.isEmpty {
                            VStack {
                                Spacer()
                                Image(systemName: "tray")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("当前没有内容")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    case .folderManagement:
                        ImportManagementView(
                            filterFolder: $filterFolder,
                            viewMode: $viewMode,
                            includeSubfolders: $includeSubfolders
                        )
                    case .folderBrowser:
                        FolderPreviewView(
                            photos: filteredPhotos,
                            selectedPhotos: $selectedPhotos,
                            currentPhoto: $currentPhoto,
                            includeSubfolders: $includeSubfolders,
                            folderPath: filterFolder
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                .overlay(alignment: .topLeading) {
                    if !showLeftNav {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { showLeftNav = true }
                        } label: {
                            Image(systemName: "sidebar.leading")
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                        .background(Color(NSColor(hex: "#2a2a2a")))
                        .cornerRadius(6)
                        .padding(.leading, 8)
                        .padding(.top, 8)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if !showRightPanel {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { showRightPanel = true }
                        } label: {
                            Image(systemName: "sidebar.trailing")
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                        .background(Color(NSColor(hex: "#2a2a2a")))
                        .cornerRadius(6)
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)

            if showRightPanel, viewMode != .fullscreen,
               let photo = currentPhoto ?? selectedPhotos.first.flatMap({ id in photos.first { $0.id == id } }) {
                VStack(spacing: 0) {
                    HStack {
                        Text("信息")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { showRightPanel = false }
                        } label: { Image(systemName: "chevron.right") }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)

                    InfoPanelView(photo: photo)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 450)
                .layoutPriority(0)
            }
        }
        .background(Color(NSColor(hex: "#1a1a1a")))
        .sheet(isPresented: $showImportSheet) {
            ImportView(isPresented: $showImportSheet)
        }
        .sheet(isPresented: $showAlbumManager) {
            AlbumManagementView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .onChange(of: viewMode) { _, newValue in
            if (newValue == .single || newValue == .fullscreen), currentPhoto == nil {
                if let id = selectedPhotos.first, let photo = photos.first(where: { $0.id == id }) {
                    currentPhoto = photo
                }
            } else if newValue == .grid {
                if let anchorId = currentPhoto?.id {
                    gridScrollAnchor = anchorId
                    let visibleIds = Set(filteredPhotos.map { $0.id })
                    if visibleIds.contains(anchorId) {
                        selectedPhotos = [anchorId]
                    } else {
                        selectedPhotos = selectedPhotos.intersection(visibleIds)
                    }
                } else {
                    let visibleIds = Set(filteredPhotos.map { $0.id })
                    selectedPhotos = selectedPhotos.intersection(visibleIds)
                }
                currentPhoto = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .importPhotos)) { _ in
            showImportSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .enterFolderBrowser)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                viewMode = .folderBrowser
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .enterFullscreen)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                viewMode = .fullscreen
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .selectAll)) { _ in
            selectedPhotos = Set(filteredPhotos.map { $0.id })
        }
        
        .onAppear {
            KeyboardShortcutManager.shared.start()
        }
        .onDisappear {
            KeyboardShortcutManager.shared.stop()
        }
        .safeAreaInset(edge: .bottom) {
            MarkingToolbar(
                selectedPhotos: selectedPhotos,
                photos: photos,
                modelContext: modelContext
            )
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

    private func deleteNodeRecursively(_ node: FolderNode) {
        for p in node.photos { modelContext.delete(p) }
        for child in node.children ?? [] { deleteNodeRecursively(child) }
    }

    private func deleteNodeFromDisk(_ node: FolderNode) {
        let fm = FileManager.default
        for p in node.photos {
            try? fm.removeItem(atPath: p.filePath)
            modelContext.delete(p)
        }
        for child in node.children ?? [] { deleteNodeFromDisk(child) }
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
