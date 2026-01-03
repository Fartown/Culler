import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case dateTaken
    case dateImported
    case fileName
    case rating

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dateTaken: return "拍摄时间"
        case .dateImported: return "导入时间"
        case .fileName: return "文件名"
        case .rating: return "评分"
        }
    }
}

extension Array where Element == Photo {
    func sorted(by option: SortOption) -> [Photo] {
        switch option {
        case .dateTaken:
            return sorted {
                let lhsDate = $0.dateTaken ?? $0.dateImported
                let rhsDate = $1.dateTaken ?? $1.dateImported
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                return $0.id.uuidString < $1.id.uuidString
            }
        case .dateImported:
            return sorted {
                if $0.dateImported != $1.dateImported { return $0.dateImported > $1.dateImported }
                return $0.id.uuidString < $1.id.uuidString
            }
        case .fileName:
            return sorted {
                let cmp = $0.fileName.localizedStandardCompare($1.fileName)
                if cmp != .orderedSame { return cmp == .orderedAscending }
                return $0.id.uuidString < $1.id.uuidString
            }
        case .rating:
            return sorted {
                if $0.rating != $1.rating { return $0.rating > $1.rating }
                let lhsDate = $0.dateTaken ?? $0.dateImported
                let rhsDate = $1.dateTaken ?? $1.dateImported
                if lhsDate != rhsDate { return lhsDate > rhsDate }
                return $0.id.uuidString < $1.id.uuidString
            }
        }
    }
}
