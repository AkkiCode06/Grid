import SwiftUI

/// A hands-free "how it works" loop for Pass Studio: the pass recolours,
/// changes finish, renames itself and re-tints — on its own, forever — so a
/// new user immediately sees what customization looks like.
struct PassStudioDemoView: View {
    let model: PassCardModel
    var onClose: (() -> Void)? = nil

    @State private var theme = PassTheme()
    @State private var caption = "Make the pass yours"
    @State private var loop: Task<Void, Never>?

    private struct Step {
        let caption: String
        let apply: (inout PassTheme) -> Void
    }

    private let steps: [Step] = [
        Step(caption: "Recolour the card") { $0.accentHex = "1F6FEB"; $0.inkHex = "F5F5F7" },
        Step(caption: "Switch the finish") { $0.texture = .gloss },
        Step(caption: "Go holographic") { $0.texture = .holographic; $0.accentHex = "E5006E" },
        Step(caption: "Rename the print") { $0.roleText = "PRO"; $0.roleFont = .heavy },
        Step(caption: "Tint the flourish") { $0.foilHex = "36E2FF"; $0.scriptText = "Member" },
        Step(caption: "Colour the track") { $0.trackHex = "FFC300" },
        Step(caption: "Endless combinations") { $0 = PassTheme() },
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                if let onClose {
                    HStack {
                        Spacer()
                        Button {
                            Haptics.impact(.light)
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(9)
                                .background(.white.opacity(0.08), in: Circle())
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                }

                Text("HOW PASS STUDIO WORKS")
                    .font(.gilroy(11, .black)).kerning(2.5)
                    .foregroundStyle(Theme.raceRed)
                    .padding(.top, onClose == nil ? 24 : 0)

                Spacer(minLength: 0)

                PassCardView(model: model, stamped: true, themeOverride: theme)
                    .frame(width: 270)
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 12)

                Text(caption)
                    .font(.gilroy(20, .heavy))
                    .foregroundStyle(.white)
                    .id(caption)
                    .transition(.push(from: .bottom).combined(with: .opacity))

                Spacer(minLength: 0)

                Text("Tap any part of the pass in the studio to change it yourself.")
                    .font(.gilroy(13, .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { start() }
        .onDisappear { loop?.cancel() }
    }

    private func start() {
        loop?.cancel()
        loop = Task {
            // Small beat before the first change so the base pass registers.
            try? await Task.sleep(nanoseconds: 900_000_000)
            while !Task.isCancelled {
                for step in steps {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.55)) {
                            step.apply(&theme)
                            caption = step.caption
                        }
                        Haptics.impact(.light)
                    }
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    if Task.isCancelled { return }
                }
            }
        }
    }
}
