import SwiftUI

struct ImportCommands: Commands {
    var body: some Commands {
        CommandMenu("Import") {
            Button("Import Photos...") {
                NotificationCenter.default.post(name: .importPhotos, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
    }
}

struct PhotoCommands: Commands {
    var body: some Commands {
        CommandMenu("Photo") {
            Button("Pick") {
                NotificationCenter.default.post(name: .setFlag, object: Flag.pick)
            }
            .keyboardShortcut("c", modifiers: [])

            Button("Reject") {
                NotificationCenter.default.post(name: .setFlag, object: Flag.reject)
            }
            .keyboardShortcut("x", modifiers: [])

            Button("Unflag") {
                NotificationCenter.default.post(name: .setFlag, object: Flag.none)
            }
            .keyboardShortcut("u", modifiers: [])

            Divider()

            ForEach(1...5, id: \.self) { rating in
                Button("Rate \(rating) Star\(rating > 1 ? "s" : "")") {
                    NotificationCenter.default.post(name: .setRating, object: rating)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(rating)")), modifiers: [])
            }

            Button("Clear Rating") {
                NotificationCenter.default.post(name: .setRating, object: 0)
            }
            .keyboardShortcut("0", modifiers: [])
        }
    }
}

struct FolderCommands: Commands {
    var body: some Commands {
        CommandMenu("Folders") {
            Button("Folder Browser") {
                NotificationCenter.default.post(name: .enterFolderBrowser, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }
    }
}

struct PanelCommands: Commands {
    var body: some Commands {
        CommandMenu("Panels") {
            Button("Toggle Left Panel") {
                NotificationCenter.default.post(name: .toggleLeftPanel, object: nil)
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])

            Button("Toggle Right Panel") {
                NotificationCenter.default.post(name: .toggleRightPanel, object: nil)
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])

            Divider()

            Button("相册与标签管理") {
                NotificationCenter.default.post(name: .openAlbumManager, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
        }
    }
}

struct ZoomCommands: Commands {
    var body: some Commands {
        CommandMenu("View") {
            Button("Zoom In") {
                NotificationCenter.default.post(name: .zoomIn, object: nil)
            }
            .keyboardShortcut("=", modifiers: [.command, .shift])

            Button("Zoom Out") {
                NotificationCenter.default.post(name: .zoomOut, object: nil)
            }
            .keyboardShortcut("-", modifiers: [.command])

            Button("Actual Size") {
                NotificationCenter.default.post(name: .zoomReset, object: nil)
            }
            .keyboardShortcut("0", modifiers: [.command])

            Button("Rotate Left") {
                NotificationCenter.default.post(name: .rotateLeft, object: nil)
            }
            .keyboardShortcut("[", modifiers: [.command])

            Button("Rotate Right") {
                NotificationCenter.default.post(name: .rotateRight, object: nil)
            }
            .keyboardShortcut("]", modifiers: [.command])
        }
    }
}
