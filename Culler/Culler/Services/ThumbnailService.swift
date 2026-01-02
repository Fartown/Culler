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

    func getThumbnail(for photo: Photo, size: CGFloat) async -> Result<NSImage, ImageLoadError> {
        let cacheKey = "\(photo.filePath)_\(Int(size))" as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return .success(cached)
        }

        let url = photo.fileURL
        
        let needsAccess = photo.bookmarkData != nil
        var didStart = false
        if needsAccess {
            didStart = url.startAccessingSecurityScopedResource()
            if !didStart {
                return .failure(.permissionDenied)
            }
        }

        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if !FileManager.default.fileExists(atPath: url.path) {
            return .failure(.fileNotFound)
        }

        let result = await generateThumbnail(for: url, size: size)

        if case .success(let image) = result {
            cache.setObject(image, forKey: cacheKey)
        }
        return result
    }

    func getDisplayImage(for photo: Photo, maxPixelSize: CGFloat = 4096) async -> Result<NSImage, ImageLoadError> {
        let url = photo.fileURL

        let needsAccess = photo.bookmarkData != nil
        var didStart = false
        if needsAccess {
            didStart = url.startAccessingSecurityScopedResource()
            if !didStart {
                return .failure(.permissionDenied)
            }
        }

        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if !FileManager.default.fileExists(atPath: url.path) {
            return .failure(.fileNotFound)
        }

        return await generateLargeImage(for: url, maxPixelSize: maxPixelSize)
    }

    private func generateThumbnail(for url: URL, size: CGFloat) async -> Result<NSImage, ImageLoadError> {
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

    func clearCache() {
        cache.removeAllObjects()
    }
}
