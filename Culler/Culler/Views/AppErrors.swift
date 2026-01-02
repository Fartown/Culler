import Foundation

enum ImageLoadError: Error, LocalizedError {
    case fileNotFound
    case permissionDenied
    case corruptedData
    case unsupportedFormat
    case unknown

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "File not found"
        case .permissionDenied: return "Access denied"
        case .corruptedData: return "File corrupted"
        case .unsupportedFormat: return "Unsupported format"
        case .unknown: return "Unknown error"
        }
    }
}

struct ImportErrorItem: Identifiable {
    let id = UUID()
    let filename: String
    let reason: String
}

enum ImportProcessError: Error, LocalizedError {
    case sourceAccessDenied
    case destinationWriteFailed
    case bookmarkCreationFailure
    case duplicateFile
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .sourceAccessDenied: return "Cannot read source file"
        case .destinationWriteFailed: return "Cannot write to library (Disk full?)"
        case .bookmarkCreationFailure: return "Failed to create security bookmark"
        case .duplicateFile: return "Duplicate file name"
        case .unknown(let error): return error.localizedDescription
        }
    }
}
