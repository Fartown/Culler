import Foundation
import SwiftData

@Model
final class Album {
    var id: UUID
    var name: String
    var dateCreated: Date
    var isSmartAlbum: Bool
    var smartRule: String?

    @Relationship var photos: [Photo]?
    @Relationship(inverse: \Album.children) var parent: Album?
    @Relationship var children: [Album]?

    init(name: String, isSmartAlbum: Bool = false) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.isSmartAlbum = isSmartAlbum
        self.photos = []
        self.children = []
    }
}
