import Foundation
import AppKit
import AVFoundation
import UniformTypeIdentifiers

final class ThumbnailService: Sendable {
    static let shared = ThumbnailService()

    private let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 1000
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        return cache
    }()

    private let displayCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 500
        cache.totalCostLimit = 256 * 1024 * 1024 // 256MB
        return cache
    }()

    private var thumbHits: Int = 0
    private var thumbMisses: Int = 0
    private var displayHits: Int = 0
    private var displayMisses: Int = 0

    private let queue = ImageTaskQueue(maxConcurrent: 4)

    /// 同步获取缓存中的缩略图（用于快速滚动）
    func cachedThumbnail(for photo: Photo, size: CGFloat) -> NSImage? {
        let cacheKey = "\(photo.filePath)_\(Int(size))" as NSString
        return cache.object(forKey: cacheKey)
    }

    func getThumbnail(for photo: Photo, size: CGFloat) async -> Result<NSImage, ImageLoadError> {
        let cacheKey = "\(photo.filePath)_\(Int(size))"
        let cacheKeyObj = cacheKey as NSString

        if let cached = cache.object(forKey: cacheKeyObj) {
            thumbHits += 1
            return .success(cached)
        }

        let result = await queue.enqueue(key: cacheKey) { [weak self] in
            guard let self = self else { return .failure(.unknown) }
            if Task.isCancelled { return .failure(.unknown) }

            let url = photo.fileURL
            let needsAccess = photo.bookmarkData != nil
            var didStart = false
            if needsAccess {
                didStart = url.startAccessingSecurityScopedResource()
                if !didStart { return .failure(.permissionDenied) }
            }
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            if !FileManager.default.fileExists(atPath: url.path) { return .failure(.fileNotFound) }
            if Task.isCancelled { return .failure(.unknown) }

            let start = CFAbsoluteTimeGetCurrent()
            let gen = await self.generateThumbnail(for: url, size: size)
            if case .success(let image) = gen {
                self.cache.setObject(image, forKey: cacheKeyObj)
                self.thumbMisses += 1
            }
            _ = CFAbsoluteTimeGetCurrent() - start
            return gen
        }
        return result
    }

    func getDisplayImage(for photo: Photo, maxPixelSize: CGFloat = 4096) async -> Result<NSImage, ImageLoadError> {
        let cacheKey = "\(photo.filePath)_\(Int(maxPixelSize))"
        let cacheKeyObj = cacheKey as NSString

        if let cached = displayCache.object(forKey: cacheKeyObj) {
            displayHits += 1
            return .success(cached)
        }

        let result = await queue.enqueue(key: cacheKey) { [weak self] in
            guard let self = self else { return .failure(.unknown) }
            if Task.isCancelled { return .failure(.unknown) }

            let url = photo.fileURL
            let needsAccess = photo.bookmarkData != nil
            var didStart = false
            if needsAccess {
                didStart = url.startAccessingSecurityScopedResource()
                if !didStart { return .failure(.permissionDenied) }
            }
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            if !FileManager.default.fileExists(atPath: url.path) { return .failure(.fileNotFound) }
            if Task.isCancelled { return .failure(.unknown) }

            let start = CFAbsoluteTimeGetCurrent()
            let gen = await self.generateLargeImage(for: url, maxPixelSize: maxPixelSize)
            if case .success(let image) = gen {
                self.displayCache.setObject(image, forKey: cacheKeyObj)
                self.displayMisses += 1
            }
            _ = CFAbsoluteTimeGetCurrent() - start
            return gen
        }
        return result
    }

    private func generateThumbnail(for url: URL, size: CGFloat) async -> Result<NSImage, ImageLoadError> {
        if isVideoURL(url) {
            return await generateVideoThumbnail(for: url, maxPixelSize: size * 2)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: size * 2
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return .failure(.corruptedData)
        }
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return .failure(.corruptedData)
        }

        return .success(NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))))
    }

    private func generateLargeImage(for url: URL, maxPixelSize: CGFloat) async -> Result<NSImage, ImageLoadError> {
        if isVideoURL(url) {
            return await generateVideoThumbnail(for: url, maxPixelSize: maxPixelSize)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return .failure(.corruptedData)
        }
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return .failure(.corruptedData)
        }

        return .success(NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))))
    }

    private func isVideoURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if let type = UTType(filenameExtension: ext) {
            return type.conforms(to: .movie) || (type.conforms(to: .audiovisualContent) && !type.conforms(to: .audio))
        }
        return [
            "mov", "mp4", "m4v", "avi", "mkv", "webm", "wmv", "flv", "f4v",
            "mpg", "mpeg", "m2v", "ts", "mts", "m2ts",
            "3gp", "3g2", "asf", "ogv", "mxf", "vob", "dv"
        ].contains(ext)
    }

    private func generateVideoThumbnail(for url: URL, maxPixelSize: CGFloat) async -> Result<NSImage, ImageLoadError> {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixelSize, height: maxPixelSize)

        let time = CMTime(seconds: 0, preferredTimescale: 600)
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            return .success(NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))))
        } catch {
            return .failure(.unsupportedFormat)
        }
    }

    func clearCache() {
        cache.removeAllObjects()
        displayCache.removeAllObjects()
    }

    func metricsSummary() -> (thumbHits: Int, thumbMisses: Int, displayHits: Int, displayMisses: Int) {
        return (thumbHits, thumbMisses, displayHits, displayMisses)
    }
}

final actor ImageTaskQueue {
    private var inflight: [String: Task<Result<NSImage, ImageLoadError>, Never>] = [:]
    private var running: Int = 0
    private let maxConcurrent: Int

    init(maxConcurrent: Int) {
        self.maxConcurrent = maxConcurrent
    }

    func enqueue(key: String, operation: @escaping () async -> Result<NSImage, ImageLoadError>) async -> Result<NSImage, ImageLoadError> {
        if let existing = inflight[key] {
            return await existing.value
        }

        while running >= maxConcurrent {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        running += 1
        let task = Task<Result<NSImage, ImageLoadError>, Never> {
            let result = await operation()
            await self.finish(key: key)
            return result
        }
        inflight[key] = task
        return await task.value
    }

    private func finish(key: String) {
        running = max(0, running - 1)
        inflight.removeValue(forKey: key)
    }

    func cancel(key: String) {
        inflight[key]?.cancel()
        inflight.removeValue(forKey: key)
    }
}
