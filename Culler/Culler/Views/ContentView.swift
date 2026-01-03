import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [Photo]
    @Query private var albums: [Album]
    @Query private var importedFolders: [ImportedFolder]

    @State private var selectedPhotos: Set<UUID> = []
    @State private var currentPhoto: Photo?
    @State private var viewMode: ViewMode = .grid
    @State private var showImportSheet = false
    @State private var gridScrollAnchor: UUID?

    enum BaseScope: Equatable {
        case all
        case folder(path: String)
        case album(id: UUID)
    }

    @State private var baseScope: BaseScope = .all
    @State private var filterRating: Int = 0
    @State private var filterFlag: Flag? = nil
    @State private var filterColorLabel: ColorLabel? = nil
    @State private var showAlbumManager = false
    @State private var includeSubfolders: Bool = true
    @AppStorage("sortOption") private var sortOption: SortOption = .dateImported
    @State private var showLeftNav: Bool = true
    @State private var showRightPanel: Bool = true
    @State private var syncFolderPath: String?
    @State private var isSyncingFolder: Bool = false
    @State private var syncProgress: Double = 0
    @State private var syncResultText: String?
    @State private var syncErrors: [ImportErrorItem] = []
    @State private var showSyncErrorSheet: Bool = false
    @State private var showSyncMissingAlert: Bool = false

    enum ViewMode {
        case grid, single, fullscreen
    }

    private var scopedPhotos: [Photo] {
        switch baseScope {
        case .all:
            return photos
        case .folder(let path):
            let folderPath = URL(fileURLWithPath: path).standardizedFileURL.path
            let basePrefix = folderPath.hasSuffix("/") ? folderPath : folderPath + "/"
            return photos.filter { photo in
                let photoDir = URL(fileURLWithPath: photo.filePath).deletingLastPathComponent().standardizedFileURL.path
                if includeSubfolders {
                    return photoDir == folderPath || photoDir.hasPrefix(basePrefix)
                }
                return photoDir == folderPath
            }
        case .album(let id):
            return photos.filter { photo in
                (photo.albums ?? []).contains(where: { $0.id == id })
            }
        }
    }

    private var filteredPhotos: [Photo] {
        scopedPhotos.filter { photo in
            if filterRating > 0, photo.rating < filterRating { return false }
            if let flag = filterFlag, photo.flag != flag { return false }
            if let colorLabel = filterColorLabel, photo.colorLabel != colorLabel { return false }
            return true
        }
    }

    private var displayedPhotos: [Photo] {
        filteredPhotos.sorted(by: sortOption)
    }

    private var currentFolderPath: String? {
        if case .folder(let path) = baseScope { return path }
        return nil
    }

    private var scopeTitle: String {
        switch baseScope {
        case .all:
            return "全部照片"
        case .folder(let path):
            return URL(fileURLWithPath: path).lastPathComponent
        case .album(let id):
            return albums.first(where: { $0.id == id })?.name ?? "相册"
        }
    }

    private var hasActiveFilters: Bool {
        filterFlag != nil || filterRating > 0 || filterColorLabel != nil
    }

    private var preferCurrentPhotoForMarking: Bool {
        viewMode != .grid
    }

    private func clearFilters() {
        filterFlag = nil
        filterRating = 0
        filterColorLabel = nil
    }

    private func syncSelectionWithDisplayedPhotos() {
        let visibleIds = Set(displayedPhotos.map { $0.id })
        selectedPhotos = selectedPhotos.intersection(visibleIds)
        if let currentPhoto, !visibleIds.contains(currentPhoto.id) {
            self.currentPhoto = nil
        }
    }

    private func resolveMarkingTargets(preferCurrent: Bool) -> [Photo] {
        if preferCurrent, let currentPhoto { return [currentPhoto] }
        if !selectedPhotos.isEmpty {
            var resolved: [Photo] = []
            resolved.reserveCapacity(selectedPhotos.count)
            for id in selectedPhotos {
                if let photo = photos.first(where: { $0.id == id }) {
                    resolved.append(photo)
                }
            }
            return resolved
        }
        if let currentPhoto { return [currentPhoto] }
        return []
    }

    private func applyFlag(_ flag: Flag) {
        let targets = resolveMarkingTargets(preferCurrent: preferCurrentPhotoForMarking)
        targets.forEach { $0.flag = flag }
    }

    private func applyRating(_ rating: Int) {
        let targets = resolveMarkingTargets(preferCurrent: preferCurrentPhotoForMarking)
        targets.forEach { $0.rating = rating }
    }

    private func applyColorLabel(_ label: ColorLabel) {
        let targets = resolveMarkingTargets(preferCurrent: preferCurrentPhotoForMarking)
        targets.forEach { $0.colorLabel = label }
    }

    private var splitLayout: some View {
        HSplitView {
            sidebarColumn
            mainColumn
            inspectorColumn
        }
    }

    @ViewBuilder
    private var sidebarColumn: some View {
        if showLeftNav {
            let folderNodes = FolderNode.buildTree(from: photos)
            SidebarView(
                albums: albums,
                folderNodes: folderNodes,
                showImportSheet: $showImportSheet,
                baseScope: $baseScope,
                filterFlag: $filterFlag,
                includeSubfolders: $includeSubfolders,
                showAlbumManager: $showAlbumManager,
                showLeftNav: $showLeftNav
            ) { node in
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: node.fullPath)
            } onDeleteRecursively: { node in
                deleteNodeRecursively(node)
            } onDeleteFromDisk: { node in
                deleteNodeFromDisk(node)
            } onSyncFolder: { node in
                startSync(folderPath: node.fullPath)
            }
            .frame(minWidth: 180, idealWidth: 220, maxWidth: 360)
            .layoutPriority(0)
        }
    }

    private var mainColumn: some View {
        VStack(spacing: 0) {
            toolbarRow
                contentArea
                .safeAreaInset(edge: .bottom) {
                    if viewMode != .fullscreen, (!selectedPhotos.isEmpty || viewMode != .grid) {
                        MarkingToolbar(
                            targetCount: resolveMarkingTargets(preferCurrent: preferCurrentPhotoForMarking).count,
                            onSetFlag: applyFlag,
                            onSetRating: applyRating,
                            onSetColorLabel: applyColorLabel
                        )
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1)
    }

    private var toolbarRow: some View {
        ToolbarView(
            viewMode: $viewMode,
            showLeftNav: $showLeftNav,
            showRightPanel: $showRightPanel,
            scopeTitle: scopeTitle + (currentFolderPath != nil && includeSubfolders ? "（含子文件夹）" : ""),
            photoCount: filteredPhotos.count,
            selectedCount: selectedPhotos.count,
            hasActiveFilters: hasActiveFilters,
            onClearFilters: clearFilters,
            canSyncFolder: currentFolderPath != nil && !isSyncingFolder,
            onSyncFolder: { if let p = currentFolderPath { startSync(folderPath: p) } },
            sortOption: $sortOption
        )
    }

    private var contentArea: some View {
        ZStack {
            switch viewMode {
            case .grid:
                PhotoGridView(
                    photos: displayedPhotos,
                    selectedPhotos: $selectedPhotos,
                    currentPhoto: $currentPhoto,
                    scrollAnchor: gridScrollAnchor,
                    onDoubleClick: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .single } }
                )
                .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            case .single:
                singleViewer
            case .fullscreen:
                fullscreenViewer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .layoutPriority(1)
    }

    @ViewBuilder
    private var singleViewer: some View {
        if let photo = currentPhoto {
            SinglePhotoView(
                photo: photo,
                photos: displayedPhotos,
                currentPhoto: $currentPhoto,
                onBack: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .grid } }
            )
            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
        } else if displayedPhotos.isEmpty {
            EmptyStateView()
        } else {
            EmptyStateView(systemImage: "photo", title: "请选择一张照片", subtitle: nil)
        }
    }

    @ViewBuilder
    private var fullscreenViewer: some View {
        if let photo = currentPhoto {
            FullscreenView(
                photo: photo,
                photos: displayedPhotos,
                currentPhoto: $currentPhoto,
                onExit: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .single } }
            )
            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
        } else if displayedPhotos.isEmpty {
            EmptyStateView()
        }
    }

    @ViewBuilder
    private var inspectorColumn: some View {
        if showRightPanel, viewMode != .fullscreen {
            let photo = currentPhoto ?? selectedPhotos.first.flatMap({ id in photos.first { $0.id == id } })
            VStack(spacing: 0) {
                HStack {
                    Text("检查器")
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

                InspectorView(
                    photo: photo,
                    filterFlag: $filterFlag,
                    filterRating: $filterRating,
                    filterColorLabel: $filterColorLabel,
                    onClearFilters: clearFilters
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            .frame(minWidth: 240, idealWidth: 280, maxWidth: 450)
            .layoutPriority(0)
        }
    }

    @ViewBuilder
    private var syncProgressOverlay: some View {
        if isSyncingFolder, let path = syncFolderPath {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ProgressView(value: syncProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 240)
                    Text("同步中：\(URL(fileURLWithPath: path).lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(.top, 10)
            .padding(.horizontal, 12)
        }
    }

    var body: some View {
        buildBody()
    }

    private func buildBody() -> AnyView {
        var view: AnyView = AnyView(
            splitLayout
                .background(Color(NSColor(hex: "#1a1a1a")))
                .overlay(alignment: .top) { syncProgressOverlay }
        )

        view = AnyView(view.sheet(isPresented: $showImportSheet) {
            ImportView(isPresented: $showImportSheet)
        })

        view = AnyView(view.sheet(isPresented: $showAlbumManager) {
            AlbumManagementView()
                .frame(minWidth: 900, minHeight: 600)
        })

        view = AnyView(view.sheet(isPresented: $showSyncErrorSheet) {
            ImportErrorView(errors: syncErrors) {
                showSyncErrorSheet = false
            }
        })

        view = AnyView(view.onChange(of: viewMode) { _, newValue in
            if (newValue == .single || newValue == .fullscreen), currentPhoto == nil {
                if let id = selectedPhotos.first, let photo = photos.first(where: { $0.id == id }) {
                    currentPhoto = photo
                } else if let first = displayedPhotos.first {
                    currentPhoto = first
                    selectedPhotos = [first.id]
                }
            } else if newValue == .grid {
                if let anchorId = currentPhoto?.id {
                    gridScrollAnchor = anchorId
                    let visibleIds = Set(displayedPhotos.map { $0.id })
                    if visibleIds.contains(anchorId) {
                        selectedPhotos = [anchorId]
                    } else {
                        selectedPhotos = selectedPhotos.intersection(visibleIds)
                    }
                } else {
                    let visibleIds = Set(displayedPhotos.map { $0.id })
                    selectedPhotos = selectedPhotos.intersection(visibleIds)
                }
                currentPhoto = nil
                syncSelectionWithDisplayedPhotos()
            }
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .importPhotos)) { _ in
            showImportSheet = true
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .enterFolderBrowser)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                showLeftNav = true
            }
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .enterFullscreen)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                viewMode = .fullscreen
            }
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .setFlag)) { notification in
            if let flag = notification.object as? Flag {
                applyFlag(flag)
            }
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .setRating)) { notification in
            if let rating = notification.object as? Int {
                applyRating(rating)
            }
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .selectAll)) { _ in
            selectedPhotos = Set(displayedPhotos.map { $0.id })
        })

        view = AnyView(view.onChange(of: baseScope) { _, _ in syncSelectionWithDisplayedPhotos() })
        view = AnyView(view.onChange(of: includeSubfolders) { _, _ in syncSelectionWithDisplayedPhotos() })
        view = AnyView(view.onChange(of: filterFlag) { _, _ in syncSelectionWithDisplayedPhotos() })
        view = AnyView(view.onChange(of: filterRating) { _, _ in syncSelectionWithDisplayedPhotos() })
        view = AnyView(view.onChange(of: filterColorLabel) { _, _ in syncSelectionWithDisplayedPhotos() })

        view = AnyView(view.onAppear { KeyboardShortcutManager.shared.start() })
        view = AnyView(view.onDisappear { KeyboardShortcutManager.shared.stop() })

        view = AnyView(view.onAppear {
            UITestDataSeeder.seedIfNeeded(into: modelContext)
        })

        view = AnyView(view.onAppear {
            if ProcessInfo.processInfo.arguments.contains("-e2e") {
                Task { @MainActor in
                    await runE2ESmoke()
                }
            }
        })

        view = AnyView(view.alert("同步完成", isPresented: Binding(get: { syncResultText != nil }, set: { if !$0 { syncResultText = nil } })) {
            Button("好的") { syncResultText = nil }
        } message: {
            Text(syncResultText ?? "")
        })

        view = AnyView(view.alert("需要重新导入/授权", isPresented: $showSyncMissingAlert) {
            Button("重新导入") {
                showImportSheet = true
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("文件夹权限或路径已变更。请重新导入该文件夹后再同步。")
        })

        return view
    }

    @MainActor
    private func runE2ESmoke() async {
        if photos.isEmpty {
            UITestDataSeeder.seedIfNeeded(into: modelContext)
        }

        // wait one run loop for @Query refresh
        try? await Task.sleep(nanoseconds: 150_000_000)

        guard let first = displayedPhotos.first else {
            fatalError("E2E: no photos after seeding")
        }

        selectedPhotos = [first.id]
        currentPhoto = first
        viewMode = .single

        applyFlag(.pick)
        guard currentPhoto?.flag == .pick else { fatalError("E2E: flag not applied") }

        applyRating(5)
        guard currentPhoto?.rating == 5 else { fatalError("E2E: rating not applied") }

        applyColorLabel(.red)
        guard currentPhoto?.colorLabel == .red else { fatalError("E2E: color label not applied") }

        NSApp.terminate(nil)
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

    private func startSync(folderPath: String) {
        if isSyncingFolder { return }

        isSyncingFolder = true
        syncFolderPath = folderPath
        syncProgress = 0
        syncErrors = []
        syncResultText = nil

        Task {
            do {
                let summary = try await FolderSyncService.sync(
                    folderPath: folderPath,
                    photos: photos,
                    importedFolders: importedFolders,
                    modelContext: modelContext,
                    progress: { value in
                        Task { @MainActor in
                            syncProgress = value
                        }
                    }
                )

                await MainActor.run {
                    isSyncingFolder = false
                    syncFolderPath = nil
                    syncProgress = 0

                    if summary.folderMissing {
                        syncResultText = "文件夹已不存在，已从库中移除对应内容。"
                    } else {
                        syncResultText = "新增 \(summary.addedCount) 张，移除 \(summary.removedCount) 张。"
                    }

                    if !summary.errors.isEmpty {
                        syncErrors = summary.errors
                        showSyncErrorSheet = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSyncingFolder = false
                    syncFolderPath = nil
                    syncProgress = 0
                    if let syncError = error as? FolderSyncError {
                        switch syncError {
                        case .permissionDenied:
                            showSyncMissingAlert = true
                        case .notDirectory:
                            syncResultText = syncError.localizedDescription
                        }
                    } else {
                        syncResultText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    }
                }
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
