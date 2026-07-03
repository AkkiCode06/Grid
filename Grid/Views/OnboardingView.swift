import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("driverName") private var driverName: String = ""
    @AppStorage("selectedTeamID") private var selectedTeamID = TeamLibrary.all[0].id

    @State private var step = 0 // 0=Logo, 1=Name, 2=Team Picker, 3=Signing, 4=Welcome
    @State private var localName = ""
    @State private var localTeamID = TeamLibrary.all[0].id
    @State private var signProgress: CGFloat = 0.0
    @State private var isExiting = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if step == 0 {
                logoStep
            } else if step == 1 {
                nameStep
            } else if step == 2 {
                teamStep
            } else if step == 3 {
                signingStep
            } else if step == 4 {
                welcomeStep
            }

            // Fade-to-black exit before handing over to the paddock.
            Color.black
                .ignoresSafeArea()
                .opacity(isExiting ? 1 : 0)
                .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if step == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Haptics.impact(.heavy)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        step = 1
                    }
                }
            }
        }
    }

    // MARK: - Logo Step

    private var logoStep: some View {
        ZStack {
            ChequeredFlagView()
                .opacity(0.08)
                .ignoresSafeArea()

            Text("GRID")
                .font(.gilroy(64, .black))
                .italic()
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 0)
        }
        .transition(.opacity)
    }

    // MARK: - Name Step

    private var nameStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("ENTER YOUR NAME")
                .font(.gilroy(20, .bold))
                .kerning(4)
                .foregroundStyle(.white.opacity(0.6))

            TextField("Driver", text: $localName)
                .font(.gilroy(44, .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.vertical, 22)
                .padding(.horizontal, 20)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 28)

            Spacer()

            Button {
                Haptics.impact(.medium)
                let trimmed = localName.trimmingCharacters(in: .whitespacesAndNewlines)
                driverName = trimmed.isEmpty ? "Driver" : trimmed
                withAnimation(.easeInOut(duration: 0.6)) {
                    step = 2
                }
            } label: {
                Text("CONTINUE")
                    .font(.gilroy(18, .bold))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }
            .disabled(localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .padding(.horizontal, 32)
            .padding(.bottom, 64)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Team Step

    private var teamStep: some View {
        ZStack {
            TabView(selection: $localTeamID) {
                ForEach(TeamLibrary.all) { team in
                    teamCard(for: team)
                        .tag(team.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            let selectedTeam = TeamLibrary.team(id: localTeamID) ?? TeamLibrary.all[0]

            VStack {
                Spacer()

                Button {
                    Haptics.impact(.heavy)
                    selectedTeamID = localTeamID
                    PassThemeStore.shared.applyTeam(selectedTeam)
                    withAnimation(.easeInOut(duration: 0.6)) {
                        step = 3
                    }
                    startSigningAnimation()
                } label: {
                    Text("SIGN CONTRACT")
                        .font(.gilroy(18, .bold))
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            Color(hex: selectedTeam.accentHex),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .foregroundStyle(.white)
                        .shadow(
                            color: Color(hex: selectedTeam.accentHex).opacity(0.4),
                            radius: 8, x: 0, y: 4
                        )
                }
                .animation(.easeInOut(duration: 0.45), value: localTeamID)
                .padding(.horizontal, 32)
                .padding(.bottom, 64)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    @ViewBuilder
    private func teamCard(for team: Team) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: team.accentHex).opacity(0.6), .black],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack {
                HStack(alignment: .lastTextBaseline, spacing: 12) {
                    Text("\(team.carNumber)")
                        .font(.gilroy(56, .black))
                        .foregroundStyle(.white)

                    Text("|")
                        .font(.gilroy(40, .light))
                        .foregroundStyle(.white.opacity(0.3))

                    Text(team.threeLetterCode)
                        .font(.gilroy(40, .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 40)

                Spacer()
            }

            Image(team.assetName)
                .resizable()
                .scaledToFit()
                .frame(height: UIScreen.main.bounds.height * 0.75)
                .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 15)
        }
    }

    // MARK: - Signing Step

    private var signingStep: some View {
        let team = TeamLibrary.team(id: localTeamID) ?? TeamLibrary.all[0]
        return ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Text("SIGNING CONTRACT…")
                    .font(.gilroy(16, .bold))
                    .kerning(3)
                    .foregroundStyle(.white.opacity(0.6))

                // The contract paper
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("GRID RACING")
                            .font(.gilroy(15, .black))
                            .kerning(2)
                            .foregroundStyle(.black)
                        Spacer()
                        Text("OFFICIAL DRIVER CONTRACT")
                            .font(.gilroy(8, .bold))
                            .kerning(1.5)
                            .foregroundStyle(.black.opacity(0.4))
                    }

                    Rectangle()
                        .fill(Color(hex: team.accentHex))
                        .frame(height: 3)

                    Group {
                        Text("CLAUSE 1 — ")
                            .font(.gilroy(8, .black))
                        + Text("\(driverName) hereby agrees to lock in until the chequered flag. No doomscrolling, no \"just checking one thing\", no exceptions.")
                            .font(.gilroy(8, .regular))
                    }
                    .foregroundStyle(.black.opacity(0.65))

                    Group {
                        Text("CLAUSE 2 — ")
                            .font(.gilroy(8, .black))
                        + Text("Early exits are stamped DNF and remembered forever. \(team.name) does not comment on retirements.")
                            .font(.gilroy(8, .regular))
                    }
                    .foregroundStyle(.black.opacity(0.65))

                    Group {
                        Text("CLAUSE 3 — ")
                            .font(.gilroy(8, .black))
                        + Text("The undersigned accepts that the group chat can wait, and that any lateness will be blamed on box, box, box.")
                            .font(.gilroy(8, .regular))
                    }
                    .foregroundStyle(.black.opacity(0.65))

                    Spacer(minLength: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(driverName)
                            .font(.custom("SnellRoundhand-Bold", size: 42))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.3)
                            .mask(
                                GeometryReader { geo in
                                    Rectangle()
                                        .frame(width: geo.size.width * signProgress)
                                }
                            )
                        Rectangle()
                            .fill(.black.opacity(0.35))
                            .frame(height: 1)
                        HStack {
                            Text("DRIVER SIGNATURE")
                                .font(.gilroy(7, .bold))
                                .kerning(1.5)
                            Spacer()
                            Text(Date.now.formatted(date: .abbreviated, time: .omitted).uppercased())
                                .font(.gilroy(7, .bold))
                                .kerning(1)
                        }
                        .foregroundStyle(.black.opacity(0.4))
                    }
                }
                .padding(20)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                .frame(height: 320)
                .padding(.horizontal, 32)
                .shadow(color: .white.opacity(0.12), radius: 24)
            }
        }
        .transition(.opacity)
    }

    private func startSigningAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { Haptics.impact(.light) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { Haptics.impact(.medium) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { Haptics.impact(.heavy) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { Haptics.success() }

        withAnimation(.easeOut(duration: 3.2).delay(0.2)) {
            signProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            withAnimation(.easeInOut(duration: 0.6)) {
                step = 4
            }
        }
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        ZStack {
            ChequeredFlagView()
                .opacity(0.09)
                .ignoresSafeArea()

            LinearGradient(
                colors: [Theme.raceRed.opacity(0.35), .clear, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("WELCOME TO GRID")
                    .font(.gilroy(32, .black))
                    .kerning(2)
                    .foregroundStyle(.white)

                Text("YOUR JOURNEY BEGINS NOW.")
                    .font(.gilroy(16, .medium))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button {
                    Haptics.impact(.heavy)
                    withAnimation(.easeIn(duration: 0.5)) {
                        isExiting = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        withAnimation(.easeOut(duration: 0.6)) {
                            hasCompletedOnboarding = true
                        }
                    }
                } label: {
                    Text("ENTER PADDOCK")
                        .font(.gilroy(18, .bold))
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 64)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

#Preview {
    OnboardingView()
}
