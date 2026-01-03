import Foundation
import SwiftData
import UniformTypeIdentifiers

struct FolderSyncSummary: Sendable {
    let folderPath: String
    let addedCount: Int
    let removedCount: Int
    let folderMissing: Bool
    let errors: [ImportErrorItem]
}

enum FolderSyncError: LocalizedError {
    case permissionDenied
    case notDirectory

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "没有权限访问该文件夹（可能需要重新授权）。"
        case .notDirectory:
            return "选择的路径不是文件夹。"
        }
    }
}

@MainActor
enum FolderSyncService {
    static func sync(
        folderPath: String,
        photos: [Photo],
        importedFolders: [ImportedFolder],
        modelContext: ModelContext,
        progress: ((Double) -> Void)? = nil
    ) async throws -> FolderSyncSummary {
        let folderStandardPath = URL(fileURLWithPath: folderPath).standardizedFileURL.path
        let folderURL = URL(fileURLWithPath: folderStandardPath)

        let photosInFolder = photos.filter { isPhoto($0, underFolderPath: folderStandardPath) }
        let existingPaths: Set<String> = Set(photosInFolder.map { URL(fileURLWithPath: $0.filePath).standardizedFileURL.path })
        let existingPhotosByPath: [String: Photo] = {
            var map: [String: Photo] = [:]
            for photo in photosInFolder {
                map[URL(fileURLWithPath: photo.filePath).standardizedFileURL.path] = photo
            }
            return map
        }()

        let needsBookmarks = photosInFolder.contains { $0.bookmarkData != nil }

        var didStartAccess = false
        var accessURL: URL?
        if let candidate = bestBookmarkFolder(for: folderStandardPath, from: importedFolders), let data = candidate.bookmarkData {
            var stale = false
            if let resolvedURL = try? URL(resolvingBookmarkData: data, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
                accessURL = resolvedURL
                didStartAccess = resolvedURL.startAccessingSecurityScopedResource()
                if stale, didStartAccess, let newData = try? resolvedURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    candidate.bookmarkData = newData
                }
            }
        }
        defer {
            if didStartAccess, let accessURL {
                accessURL.stopAccessingSecurityScopedResource()
            }
        }

        progress?(0)

        let scanResult = await Task.detached(priority: .userInitiated) {
            scanFolder(folderURL: folderURL)
        }.value

        if scanResult.permissionDenied {
            throw FolderSyncError.permissionDenied
        }
        if scanResult.notDirectory {
            throw FolderSyncError.notDirectory
        }

        let diskPaths = scanResult.diskPaths
        let removedPaths = existingPaths.subtracting(diskPaths)
        let addedPaths = diskPaths.subtracting(existingPaths)

        if needsBookmarks {
            upsertImportedFolderBookmark(folderURL: folderURL, modelContext: modelContext)
        }

        var errors: [ImportErrorItem] = []
        var removedCount = 0
        var addedCount = 0

        let totalOps = max(removedPaths.count + addedPaths.count, 1)
        var completedOps = 0
        func reportProgress() {
            progress?(min(1, 0.1 + (Double(completedOps) / Double(totalOps)) * 0.9))
        }
        reportProgress()

        for path in removedPaths {
            if let photo = existingPhotosByPath[path] {
                modelContext.delete(photo)
                removedCount += 1
            }
            completedOps += 1
            reportProgress()
        }

        let sortedAdded = addedPaths.sorted { $0.lowercased() < $1.lowercased() }
        for path in sortedAdded {
            let url = URL(fileURLWithPath: path)
            var bookmark: Data? = nil
            if needsBookmarks {
                do {
                    bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                } catch {
                    errors.append(ImportErrorItem(filename: url.lastPathComponent, reason: "无法创建文件权限（Bookmark）"))
                    completedOps += 1
                    reportProgress()
                    continue
                }
            }

            let photo = Photo(filePath: url.path, bookmarkData: bookmark)
            modelContext.insert(photo)
            addedCount += 1

            completedOps += 1
            reportProgress()
        }

        if scanResult.folderMissing {
            deleteImportedFolders(underFolderPath: folderStandardPath, modelContext: modelContext)
        }

