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
                    #if DEBUG
                    // Screenshot/UI-test hook: land mid-race via the restore path.
                    if ProcessInfo.processInfo.arguments.contains("-uitest-racing"),
                       let circuit = CircuitLibrary.all.first {
                        SharedStore.saveActiveSession(ActiveSessionSnapshot(
                            driverName: "TEST DRIVER",
                            circuitID: circuit.id,
                            circuitName: circuit.name,
                            teamName: TeamLibrary.all[0].name,
                            sessionNumber: 99,
                            startDate: .now.addingTimeInterval(-300),
                            durationSeconds: 1500,
                            lapSeconds: circuit.lapSeconds
                        ))
                    }
                    #endif
                    session.restoreOnLaunch()
                    #if DEBUG
                    // Screenshot/UI-test hook: jump straight to an issued pass.
                    if ProcessInfo.processInfo.arguments.contains("-uitest-pass"),
                       let circuit = CircuitLibrary.all.first {
                        session.issuePass(circuit: circuit, team: TeamLibrary.all[0])
                    }
                    #endif
                    await StoreService.shared.start()
                }
        }
        .modelContainer(modelContainer)
    }
}
