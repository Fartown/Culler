import SwiftUI
import SwiftData

#if E2E
@main
struct E2EEntry: App {
    private static let schema = Schema([
        Photo.self,
        Album.self,
        Tag.self,
        ImportedFolder.self
    ])

    let sharedModelContainer: ModelContainer

    init() {
        let modelConfiguration = ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: false)
        do {
            sharedModelContainer = try ModelContainer(for: Self.schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .overlay(E2ESeedView())
                .onAppear { E2ERunner.startIfNeeded() }
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

private struct E2ESeedView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Color.clear
            .onAppear {
                guard UITestConfig.isEnabled else { return }
                if UITestConfig.shouldResetDemoData {
                    UITestDataSeeder.reset(into: modelContext)
                } else {
                    UITestDataSeeder.seedIfNeeded(into: modelContext)
                }
            }
    }
}
#endif