        progress?(1)
        return FolderSyncSummary(
            folderPath: folderStandardPath,
            addedCount: addedCount,
            removedCount: removedCount,
            folderMissing: scanResult.folderMissing,
            errors: errors
        )
    }

    private static func isPhoto(_ photo: Photo, underFolderPath folderPath: String) -> Bool {
        let folderStandard = URL(fileURLWithPath: folderPath).standardizedFileURL.path
        let prefix = folderStandard.hasSuffix("/") ? folderStandard : folderStandard + "/"
        let photoPath = URL(fileURLWithPath: photo.filePath).standardizedFileURL.path
        return photoPath.hasPrefix(prefix)
    }

    private static func bestBookmarkFolder(for folderPath: String, from importedFolders: [ImportedFolder]) -> ImportedFolder? {
        let folderStandard = URL(fileURLWithPath: folderPath).standardizedFileURL.path
        return importedFolders
            .filter { imported in
                let importedPath = URL(fileURLWithPath: imported.folderPath).standardizedFileURL.path
                if folderStandard == importedPath { return true }
                let prefix = importedPath.hasSuffix("/") ? importedPath : importedPath + "/"
                return folderStandard.hasPrefix(prefix)
            }
            .max(by: { $0.folderPath.count < $1.folderPath.count })
    }

    private struct FolderScanResult: Sendable {
        let folderMissing: Bool
        let notDirectory: Bool
        let permissionDenied: Bool
        let diskPaths: Set<String>
    }

    private nonisolated static func scanFolder(folderURL: URL) -> FolderScanResult {
        let fm = FileManager.default

        do {
            let attrs = try fm.attributesOfItem(atPath: folderURL.path)
            let type = attrs[.type] as? FileAttributeType
            if type != .typeDirectory {
                return FolderScanResult(folderMissing: false, notDirectory: true, permissionDenied: false, diskPaths: [])
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == CocoaError.Code.fileNoSuchFile.rawValue {
                return FolderScanResult(folderMissing: true, notDirectory: false, permissionDenied: false, diskPaths: [])
            }
            if nsError.domain == NSCocoaErrorDomain, nsError.code == CocoaError.Code.fileReadNoPermission.rawValue {
                return FolderScanResult(folderMissing: false, notDirectory: false, permissionDenied: true, diskPaths: [])
            }
            return FolderScanResult(folderMissing: false, notDirectory: false, permissionDenied: true, diskPaths: [])
        }

        guard let enumerator = fm.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return FolderScanResult(folderMissing: false, notDirectory: false, permissionDenied: true, diskPaths: [])
        }

        var diskPaths = Set<String>()
        while let fileURL = enumerator.nextObject() as? URL {
            if isSupportedMediaFile(fileURL) {
                diskPaths.insert(fileURL.standardizedFileURL.path)
            }
        }

        return FolderScanResult(folderMissing: false, notDirectory: false, permissionDenied: false, diskPaths: diskPaths)
    }

    private nonisolated static func isSupportedMediaFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ext.isEmpty { return false }

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

    private static func upsertImportedFolderBookmark(folderURL: URL, modelContext: ModelContext) {
        do {
            let data = try folderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            let folderPath = folderURL.standardizedFileURL.path
            let descriptor = FetchDescriptor<ImportedFolder>(predicate: #Predicate { $0.folderPath == folderPath })
            if let existing = try modelContext.fetch(descriptor).first {
                existing.bookmarkData = data
            } else {
                modelContext.insert(ImportedFolder(folderPath: folderPath, bookmarkData: data))
            }
        } catch {
            // 忽略：没有权限时同步会直接报错；这里尽量不影响主流程
        }
    }

    private static func deleteImportedFolders(underFolderPath folderPath: String, modelContext: ModelContext) {
        let folderStandard = URL(fileURLWithPath: folderPath).standardizedFileURL.path
        let prefix = folderStandard.hasSuffix("/") ? folderStandard : folderStandard + "/"

        let descriptor = FetchDescriptor<ImportedFolder>()
        if let all = try? modelContext.fetch(descriptor) {
            for item in all {
                let itemPath = URL(fileURLWithPath: item.folderPath).standardizedFileURL.path
                if itemPath == folderStandard || itemPath.hasPrefix(prefix) {
                    modelContext.delete(item)
                }
            }
        }
    }
}
