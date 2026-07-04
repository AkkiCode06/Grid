import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("driverName") private var driverName: String = ""
    @AppStorage("selectedTeamID") private var selectedTeamID = TeamLibrary.all[0].id

    @AppStorage("onbDistraction") private var onbDistraction = ""
    @AppStorage("onbScreenTime") private var onbScreenTime = ""
    @AppStorage("onbSlipping") private var onbSlipping = ""
    @AppStorage("onbStrictness") private var onbStrictness = ""

    // 0=Logo 1=Mission 2=Questions 3=Processing 4=RacePlan 5=Name 6=Team 7=Signing 8=Welcome
    @State private var step = 0
    @State private var questionIndex = 0
    @State private var showInterstitial = false
    @State private var answers: [String: [String]] = [:]

    @State private var processingProgress: CGFloat = 0
    @State private var processingStatus = 0
    @State private var planPhase = 0
    @State private var planRevealed = false

    @State private var localName = ""
    @State private var localTeamID = TeamLibrary.all[0].id
    @State private var signProgress: CGFloat = 0.0
    @State private var sealStamp = false
    @State private var isExiting = false
    @State private var isDrivingOff = false
    @State private var logoGlow = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch step {
            case 0: logoStep
            case 1: missionStep
            case 2: questionsStep
            case 3: processingStep
            case 4: racePlanStep
            case 5: nameStep
            case 6: greetingStep
            case 7: teamStep
            case 8: signingStep
            default: welcomeStep
            }

            Color.black
                .ignoresSafeArea()
                .opacity(isExiting ? 1 : 0)
                .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if step == 0 {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    logoGlow = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { Haptics.impact(.heavy) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeInOut(duration: 1.0)) { step = 1 }
                }
            }
        }
    }

    // MARK: - Logo

    private var logoStep: some View {
        Image("grid_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 220)
            .shadow(color: Theme.raceRed.opacity(logoGlow ? 0.7 : 0.25), radius: logoGlow ? 45 : 20)
            .scaleEffect(logoGlow ? 1.04 : 0.98)
            .transition(.opacity)
    }

    // MARK: - Mission

    private var missionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Image("grid_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72)
                    .padding(.top, 40)

                Text("FOCUS IS A RACE.")
                    .font(.gilroy(38, .black))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Every session is a Grand Prix — you against the clock, against the pull of your phone, against the part of you that quits.")
                    Text("Pick a circuit. Sign for a team. Lights out, and lock in.")
                    Text("No willpower needed. Just the start lights, the laps, and a chequered flag waiting for the driver who doesn't retire.")
                }
                .font(.gilroy(17, .medium))
                .foregroundStyle(.white.opacity(0.6))

                // Loss-aversion hook
                VStack(alignment: .leading, spacing: 6) {
                    Rectangle().fill(Theme.raceRed).frame(width: 40, height: 3)
                    Text("The average person burns 4 hours a day on their phone. That's 60 days a year.")
                        .font(.gilroy(16, .semiBold))
                        .foregroundStyle(.white)
                    Text("GRID wins them back.")
                        .font(.gilroy(16, .black))
                        .foregroundStyle(Theme.raceRed)
                }
                .padding(.top, 6)

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Haptics.impact(.medium)
                withAnimation(.easeInOut(duration: 0.6)) { step = 2 }
            } label: {
                Text("PERSONALIZE MY GRID")
                    .font(.gilroy(18, .bold))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .background(
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                    .allowsHitTesting(false),
                alignment: .bottom
            )
        }
        .transition(.opacity)
    }

    // MARK: - Questions

    private struct Question {
        let key: String
        let prompt: String
        let subtitle: String
        let options: [String]
        let multiSelect: Bool
    }

    private static let questions: [Question] = [
        Question(
            key: "distraction",
            prompt: "What pulls you off the racing line?",
            subtitle: "Pick everything that eats your focus.",
            options: ["Social media", "Mobile games", "News & feeds", "Messaging"],
            multiSelect: true
        ),
        // Real number → the "hours won back" math becomes genuinely theirs,
        // and sets up the gut-punch interstitial right after.
        Question(
            key: "screentime",
            prompt: "Be honest — how long on your phone a day?",
            subtitle: "Roughly your daily average this week.",
            options: ["Under 2 hours", "2–4 hours", "4–6 hours", "6+ hours"],
            multiSelect: false
        ),
        // Loss-framed instead of aspirational — what you're already losing
        // lands harder than what you might gain.
        Question(
            key: "slipping",
            prompt: "What's slipping while you scroll?",
            subtitle: "The thing you keep meaning to fix.",
            options: ["My sleep", "My fitness", "My work & studies", "My relationships"],
            multiSelect: false
        ),
        // The bomb-dropper: reveals GRID actually has teeth.
        Question(
            key: "strictness",
            prompt: "How far should GRID go to keep you locked in?",
            subtitle: "Yes — it can actually do this.",
            options: ["Just remind me", "Block my apps", "Lock me out — no undo"],
            multiSelect: false
        ),
    ]

    /// Days per year lost at the user's stated screen-time rate — for drama.
    private var yearLoss: String {
        switch answers["screentime"]?.first {
        case "Under 2 hours": return "23 days"
        case "2–4 hours": return "45 days"
        case "4–6 hours": return "68 days"
        case "6+ hours": return "90 days"
        default: return "45 days"
        }
    }

    @ViewBuilder
    private var questionsStep: some View {
        if showInterstitial {
            interstitialView
        } else {
            questionCard
        }
    }

    private var interstitialView: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()

            // The gut-punch: their own number, turned into a yearly loss.
            VStack(alignment: .leading, spacing: 4) {
                Text((answers["screentime"]?.first ?? "").uppercased())
                    .font(.gilroy(15, .bold))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.5))
                Text("\(yearLoss) a year.")
                    .font(.gilroy(46, .black))
                    .foregroundStyle(.white)
                Text("Gone. Every single year.")
                    .font(.gilroy(16, .medium))
                    .foregroundStyle(Theme.raceRed)
            }

            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)

            // The "oh — so it ALSO does this?" reveal.
            VStack(alignment: .leading, spacing: 8) {
                Text("AND GRID DOESN'T JUST BLOCK APPS.")
                    .font(.gilroy(12, .black))
                    .kerning(1.5)
                    .foregroundStyle(.white)
                Text("Wander off mid-session and race control waves a yellow flag — right on your Lock Screen. Stay gone too long and it goes red. GRID keeps you honest even when you look away.")
                    .font(.gilroy(15, .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button {
                Haptics.impact(.medium)
                withAnimation(.easeInOut(duration: 0.4)) {
                    showInterstitial = false
                    questionIndex += 1
                }
            } label: {
                Text("SHOW ME MORE")
                    .font(.gilroy(18, .bold))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 32)
        .transition(.opacity)
        .onAppear { Haptics.warning() }
    }

    private var questionCard: some View {
        let q = Self.questions[questionIndex]
        let selected = answers[q.key] ?? []

        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(Self.questions.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= questionIndex ? Theme.raceRed : Color.white.opacity(0.15))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()

            VStack(spacing: 10) {
                Text(q.prompt)
                    .font(.gilroy(27, .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text(q.subtitle)
                    .font(.gilroy(14, .medium))
                    .foregroundStyle(q.key == "strictness" ? Theme.raceRed : .white.opacity(0.5))
            }
            .padding(.horizontal, 32)
            .id(questionIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            VStack(spacing: 12) {
                ForEach(q.options, id: \.self) { option in
                    optionRow(option, isSelected: selected.contains(option), question: q)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 30)

            Spacer()

            if q.multiSelect {
                Button {
                    Haptics.impact(.medium)
                    advanceQuestion()
                } label: {
                    Text("CONTINUE")
                        .font(.gilroy(18, .bold))
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                }
                .disabled(selected.isEmpty)
                .opacity(selected.isEmpty ? 0.5 : 1)
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
            } else {
                Color.clear.frame(height: 56)
            }
        }
        .transition(.opacity)
    }

    private func optionRow(_ option: String, isSelected: Bool, question: Question) -> some View {
        Button {
            Haptics.impact(.light)
            var current = answers[question.key] ?? []
            if question.multiSelect {
                if let idx = current.firstIndex(of: option) {
                    current.remove(at: idx)
                } else {
                    current.append(option)
                }
                answers[question.key] = current
            } else {
                answers[question.key] = [option]
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    advanceQuestion()
                }
            }
        } label: {
            HStack {
                Text(option)
                    .font(.gilroy(16, .semiBold))
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.raceRed)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                isSelected ? Theme.raceRed.opacity(0.18) : Color.white.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Theme.raceRed : Color.white.opacity(0.12),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    private func advanceQuestion() {
        // Encouraging interstitial after the 2nd question.
        if questionIndex == 1 {
            withAnimation(.easeInOut(duration: 0.4)) { showInterstitial = true }
            return
        }
        if questionIndex < Self.questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.4)) { questionIndex += 1 }
        } else {
            onbDistraction = (answers["distraction"] ?? []).joined(separator: ", ")
            onbScreenTime = (answers["screentime"] ?? []).first ?? ""
            onbSlipping = (answers["slipping"] ?? []).first ?? ""
            onbStrictness = (answers["strictness"] ?? []).first ?? ""
            withAnimation(.easeInOut(duration: 0.6)) { step = 3 }
        }
    }

    // MARK: - Processing

    private static let processingStatuses = [
        "Analysing your distractions",
        "Calculating time recovery",
        "Setting your lock strength",
        "Finalising your race plan",
    ]

    private var processingStep: some View {
        VStack(spacing: 34) {
            Spacer()

            Text("BUILDING YOUR RACE PLAN")
                .font(.gilroy(20, .black))
                .kerning(1)
                .foregroundStyle(.white)

            // Track with a car running along the fill.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                        .frame(maxHeight: .infinity)
                    Capsule()
                        .fill(Theme.raceRed)
                        .frame(width: geo.size.width * processingProgress, height: 8)
                        .frame(maxHeight: .infinity)
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 30))
                        .scaleEffect(x: -1, y: 1)
                        .foregroundStyle(.white)
                        .offset(x: max(0, geo.size.width * processingProgress - 26))
                }
            }
            .frame(height: 40)
            .padding(.horizontal, 40)

            Text(Self.processingStatuses[min(processingStatus, Self.processingStatuses.count - 1)])
                .font(.gilroy(14, .medium))
                .foregroundStyle(.white.opacity(0.6))
                .id(processingStatus)
                .transition(.opacity)

            Spacer()
        }
        .transition(.opacity)
        .onAppear {
            processingProgress = 0
            processingStatus = 0
            withAnimation(.easeInOut(duration: 3.0)) { processingProgress = 1 }
            for i in 1..<Self.processingStatuses.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.72) {
                    Haptics.impact(.light)
                    withAnimation(.easeInOut(duration: 0.3)) { processingStatus = i }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                Haptics.success()
                planPhase = 0
                planRevealed = false
                withAnimation(.easeInOut(duration: 0.6)) { step = 4 }
            }
        }
    }

    // MARK: - Race Plan (cardless, full-bleed)

    private var hoursWon: Int {
        // Derived from their own stated screen time — GRID reclaims roughly
        // half of it, monthly.
        switch answers["screentime"]?.first {
        case "Under 2 hours": return 20
        case "2–4 hours": return 45
        case "4–6 hours": return 75
        case "6+ hours": return 100
        default: return 45
        }
    }

    private var archetype: (title: String, blurb: String) {
        switch (answers["distraction"] ?? []).first {
        case "Social media": return ("THE DOOMSCROLLER", "Your thumb has a mind of its own. GRID gives it a pit wall.")
        case "Mobile games": return ("THE GRINDER", "\"One more level\" becomes one more hour. Not on race day.")
        case "News & feeds": return ("THE CHANNEL SURFER", "Always refreshing, never resting. Time to park it.")
        case "Messaging": return ("THE PIT-RADIO ADDICT", "The group chat can wait for the chequered flag.")
        default: return ("THE EASILY LAPPED", "Distraction keeps overtaking you. Let's fix the setup.")
        }
    }

    private var goalPayoff: String {
        switch answers["slipping"]?.first {
        case "My sleep": return "enough to reclaim a full night of sleep every week"
        case "My fitness": return "enough for 40 workouts"
        case "My work & studies": return "enough to finish what you keep putting off"
        case "My relationships": return "enough to actually be there for the people who matter"
        default: return "yours to spend however you want"
        }
    }

    private var successScore: Int {
        switch answers["strictness"]?.first {
        case "Lock me out — no undo": return 94
        case "Block my apps": return 78
        case "Just remind me": return 55
        default: return 78
        }
    }

    private var planBackground: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [Theme.raceRed.opacity(0.28), .clear],
                center: UnitPoint(x: 0.12, y: 0.02),
                startRadius: 0, endRadius: 620
            )
            LinearGradient(
                colors: [.clear, .clear, Theme.raceRed.opacity(0.10)],
                startPoint: .top, endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var racePlanStep: some View {
        ZStack {
            planBackground

            if planPhase == 0 {
                hookView
            } else {
                fullPlanView
            }
        }
        .onAppear {
            // Full-screen hook first, then fade into the full plan.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.easeInOut(duration: 0.7)) { planPhase = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(duration: 0.7, bounce: 0.25)) { planRevealed = true }
                }
            }
        }
    }

    private var hookView: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("GRID CAN WIN YOU BACK")
                .font(.gilroy(15, .bold))
                .kerning(3)
                .foregroundStyle(.white.opacity(0.6))
            Text("\(hoursWon) HOURS")
                .font(.gilroy(68, .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("every single month.")
                .font(.gilroy(17, .medium))
                .foregroundStyle(Theme.raceRed)
            Spacer()
        }
        .padding(.horizontal, 24)
        .transition(.opacity)
    }

    private var fullPlanView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR RACE PLAN")
                .font(.gilroy(12, .bold))
                .kerning(3)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 20)

            Spacer(minLength: 20)

            // Archetype — the hero
            VStack(alignment: .leading, spacing: 12) {
                Text(archetype.title)
                    .font(.gilroy(40, .black))
                    .foregroundStyle(Theme.raceRed)
                Text(archetype.blurb)
                    .font(.gilroy(17, .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .opacity(planRevealed ? 1 : 0)
            .offset(y: planRevealed ? 0 : 18)

            Spacer(minLength: 28)
            divider
            Spacer(minLength: 28)

            // Time won back — big hero number
            VStack(alignment: .leading, spacing: 4) {
                Text("TIME WON BACK")
                    .font(.gilroy(11, .bold))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.4))
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(hoursWon)")
                        .font(.gilroy(64, .heavy))
                        .foregroundStyle(.white)
                    Text("hrs / month")
                        .font(.gilroy(22, .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text("That's \(goalPayoff).")
                    .font(.gilroy(16, .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .opacity(planRevealed ? 1 : 0)
            .offset(y: planRevealed ? 0 : 26)

            Spacer(minLength: 28)
            divider
            Spacer(minLength: 28)

            // Success probability
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("SUCCESS PROBABILITY")
                        .font(.gilroy(11, .bold))
                        .kerning(2)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("\(successScore)%")
                        .font(.gilroy(22, .heavy))
                        .foregroundStyle(.green)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Theme.raceRed, .green],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: planRevealed ? geo.size.width * CGFloat(successScore) / 100 : 0)
                    }
                }
                .frame(height: 12)
                Text("Your \"\(answers["strictness"]?.first ?? "Balanced")\" setting keeps you honest when motivation dips.")
                    .font(.gilroy(13, .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .opacity(planRevealed ? 1 : 0)
            .offset(y: planRevealed ? 0 : 34)

            Spacer(minLength: 28)

            Button {
                Haptics.impact(.medium)
                withAnimation(.easeInOut(duration: 0.6)) { step = 5 }
            } label: {
                Text("BUILD MY GRID")
                    .font(.gilroy(18, .bold))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }
            .opacity(planRevealed ? 1 : 0)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .transition(.opacity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .opacity(planRevealed ? 1 : 0)
    }

    // MARK: - Name

    private var nameStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("ENTER YOUR NAME")
                .font(.gilroy(20, .bold))
                .kerning(4)
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 12) {
                TextField("", text: $localName, prompt: Text("Your name").foregroundStyle(.white.opacity(0.25)))
                    .font(.gilroy(44, .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                Rectangle()
                    .fill(localName.isEmpty ? Color.white.opacity(0.2) : Theme.raceRed)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.3), value: localName.isEmpty)
            }
            .padding(.horizontal, 44)

            Spacer()

            Button {
                Haptics.impact(.medium)
                let trimmed = localName.trimmingCharacters(in: .whitespacesAndNewlines)
                driverName = trimmed.isEmpty ? "Driver" : trimmed
                withAnimation(.easeInOut(duration: 0.6)) { step = 6 }
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
        .transition(.opacity)
    }

    // MARK: - Greeting (personalized hand-off to team pick)

    private var greetingStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Text("HEY \(driverName.uppercased()).")
                .font(.gilroy(40, .black))
                .foregroundStyle(.white)

            Text("Every driver needs a team. Pick your colours — it liveries your paddock pass and puts your name on the timing screen.")
                .font(.gilroy(17, .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Button {
                Haptics.impact(.medium)
                withAnimation(.easeInOut(duration: 0.6)) { step = 7 }
            } label: {
                Text("CHOOSE MY TEAM")
                    .font(.gilroy(18, .bold))
                    .kerning(2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }
            .padding(.bottom, 64)
        }
        .padding(.horizontal, 32)
        .transition(.opacity)
    }

    // MARK: - Team

    private var teamStep: some View {
        ZStack {
            TabView(selection: $localTeamID) {
                ForEach(TeamLibrary.all) { team in
                    teamCard(for: team, driveOff: isDrivingOff && team.id == localTeamID)
                        .tag(team.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .disabled(isDrivingOff)

            let selectedTeam = TeamLibrary.team(id: localTeamID) ?? TeamLibrary.all[0]

            VStack {
                Spacer()

                Button {
                    guard !isDrivingOff else { return }
                    Haptics.impact(.heavy)
                    withAnimation(.easeIn(duration: 0.5)) { isDrivingOff = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                        selectedTeamID = localTeamID
                        PassThemeStore.shared.applyTeam(selectedTeam)
                        withAnimation(.easeInOut(duration: 0.6)) { step = 8 }
                        startSigningAnimation()
                        isDrivingOff = false
                    }
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
                        .foregroundStyle(
                            selectedTeam.id == "ivory" ? Color(hex: selectedTeam.foilHex) : .white
                        )
                        .shadow(color: Color(hex: selectedTeam.accentHex).opacity(0.4), radius: 8, y: 4)
                }
                .animation(.easeInOut(duration: 0.45), value: localTeamID)
                .opacity(isDrivingOff ? 0 : 1)
                .padding(.horizontal, 32)
                .padding(.bottom, 64)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    @ViewBuilder
    private func teamCard(for team: Team, driveOff: Bool) -> some View {
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
                .opacity(driveOff ? 0 : 1)

                Spacer()
            }

            Image(team.assetName)
                .resizable()
                .scaledToFit()
                .frame(height: UIScreen.main.bounds.height * 0.75)
                .shadow(color: .black.opacity(0.8), radius: 20, y: 15)
                .offset(y: driveOff ? -UIScreen.main.bounds.height * 1.15 : 0)
                .scaleEffect(driveOff ? 0.82 : 1, anchor: .top)
                .blur(radius: driveOff ? 10 : 0)
        }
    }

    // MARK: - Signing

    private var signingStep: some View {
        let team = TeamLibrary.team(id: localTeamID) ?? TeamLibrary.all[0]
        let accent = Color(hex: team.accentHex)
        return ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [accent.opacity(0.4), .clear],
                center: .center, startRadius: 10, endRadius: 480
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("\(team.threeLetterCode) · CAR \(team.carNumber)")
                    .font(.gilroy(12, .bold))
                    .kerning(3)
                    .foregroundStyle(.white.opacity(0.5))

                Text("SIGNED TO")
                    .font(.gilroy(15, .medium))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 14)

                Text(team.name.uppercased())
                    .font(.gilroy(34, .black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 24)
                    .padding(.top, 2)

                // Signature writing itself in, in the team's ink.
                Text(driverName)
                    .font(.custom("SnellRoundhand-Bold", size: 56))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    .mask(
                        GeometryReader { geo in
                            Rectangle().frame(width: geo.size.width * signProgress)
                        }
                    )

                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 220, height: 1)
                    .padding(.top, 6)
                Text("DRIVER SIGNATURE")
                    .font(.gilroy(9, .bold))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 8)

                Spacer()
            }

            // The seal slams in over the top.
            Text("SEALED")
                .font(.gilroy(26, .black))
                .kerning(4)
                .foregroundStyle(accent)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(accent, lineWidth: 3)
                )
                .rotationEffect(.degrees(-14))
                .scaleEffect(sealStamp ? 1 : 2.4)
                .opacity(sealStamp ? 0.95 : 0)
                .offset(y: 150)
        }
        .transition(.opacity)
    }

    private func startSigningAnimation() {
        signProgress = 0
        sealStamp = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { Haptics.impact(.light) }

        withAnimation(.easeOut(duration: 2.2).delay(0.4)) { signProgress = 1.0 }

        // The seal drops the moment the signature finishes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            Haptics.impact(.heavy)
            Haptics.success()
            withAnimation(.spring(duration: 0.4, bounce: 0.5)) { sealStamp = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.easeInOut(duration: 0.6)) { step = 9 }
        }
    }

    // MARK: - Welcome

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

                Text("LIGHTS OUT WHEN YOU ARE.")
                    .font(.gilroy(16, .medium))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button {
                    Haptics.impact(.heavy)
                    showPaywall = true
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
        .sheet(isPresented: $showPaywall) {
            OnboardingPaywallView(onFinish: finishOnboarding)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func finishOnboarding() {
        showPaywall = false
        withAnimation(.easeIn(duration: 0.5)) { isExiting = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.6)) {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    OnboardingView()
}
