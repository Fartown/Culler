import Foundation
import SwiftData
import AppKit

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
        case .none: return "None"
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .purple: return "Purple"
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

        loadFileInfo()
        loadEXIF()
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
                } else {
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
