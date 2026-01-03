import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isDragging = false
    @State private var selectedFiles: [URL] = []
    @State private var importMode: ImportMode = .reference
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var processedCount = 0
    @State private var importedCount = 0
    @State private var totalCount = 0
    @State private var importErrors: [ImportErrorItem] = []
    @State private var showImportErrorSheet = false
    @State private var statusText: String?
    @State private var selectedFolderPaths: Set<String> = []

    enum ImportMode: String, CaseIterable {
        case reference = "Reference"
        case copy = "Copy to Library"
    }

    let supportedTypes: [UTType] = [.jpeg, .png, .heic, .tiff, .rawImage, .movie]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Import Photos")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if isImporting {
                VStack(spacing: 16) {
                    ProgressView(value: importProgress)
                        .progressViewStyle(.linear)
                    VStack(spacing: 6) {
                        Text("Importing \(processedCount) of \(totalCount)...")
                            .foregroundColor(.secondary)
                        if let statusText {
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(40)
            } else if selectedFiles.isEmpty {
                DropZoneView(
                    isDragging: $isDragging,
                    onDrop: handleDrop,
                    onBrowse: browseFiles
                )
                .padding(24)
            } else {
                VStack(spacing: 16) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(selectedFiles, id: \.absoluteString) { url in
                                HStack {
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                    Spacer()
                                    Button(action: {
                                        selectedFiles.removeAll { $0 == url }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor(hex: "#2a2a2a")))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxHeight: 200)

                    Text("\(selectedFiles.count) files selected")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    Picker("Import Mode", selection: $importMode) {
                        ForEach(ImportMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)

                    HStack {
                        Button("Clear") {
                            selectedFiles = []
                        }
                        .buttonStyle(.bordered)

                        Button("Add More...") {
                            browseFiles()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(24)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Import") {
                    performImport()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFiles.isEmpty || isImporting)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .background(Color(NSColor(hex: "#1f1f1f")))
        .sheet(isPresented: $showImportErrorSheet) {
            ImportErrorView(errors: importErrors) {
                showImportErrorSheet = false
                isPresented = false
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            addFilesFromURL(url)
                        }
                    }
                }
            }
        }
        return true
    }

    private func addFilesFromURL(_ url: URL) {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            selectedFolderPaths.insert(url.standardizedFileURL.path)
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if isImageFile(fileURL) && !selectedFiles.contains(fileURL) {
                        selectedFiles.append(fileURL)
                    }
                }
            }
        } else if isImageFile(url) && !selectedFiles.contains(url) {
            selectedFiles.append(url)
            selectedFolderPaths.insert(url.deletingLastPathComponent().standardizedFileURL.path)
        }
    }

    private func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "tiff", "tif", "raw", "cr2", "cr3", "nef", "arw", "dng", "orf", "rw2"]
        if imageExtensions.contains(ext) { return true }
        if let type = UTType(filenameExtension: ext) {
            return type.conforms(to: .movie) || (type.conforms(to: .audiovisualContent) && !type.conforms(to: .audio))
        }
        let videoFallback: Set<String> = [
            "mov", "mp4", "m4v", "avi", "mkv", "webm", "wmv", "flv", "f4v",
            "mpg", "mpeg", "m2v", "ts", "mts", "m2ts",
            "3gp", "3g2", "asf", "ogv", "mxf", "vob", "dv"
        ]
        return videoFallback.contains(ext)
    }

    private func browseFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = supportedTypes

        if panel.runModal() == .OK {
            for url in panel.urls {
                addFilesFromURL(url)
            }
        }
    }

    private func performImport() {
        isImporting = true
        totalCount = selectedFiles.count
        processedCount = 0
        importedCount = 0
        importErrors = []
        importProgress = 0
        statusText = nil

        Task {
            let existingPaths = await MainActor.run { existingImportedFilePathSet() }
            var seenPaths = existingPaths
            if importMode == .reference {
                await MainActor.run {
                    statusText = "正在保存文件夹权限..."
                }
                await MainActor.run {
                    upsertImportedFolderBookmarks()
                }
            }
            for url in selectedFiles {
                let finalURL: URL
                
                // 1. Handle Copy/Reference Logic
                if importMode == .copy {
                    do {
                        finalURL = try copyToLibrary(sourceURL: url)
                    } catch {
                        let reason = (error as NSError).localizedDescription
                        await MainActor.run {
                            processedCount += 1
                            importErrors.append(ImportErrorItem(filename: url.lastPathComponent, reason: "Copy failed: \(reason)"))
                            importProgress = Double(processedCount) / Double(max(1, totalCount))
                        }
                        continue
                    }
                } else {
                    finalURL = url
                }

                // 1.5 Deduplicate by path (MVP)
                if seenPaths.contains(finalURL.path) {
                    await MainActor.run {
                        processedCount += 1
                        importErrors.append(ImportErrorItem(filename: url.lastPathComponent, reason: "Skipped: already imported"))
                        importProgress = Double(processedCount) / Double(max(1, totalCount))
                    }
                    continue
                }
                seenPaths.insert(finalURL.path)

                // 2. Create Security Bookmark (Crucial for Sandboxed Apps)
                var bookmark: Data? = nil
                // For both Reference and Copy modes, we might need bookmarks. 
                // Even for copied files, if they are outside the app's container, we might need them, 
                // but usually copied files in app support don't need explicit bookmarks if we access them via standard paths.
                // However, 'Reference' mode ABSOLUTELY needs them.
                if importMode == .reference {
                    do {
                        // Start accessing to ensure we have permission to create the bookmark
                        let accessing = finalURL.startAccessingSecurityScopedResource()
                        defer { if accessing { finalURL.stopAccessingSecurityScopedResource() } }
                        
                        bookmark = try finalURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    } catch {
                        print("Failed to create bookmark for \(finalURL.path): \(error)")
                        await MainActor.run {
                            processedCount += 1
                            importErrors.append(ImportErrorItem(filename: url.lastPathComponent, reason: "Permission error: Failed to create security bookmark"))
                            importProgress = Double(processedCount) / Double(max(1, totalCount))
                        }
                        // We continue even if bookmark fails, but the image might not load later.
                        // Alternatively, we could fail the import here. Let's fail it to be safe.
                        continue
                    }
                }

                // 3. Create Model
                let photo = Photo(filePath: finalURL.path, bookmarkData: bookmark)
                await MainActor.run {
                    modelContext.insert(photo)
                    processedCount += 1
                    importedCount += 1
                    importProgress = Double(processedCount) / Double(max(1, totalCount))
                    statusText = finalURL.deletingLastPathComponent().lastPathComponent
                }
            }

            await MainActor.run {
                isImporting = false
                if !importErrors.isEmpty {
                    showImportErrorSheet = true
                } else {
                    isPresented = false
                }
            }
        }
    }

    @MainActor
    private func existingImportedFilePathSet() -> Set<String> {
        let desc = FetchDescriptor<Photo>()
        let photos = (try? modelContext.fetch(desc)) ?? []
        return Set(photos.map(\.filePath))
    }

    private func upsertImportedFolderBookmarks() {
        let uniquePaths = Array(selectedFolderPaths).sorted { $0.lowercased() < $1.lowercased() }
        for path in uniquePaths {
            let folderURL = URL(fileURLWithPath: path)
            let didStart = folderURL.startAccessingSecurityScopedResource()
            defer { if didStart { folderURL.stopAccessingSecurityScopedResource() } }

            do {
                let data = try folderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                let standardizedPath = folderURL.standardizedFileURL.path
                let descriptor = FetchDescriptor<ImportedFolder>(predicate: #Predicate { $0.folderPath == standardizedPath })
                if let existing = try modelContext.fetch(descriptor).first {
                    existing.bookmarkData = data
                } else {
                    modelContext.insert(ImportedFolder(folderPath: standardizedPath, bookmarkData: data))
                }
            } catch {
                // 忽略：没有权限时，后续同步会提示重新导入/授权
            }
        }
    }

    private func libraryDirectoryURL() throws -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let base = appSupport.first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let dir = base
            .appendingPathComponent("Culler", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)

        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func copyToLibrary(sourceURL: URL) throws -> URL {
        let dir = try libraryDirectoryURL()
        let fileManager = FileManager.default

        let directCandidate = dir.appendingPathComponent(sourceURL.lastPathComponent)
        if fileManager.fileExists(atPath: directCandidate.path) {
            let srcSize = (try? fileManager.attributesOfItem(atPath: sourceURL.path)[.size] as? Int64) ?? -1
            let dstSize = (try? fileManager.attributesOfItem(atPath: directCandidate.path)[.size] as? Int64) ?? -2
            if srcSize >= 0, srcSize == dstSize {
                return directCandidate
            }
        }

        let ext = sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent

        var candidate = dir.appendingPathComponent(sourceURL.lastPathComponent)
        var i = 1
        while fileManager.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(baseName)-\(i)" : "\(baseName)-\(i).\(ext)"
            candidate = dir.appendingPathComponent(newName)
            i += 1
        }

        try fileManager.copyItem(at: sourceURL, to: candidate)
        return candidate
    }
}

