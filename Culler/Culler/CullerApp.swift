import SwiftUI
import SwiftData

@main
struct CullerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Photo.self,
            Album.self,
            Tag.self,
            ImportedFolder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            ImportCommands()
            PhotoCommands()
            FolderCommands()
            PanelCommands()
            ZoomCommands()

        }

        Settings {
            SettingsView()
        }
    }
}

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

extension Notification.Name {
    static let importPhotos = Notification.Name("importPhotos")
    static let setFlag = Notification.Name("setFlag")
    static let setRating = Notification.Name("setRating")
    static let setColorLabel = Notification.Name("setColorLabel")
    static let navigateLeft = Notification.Name("navigateLeft")
    static let navigateRight = Notification.Name("navigateRight")
    static let navigateUp = Notification.Name("navigateUp")
    static let navigateDown = Notification.Name("navigateDown")
    static let selectAll = Notification.Name("selectAll")

    static let enterFolderBrowser = Notification.Name("enterFolderBrowser")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let zoomReset = Notification.Name("zoomReset")
    static let toggleLeftPanel = Notification.Name("toggleLeftPanel")
    static let toggleRightPanel = Notification.Name("toggleRightPanel")
    static let deletePhoto = Notification.Name("deletePhoto")
    static let rotateLeft = Notification.Name("rotateLeft")
    static let rotateRight = Notification.Name("rotateRight")
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

 
