import Foundation
import SwiftData

@Model
final class ImportedFolder {
    var id: UUID
    var folderPath: String
    var bookmarkData: Data?
    var dateImported: Date

    init(folderPath: String, bookmarkData: Data? = nil) {
        self.id = UUID()
        self.folderPath = folderPath
        self.bookmarkData = bookmarkData
        self.dateImported = Date()
    }
}

