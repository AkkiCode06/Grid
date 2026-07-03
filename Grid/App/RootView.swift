import SwiftUI

struct RootView: View {
    @Environment(SessionController.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch session.phase {
            case .idle:
                HomeView()
                    .transition(.opacity)
            case .passIssued(let pass):
                PaddockPassView(pass: pass)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .lightsSequence:
                LightsOutView()
                    .transition(.opacity)
            case .racing(let pass, let startDate):
                RacingView(pass: pass, startDate: startDate)
                    .transition(.opacity)
            case .ended(let pass, let startDate, let result):
                FinishView(pass: pass, startDate: startDate, result: result)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.phase)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                session.tick()
            }
        }
    }
}
