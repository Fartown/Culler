import Foundation
import SwiftData
import AppKit

enum UITestConfig {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }
}

enum UITestNotifications {
    static let openAlbumManager = Notification.Name("openAlbumManager")
    static let resetDemoData = Notification.Name("resetDemoData")
}

enum UITestDataSeeder {
    static func seedIfNeeded(into modelContext: ModelContext) {
        guard UITestConfig.isEnabled else { return }

        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<Photo>())) ?? 0
        if existingCount > 0 { return }

        let urls = createDemoImages()
        let photos: [Photo] = urls.map { Photo(filePath: $0.path) }

        for (index, photo) in photos.enumerated() {
            photo.rating = (index % 6)
            if index % 3 == 1 { photo.flag = .pick }
            if index % 3 == 2 { photo.flag = .reject }

            let colors: [ColorLabel] = [.none, .red, .yellow, .green, .blue, .purple]
            photo.colorLabel = colors[index % colors.count]

            modelContext.insert(photo)
        }

        let albumA = Album(name: "Demo Album")
        albumA.photos = Array(photos.prefix(4))
        modelContext.insert(albumA)

        let smart = Album(name: "⭐️ 3+ Stars", isSmartAlbum: true)
        smart.photos = photos.filter { $0.rating >= 3 }
        modelContext.insert(smart)

        let tagA = Tag(name: "Portrait", colorHex: "#FF2D55")
        tagA.photos = Array(photos.prefix(3))
        modelContext.insert(tagA)

        let tagB = Tag(name: "Travel", colorHex: "#34C759")
        tagB.photos = Array(photos.suffix(3))
        modelContext.insert(tagB)
    }

    static func reset(into modelContext: ModelContext) {
        let photos = (try? modelContext.fetch(FetchDescriptor<Photo>())) ?? []
        let albums = (try? modelContext.fetch(FetchDescriptor<Album>())) ?? []
        let tags = (try? modelContext.fetch(FetchDescriptor<Tag>())) ?? []

        for photo in photos { modelContext.delete(photo) }
        for album in albums { modelContext.delete(album) }
        for tag in tags { modelContext.delete(tag) }

        seedIfNeeded(into: modelContext)
    }

    private static func createDemoImages() -> [URL] {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("CullerUITestImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)

        let specs: [(String, NSColor)] = [
            ("E2E-01", .systemBlue),
            ("E2E-02", .systemGreen),
            ("E2E-03", .systemYellow),
            ("E2E-04", .systemOrange),
            ("E2E-05", .systemRed),
            ("E2E-06", .systemPurple),
            ("E2E-07", .systemTeal),
            ("E2E-08", .systemPink)
        ]

        var results: [URL] = []
        for (name, color) in specs {
            let url = base.appendingPathComponent("\(name).png")
            if !FileManager.default.fileExists(atPath: url.path) {
                if let image = makeDemoImage(title: name, color: color, size: 720) {
                    try? writePNG(image: image, to: url)
                }
            }
            results.append(url)
        }
        return results
    }

    private static func makeDemoImage(title: String, color: NSColor, size: Int) -> NSImage? {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        color.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = NSSize(width: 0, height: -2)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.09, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph,
            .shadow: shadow
        ]

        let text = NSString(string: title)
        let rect = NSRect(x: 0, y: (CGFloat(size) * 0.45), width: CGFloat(size), height: CGFloat(size) * 0.2)
        text.draw(in: rect, withAttributes: attrs)
        return image
    }

    private static func writePNG(image: NSImage, to url: URL) throws {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: [.atomic])
    }
}

