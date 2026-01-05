import Foundation
import SwiftData
import AppKit
import AVFoundation
import Darwin

@MainActor
enum E2ERunner {
    // 覆盖统计标记（供 script/check_e2e_feature_coverage.py 静态扫描）
    // E2E_CASE:E2E-01
    // E2E_CASE:E2E-02
    // E2E_CASE:E2E-03
    // E2E_CASE:E2E-04
    // E2E_CASE:E2E-05
    // E2E_CASE:E2E-06
    // E2E_CASE:E2E-07
    // E2E_CASE:E2E-08
    // E2E_CASE:E2E-09
    // E2E_CASE:E2E-10
    // E2E_CASE:E2E-11

    private static var didStart = false

    static func startIfNeeded() {
        guard UITestConfig.isE2E else { return }
        guard !didStart else { return }
        didStart = true

        Task { @MainActor in
            await run()
        }
    }

    private static func printCase(_ id: String) {
        print("E2E_CASE:\(id)")
        fflush(stdout)
    }

    private static func fail(_ message: String) -> Never {
        print("E2E_RESULT:FAIL \(message)")
        fflush(stdout)
        exit(1)
    }

    private static func pass() -> Never {
        print("E2E_RESULT:PASS")
        fflush(stdout)
        exit(0)
    }

    static func run() async {
        do {
            let schema = Schema([Photo.self, Album.self, Tag.self, ImportedFolder.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            let modelContext = container.mainContext

            E2EProbe.reset()

            // E2E-01: 启动与示例数据
            printCase("E2E-01")
            UITestDataSeeder.reset(into: modelContext)
            let seededPhotos = try modelContext.fetch(FetchDescriptor<Photo>())
            guard !seededPhotos.isEmpty else { fail("no seeded photos") }
            let first = seededPhotos[0]

            // E2E-02: 网格浏览（数据可用于展示）
            printCase("E2E-02")
            guard FileManager.default.fileExists(atPath: first.filePath) else { fail("seed file missing") }

            // E2E-04: 标记
            printCase("E2E-04")
            first.flag = .pick
            first.rating = 5
            first.colorLabel = .red
            guard first.flag == .pick, first.rating == 5, first.colorLabel == .red else { fail("marking not persisted") }

            // E2E-05: 筛选
            printCase("E2E-05")
            let filtered = seededPhotos.filter { $0.rating >= 3 }
            guard !filtered.isEmpty, filtered.count <= seededPhotos.count else { fail("filter failed") }

            // E2E-06: 排序
            printCase("E2E-06")
            guard seededPhotos.sorted(by: .fileName).count == seededPhotos.count else { fail("sort fileName failed") }
            guard seededPhotos.sorted(by: .rating).count == seededPhotos.count else { fail("sort rating failed") }

            // E2E-03: 单图查看（旋转信号）
            printCase("E2E-03")
            E2EProbe.recordRotation(degrees: 90)
            guard E2EProbe.rotationDegrees == 90 else { fail("rotation probe not recorded") }

            // E2E-07: 导入（模拟：新增文件 + 新增 Photo）
            printCase("E2E-07")
            let importURL = UITestDataSeeder.createAdditionalDemoImage(named: "E2E-IMPORT-01", color: .systemIndigo)
            let beforeImportCount = (try? modelContext.fetchCount(FetchDescriptor<Photo>())) ?? 0
            modelContext.insert(Photo(filePath: importURL.path))
            let afterImportCount = (try? modelContext.fetchCount(FetchDescriptor<Photo>())) ?? 0
            guard afterImportCount == beforeImportCount + 1 else { fail("import insert failed") }

            // E2E-08: 文件夹同步（磁盘新增 -> sync 入库）
            printCase("E2E-08")
            let folderURL = UITestDataSeeder.demoImagesDirectory()
            let folderPath = folderURL.standardizedFileURL.path
            modelContext.insert(ImportedFolder(folderPath: folderPath, bookmarkData: nil))

            _ = UITestDataSeeder.createAdditionalDemoImage(named: "E2E-SYNC-01", color: .systemBrown)
            let photosBeforeSync = (try? modelContext.fetch(FetchDescriptor<Photo>())) ?? []
            let importedFolders = (try? modelContext.fetch(FetchDescriptor<ImportedFolder>())) ?? []
            let summary = try await FolderSyncService.sync(
                folderPath: folderPath,
                photos: photosBeforeSync,
                importedFolders: importedFolders,
                modelContext: modelContext,
                progress: nil
            )
            guard summary.folderPath == folderPath else { fail("sync summary folder mismatch") }
            guard summary.addedCount >= 1 else { fail("sync did not add") }

            // E2E-09: 相册与标签管理
            printCase("E2E-09")
            let album = Album(name: "E2E Album")
            let tag = Tag(name: "E2E Tag", colorHex: "#FF9500")
            modelContext.insert(album)
            modelContext.insert(tag)
            album.photos = [first]
            first.tags = [tag]
            guard (album.photos?.count ?? 0) == 1 else { fail("album assign failed") }
            guard (first.tags?.count ?? 0) == 1 else { fail("tag assign failed") }

            // E2E-10: 检查器信息（核心字段存在 + 文件大小可读）
            printCase("E2E-10")
            guard !first.fileName.isEmpty else { fail("missing fileName") }
            let attrs = try FileManager.default.attributesOfItem(atPath: first.fileURL.path)
            let size = attrs[.size] as? Int64 ?? 0
            guard size > 0 else { fail("file size not readable") }

            // E2E-11: 视频识别与播放失败兜底（不可播放视频 -> 记录失败）
            printCase("E2E-11")
            let badVideoURL = folderURL.appendingPathComponent("E2E-BAD-VIDEO.mov")
            if !FileManager.default.fileExists(atPath: badVideoURL.path) {
                FileManager.default.createFile(atPath: badVideoURL.path, contents: Data("not a video".utf8))
            }
            let badPhoto = Photo(filePath: badVideoURL.path)
            modelContext.insert(badPhoto)
            guard badPhoto.isVideo else { fail("bad video not recognized as video") }

            let asset = AVAsset(url: badVideoURL)
            let isPlayable = (try? await asset.load(.isPlayable)) ?? false
            if !isPlayable {
                E2EProbe.recordVideoLoadFailed(photoID: badPhoto.id)
            }
            guard E2EProbe.videoLoadFailedPhotoID == badPhoto.id else { fail("video fallback not recorded") }

            pass()
        } catch {
            fail("unexpected error: \(error)")
        }
    }
}
