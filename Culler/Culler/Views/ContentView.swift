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
    @AppStorage("includeSubfolders") private var includeSubfolders: Bool = true
    @AppStorage("sortOption") private var sortOption: SortOption = .dateImported
    @AppStorage("showFilesInSidebar") private var showFilesInSidebar: Bool = false
    @State private var showLeftNav: Bool = true
    @State private var showRightPanel: Bool = true
    @SceneStorage("leftPanelWidth") private var leftPanelWidth: Double = 260
    @SceneStorage("rightPanelWidth") private var rightPanelWidth: Double = 260
    @State private var syncFolderPath: String?
    @State private var isSyncingFolder: Bool = false
    @State private var syncProgress: Double = 0
    @State private var syncResultText: String?
    @State private var syncErrors: [ImportErrorItem] = []
    @State private var showSyncErrorSheet: Bool = false
    @State private var showSyncMissingAlert: Bool = false

    enum ViewMode {
        case grid, single
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
            if viewMode == .single {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                    viewMode = .grid
                }
            }
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

    private struct LeftWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    private struct RightWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    @ViewBuilder
    private var sidebarColumn: some View {
        let folderNodes = showFilesInSidebar ? FolderNode.buildTreeWithFiles(from: photos) : FolderNode.buildTree(from: photos)
        SidebarView(
            albums: albums,
            folderNodes: folderNodes,
            showImportSheet: $showImportSheet,
            baseScope: $baseScope,
            filterFlag: $filterFlag,
            filterRating: $filterRating,
            filterColorLabel: $filterColorLabel,
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
        } onClearFilters: {
            clearFilters()
        } onSelectFile: { photo in
            currentPhoto = photo
            selectedPhotos = [photo.id]
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) {
                viewMode = .single
            }
        } onRevealFile: { photo in
            NSWorkspace.shared.selectFile(photo.filePath, inFileViewerRootedAtPath: "")
        } onDeletePhotoFromLibrary: { photo in
            if currentPhoto?.id == photo.id { currentPhoto = nil }
            selectedPhotos.remove(photo.id)
            modelContext.delete(photo)
        } onDeletePhotoFromDisk: { photo in
            let fm = FileManager.default
            try? fm.removeItem(atPath: photo.filePath)
            if currentPhoto?.id == photo.id { currentPhoto = nil }
            selectedPhotos.remove(photo.id)
            modelContext.delete(photo)
        }
        .frame(
            minWidth: showLeftNav ? 240 : 0,
            idealWidth: showLeftNav ? CGFloat(leftPanelWidth) : 0,
            maxWidth: showLeftNav ? 450 : 0
        )
        .opacity(showLeftNav ? 1 : 0)
        .allowsHitTesting(showLeftNav)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: LeftWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(LeftWidthKey.self) { w in
            if showLeftNav, w > 0 { leftPanelWidth = Double(w) }
        }
        .layoutPriority(0)
    }

    private var mainColumn: some View {
        VStack(spacing: 0) {
            toolbarRow
                contentArea
                .safeAreaInset(edge: .bottom) {
                    if !selectedPhotos.isEmpty || viewMode != .grid {
                        MarkingToolbar(
                            targetCount: resolveMarkingTargets(preferCurrent: preferCurrentPhotoForMarking).count,
                            currentRating: currentMarkingRating,
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
            showLeftNav: $showLeftNav,
            showRightPanel: $showRightPanel,
            scopeTitle: scopeTitle + (currentFolderPath != nil && includeSubfolders ? "（含子文件夹）" : ""),
            photoCount: filteredPhotos.count,
            selectedCount: selectedPhotos.count,
            hasActiveFilters: hasActiveFilters,
            onClearFilters: clearFilters,
            canSyncFolder: currentFolderPath != nil && !isSyncingFolder,
            onSyncFolder: { if let p = currentFolderPath { startSync(folderPath: p) } },
            sortOption: $sortOption,
            showRotateButtons: viewMode == .single
        )
    }

    private var contentArea: some View {
        ZStack {
            PhotoGridView(
                photos: displayedPhotos,
                selectedPhotos: $selectedPhotos,
                currentPhoto: $currentPhoto,
                scrollAnchor: gridScrollAnchor,
                onDoubleClick: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .single } }
            )
            .opacity(viewMode == .grid ? 1 : 0)
            .allowsHitTesting(viewMode == .grid)

            if viewMode == .single {
                singleViewer
                    .transition(.opacity)
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
                onBack: {
                    currentPhoto = nil
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2)) { viewMode = .grid }
                }
            )
            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
        } else if displayedPhotos.isEmpty {
            EmptyStateView()
        } else {
            EmptyStateView(systemImage: "photo", title: "请选择一张照片", subtitle: nil)
        }
    }



    @ViewBuilder
    private var inspectorColumn: some View {
        let photo = currentPhoto ?? selectedPhotos.first.flatMap({ id in photos.first { $0.id == id } })
        VStack(spacing: 0) {
            HStack {
                Text("检查器")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            InspectorView(
                photo: photo
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .frame(
            minWidth: showRightPanel ? 240 : 0,
            idealWidth: showRightPanel ? CGFloat(rightPanelWidth) : 0,
            maxWidth: showRightPanel ? 450 : 0
        )
        .opacity(showRightPanel ? 1 : 0)
        .allowsHitTesting(showRightPanel)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: RightWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(RightWidthKey.self) { w in
            if showRightPanel, w > 0 { rightPanelWidth = Double(w) }
        }
        .layoutPriority(0)
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
            if newValue == .single, currentPhoto == nil {
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
            showLeftNav = true
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .toggleLeftPanel)) { _ in
            showLeftNav.toggle()
        })

        view = AnyView(view.onReceive(NotificationCenter.default.publisher(for: .toggleRightPanel)) { _ in
            showRightPanel.toggle()
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
            Task {
                await restoreFolderPermissionsAsync()
            }
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

        view = AnyView(view.background(WindowAccessor { window in
            if let window = window, let screen = window.screen {
                let visibleFrame = screen.visibleFrame
                let newFrame = NSRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: visibleFrame.height)
                window.setFrame(newFrame, display: true)
            }
        }))

        return view
    }

    private var currentMarkingRating: Int {
        let targets = resolveMarkingTargets(preferCurrent: preferCurrentPhotoForMarking)
        guard let first = targets.first else { return 0 }
        let r = first.rating
        if r == 0 { return 0 }
        for t in targets { if t.rating != r { return 0 } }
        return r
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

        UserDefaults.standard.set(true, forKey: "expandLibrary")
        UserDefaults.standard.set(false, forKey: "expandAlbums")
        UserDefaults.standard.set(2, forKey: "inspectorTabIndex")
        let lib = UserDefaults.standard.bool(forKey: "expandLibrary")
        let alb = UserDefaults.standard.bool(forKey: "expandAlbums")
        let tab = UserDefaults.standard.integer(forKey: "inspectorTabIndex")
        guard lib == true && alb == false && tab == 2 else { fatalError("E2E: preferences not persisted") }

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

    private func restoreFolderPermissionsAsync() async {
        for folder in importedFolders {
            if let data = folder.bookmarkData {
                var stale = false
                do {
                    let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
                    let ok = url.startAccessingSecurityScopedResource()
                    if !ok {
                        print("Failed to restore permission for \(folder.folderPath)")
                    }
                } catch {
                    print("Failed to resolve bookmark for \(folder.folderPath): \(error)")
                }
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
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
