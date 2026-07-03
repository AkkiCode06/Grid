import SwiftUI
import SwiftData

@main
struct GridApp: App {
    private let modelContainer: ModelContainer
    @State private var session: SessionController

    init() {
        AppConfig.registerDefaultPreferences()
        do {
            modelContainer = try ModelContainer(for: RaceRecord.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        _session = State(initialValue: SessionController())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .task {
                    session.attachModelContext(modelContainer.mainContext)
                    session.restoreOnLaunch()
                    await StoreService.shared.start()
                }
        }
        .modelContainer(modelContainer)
    }
}
