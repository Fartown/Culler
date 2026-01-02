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
    @State private var importedCount = 0
    @State private var totalCount = 0
    @State private var importErrors: [ImportErrorItem] = []
    @State private var showImportErrorSheet = false

    enum ImportMode: String, CaseIterable {
        case reference = "Reference"
        case copy = "Copy to Library"
    }

    let supportedTypes: [UTType] = [.jpeg, .png, .heic, .tiff, .rawImage]

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
                    Text("Importing \(importedCount) of \(totalCount)...")
                        .foregroundColor(.secondary)
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
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if isImageFile(fileURL) && !selectedFiles.contains(fileURL) {
                        selectedFiles.append(fileURL)
                    }
                }
            }
        } else if isImageFile(url) && !selectedFiles.contains(url) {
            selectedFiles.append(url)
        }
    }

    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "tiff", "tif", "raw", "cr2", "cr3", "nef", "arw", "dng", "orf", "rw2"]
        return imageExtensions.contains(url.pathExtension.lowercased())
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
        importedCount = 0
        importErrors = []

        Task {
            for url in selectedFiles {
                let finalURL: URL
                
                // 1. Handle Copy/Reference Logic
                if importMode == .copy {
                    do {
                        finalURL = try copyToLibrary(sourceURL: url)
                    } catch {
                        let reason = (error as NSError).localizedDescription
                        importErrors.append(ImportErrorItem(filename: url.lastPathComponent, reason: "Copy failed: \(reason)"))
                        continue
                    }
                } else {
                    finalURL = url
                }

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
                        importErrors.append(ImportErrorItem(filename: url.lastPathComponent, reason: "Permission error: Failed to create security bookmark"))
                        // We continue even if bookmark fails, but the image might not load later.
                        // Alternatively, we could fail the import here. Let's fail it to be safe.
                        continue
                    }
                }

                // 3. Create Model
                let photo = Photo(filePath: finalURL.path, bookmarkData: bookmark)
                await MainActor.run {
                    modelContext.insert(photo)
                    importedCount += 1
                    importProgress = Double(importedCount) / Double(totalCount)
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
                List {
                    ForEach(folders) { folder in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(folder.url.lastPathComponent)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(folder.id)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            Text("\(folder.count) photos")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)

                            Menu {
                                Button(action: {
                                    filterFolder = folder.id
                                    viewMode = .grid
                                }) {
                                    Label("View Photos", systemImage: "photo")
                                }

                                Button(action: {
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folder.id)
                                }) {
                                    Label("Show in Finder", systemImage: "folder")
                                }

                                Divider()

                                Button(role: .destructive, action: {
                                    deleteFolder(folder)
                                }) {
                                    Label("Remove from Library", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            .menuStyle(.borderlessButton)
                            .frame(width: 30)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.inset)
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
