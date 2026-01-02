import Foundation
import AppKit

actor ThumbnailService {
    static let shared = ThumbnailService()

    private var cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 1000
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        return cache
    }()

    func getThumbnail(for photo: Photo, size: CGFloat) async -> NSImage? {
        let cacheKey = "\(photo.filePath)_\(Int(size))" as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let url = photo.fileURL
        let needsAccess = photo.bookmarkData != nil
        var didStart = false
        if needsAccess {
            didStart = url.startAccessingSecurityScopedResource()
        }

        let thumbnail = await generateThumbnail(for: url, size: size)

        if didStart {
            url.stopAccessingSecurityScopedResource()
        }

        guard let result = thumbnail else {
            return nil
        }

        cache.setObject(result, forKey: cacheKey)
        return result
    }

    func getDisplayImage(for photo: Photo, maxPixelSize: CGFloat = 4096) async -> NSImage? {
        let url = photo.fileURL
        let needsAccess = photo.bookmarkData != nil
        var didStart = false
        if needsAccess {
            didStart = url.startAccessingSecurityScopedResource()
        }

        let image = await generateLargeImage(for: url, maxPixelSize: maxPixelSize)

        if didStart {
            url.stopAccessingSecurityScopedResource()
        }

        return image
    }

    private func generateThumbnail(for url: URL, size: CGFloat) async -> NSImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: size * 2
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
    }

    private func generateLargeImage(for url: URL, maxPixelSize: CGFloat) async -> NSImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
