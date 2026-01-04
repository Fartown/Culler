import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

enum Flag: Int, Codable, CaseIterable {
    case none = 0
    case pick = 1
    case reject = 2
}

enum ColorLabel: Int, Codable, CaseIterable {
    case none = 0
    case red = 1
    case yellow = 2
    case green = 3
    case blue = 4
    case purple = 5

    var color: NSColor {
        switch self {
        case .none: return .clear
        case .red: return .systemRed
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .blue: return .systemBlue
        case .purple: return .systemPurple
        }
    }

    var name: String {
        switch self {
        case .none: return "无"
        case .red: return "红"
        case .yellow: return "黄"
        case .green: return "绿"
        case .blue: return "蓝"
        case .purple: return "紫"
        }
    }
}

@Model
final class Photo {
    var id: UUID
    var filePath: String
    var bookmarkData: Data?
    var fileName: String
    var fileSize: Int64
    var dateCreated: Date
    var dateImported: Date
    var rating: Int
    var flagValue: Int
    var colorLabelValue: Int

    // EXIF metadata
    var cameraMake: String?
    var cameraModel: String?
    var lens: String?
    var focalLength: Double?
    var aperture: Double?
    var shutterSpeed: String?
    var iso: Int?
    var dateTaken: Date?
    var width: Int?
    var height: Int?

    @Relationship(inverse: \Album.photos) var albums: [Album]?
    @Relationship(inverse: \Tag.photos) var tags: [Tag]?

    var flag: Flag {
        get { Flag(rawValue: flagValue) ?? .none }
        set { flagValue = newValue.rawValue }
    }

    var colorLabel: ColorLabel {
        get { ColorLabel(rawValue: colorLabelValue) ?? .none }
        set { colorLabelValue = newValue.rawValue }
    }

    var fileURL: URL {
        if let data = bookmarkData {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: data, options: [.withoutUI, .withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
                if stale {
                    if url.startAccessingSecurityScopedResource() {
                        if let newData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                            bookmarkData = newData
                        }
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                return url
            }
        }
        return URL(fileURLWithPath: filePath)
    }

    init(filePath: String, bookmarkData: Data? = nil) {
        self.id = UUID()
        self.filePath = filePath
        self.bookmarkData = bookmarkData
        self.fileName = URL(fileURLWithPath: filePath).lastPathComponent
        self.fileSize = 0
        self.dateCreated = Date()
        self.dateImported = Date()
        self.rating = 0
        self.flagValue = Flag.none.rawValue
        self.colorLabelValue = ColorLabel.none.rawValue
        self.albums = []
        self.tags = []

        Task.detached { [fileURL = self.fileURL] in
            var parsedSize: Int64 = 0
            var parsedCreated: Date = Date()

            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
                parsedSize = attrs[.size] as? Int64 ?? 0
                parsedCreated = attrs[.creationDate] as? Date ?? Date()
            }

            var exifCameraMake: String?
            var exifCameraModel: String?
            var exifLens: String?
            var exifFocalLength: Double?
            var exifAperture: Double?
            var exifShutterSpeed: String?
            var exifISO: Int?
            var exifDateTaken: Date?
            var pixelWidth: Int?
            var pixelHeight: Int?

            if let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {

                if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
                    if let focalLength = exif[kCGImagePropertyExifFocalLength] as? Double { exifFocalLength = focalLength }
                    if let aperture = exif[kCGImagePropertyExifFNumber] as? Double { exifAperture = aperture }
                    if let iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first { exifISO = iso }
                    if let exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double {
                        if exposureTime >= 1 { exifShutterSpeed = "\(Int(exposureTime))s" }
                        else if exposureTime > 0 { exifShutterSpeed = "1/\(Int(1/exposureTime))" }
                    }
                    if let dateStr = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                        exifDateTaken = formatter.date(from: dateStr)
                    }
                }

                if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
                    exifCameraMake = tiff[kCGImagePropertyTIFFMake] as? String
                    exifCameraModel = tiff[kCGImagePropertyTIFFModel] as? String
                }

                pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int
                pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int
            }

            await MainActor.run {
                self.fileSize = parsedSize
                self.dateCreated = parsedCreated
                self.cameraMake = exifCameraMake
                self.cameraModel = exifCameraModel
                self.lens = exifLens
                self.focalLength = exifFocalLength
                self.aperture = exifAperture
                self.shutterSpeed = exifShutterSpeed
                self.iso = exifISO
                self.dateTaken = exifDateTaken
                self.width = pixelWidth
                self.height = pixelHeight
            }
        }
    }

    private func loadFileInfo() {
        let url = fileURL
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) {
            fileSize = attrs[.size] as? Int64 ?? 0
            dateCreated = attrs[.creationDate] as? Date ?? Date()
        }
    }

    private func loadEXIF() {
        let url = fileURL
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return
        }

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            if let focalLength = exif[kCGImagePropertyExifFocalLength] as? Double {
                self.focalLength = focalLength
            }
            if let aperture = exif[kCGImagePropertyExifFNumber] as? Double {
                self.aperture = aperture
            }
            if let iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first {
                self.iso = iso
            }
            if let exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double {
                if exposureTime >= 1 {
                    self.shutterSpeed = "\(Int(exposureTime))s"
                } else if exposureTime > 0 {
                    self.shutterSpeed = "1/\(Int(1/exposureTime))"
                }
            }
            if let dateStr = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                self.dateTaken = formatter.date(from: dateStr)
            }
        }

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            self.cameraMake = tiff[kCGImagePropertyTIFFMake] as? String
            self.cameraModel = tiff[kCGImagePropertyTIFFModel] as? String
        }

        self.width = properties[kCGImagePropertyPixelWidth] as? Int
        self.height = properties[kCGImagePropertyPixelHeight] as? Int
    }
}

extension Photo {
    private static let videoFileExtensions: Set<String> = [
        "mov", "mp4", "m4v", "avi", "mkv", "webm", "wmv", "flv", "f4v",
        "mpg", "mpeg", "m2v", "ts", "mts", "m2ts",
        "3gp", "3g2", "asf", "ogv", "mxf", "vob", "dv"
    ]

    var isVideo: Bool {
        // 使用 NSString 获取扩展名比创建 URL 快得多
        let ext = (filePath as NSString).pathExtension.lowercased()
        guard !ext.isEmpty else { return false }
        
        // 优先检查常见视频后缀 (O(1))
        if Self.videoFileExtensions.contains(ext) {
            return true
        }
        
        // 仅在未知后缀时回退到系统 UTType 查询 (较慢)
        if let type = UTType(filenameExtension: ext) {
            return type.conforms(to: .movie) || (type.conforms(to: .audiovisualContent) && !type.conforms(to: .audio))
        }
        return false
    }
}
