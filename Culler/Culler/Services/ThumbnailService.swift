import Foundation
import AppKit
import AVFoundation
import UniformTypeIdentifiers

actor ThumbnailService {
    static let shared = ThumbnailService()

    private var cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 1000
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        return cache
    }()

    private var displayCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 500
        cache.totalCostLimit = 256 * 1024 * 1024 // 256MB
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
        let cacheKey = "\(photo.filePath)_\(Int(maxPixelSize))" as NSString

        if let cached = displayCache.object(forKey: cacheKey) {
            print("Display cache hit: \(photo.fileName) size \(Int(maxPixelSize)))")
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

        let t0 = CFAbsoluteTimeGetCurrent()
        let result = await generateLargeImage(for: url, maxPixelSize: maxPixelSize)
        let dt = Int((CFAbsoluteTimeGetCurrent() - t0) * 1000)
        print("Display decode: \(photo.fileName) size \(Int(maxPixelSize))) took \(dt)ms")
        if case .success(let image) = result {
            displayCache.setObject(image, forKey: cacheKey)
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
}