struct ImportManagementView: View {
    @Query private var photos: [Photo]
    @Environment(\.modelContext) private var modelContext
    @Binding var filterFolder: String?
    @Binding var viewMode: ContentView.ViewMode
    @Binding var includeSubfolders: Bool

    struct FolderInfo: Identifiable {
        let id: String // Path
        let url: URL
        let count: Int
        let photos: [Photo]
    }

    var folders: [FolderInfo] {
        let grouped = Dictionary(grouping: photos) { photo in
            // Use the directory of the file as the grouping key
            URL(fileURLWithPath: photo.filePath).deletingLastPathComponent().path
        }
        return grouped.map { path, photos in
            FolderInfo(
                id: path,
                url: URL(fileURLWithPath: path),
                count: photos.count,
                photos: photos
            )
        }.sorted { $0.id < $1.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Import Management")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Toggle("包含子文件夹", isOn: $includeSubfolders)
                    .toggleStyle(.switch)
                    .accessibilityIdentifier("include_subfolders_toggle")
            }
            .padding()

            if folders.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    Text("No imported folders found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Import some photos to see them here.")
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                let nodes = FolderNode.buildTree(from: photos)
                FoldersTreeView(
                    nodes: nodes,
                    onSelect: { node in
                        filterFolder = node.fullPath
                        viewMode = .grid
                    },
                    onRevealInFinder: { node in
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: node.fullPath)
                    },
                    onDeleteRecursively: { node in
                        deleteNode(node)
                    }
                )
            }
        }
        .background(Color(NSColor(hex: "#1a1a1a")))
    }

    private func deleteFolder(_ folder: FolderInfo) {
        // Confirm deletion? Usually good, but for MVP we just delete.
        // User can undo if we implemented undo, but we haven't.
        // Since it's "Remove from Library", it's non-destructive to files.
        for photo in folder.photos {
            modelContext.delete(photo)
        }
    }

    private func deleteNode(_ node: FolderNode) {
        for p in node.photos { modelContext.delete(p) }
        for child in node.children ?? [] { deleteNode(child) }
    }
}

struct DropZoneView: View {
    @Binding var isDragging: Bool
    var onDrop: ([NSItemProvider]) -> Bool
    var onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(isDragging ? .accentColor : .secondary)

            Text("Drag photos or folders here")
                .font(.headline)

            Text("or")
                .foregroundColor(.secondary)

            Button("Browse Files...") {
                onBrowse()
            }
            .buttonStyle(.bordered)

            Text("Supports: JPEG, PNG, HEIC, TIFF, RAW")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragging ? Color.accentColor : Color.gray.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            onDrop(providers)
        }
    }
}
