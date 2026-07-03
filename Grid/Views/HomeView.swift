import SwiftUI
import SwiftData

/// Full-screen immersive circuit selection matching the racing view.
/// Swipe left/right for circuits (TabView with transparent pages).
/// Photorealistic flyover cycling between circuit and city modes.
struct HomeView: View {
    @Environment(SessionController.self) private var session
    @Query(sort: \RaceRecord.startDate, order: .reverse) private var raceRecords: [RaceRecord]

    @State private var selectedCircuitID: String = CircuitLibrary.all.first?.id ?? "monteCarlo"
    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    @State private var swipeHintVisible = false
    @AppStorage("selectedTeamID") private var selectedTeamID = TeamLibrary.all[0].id
    @State private var customMinutes: Int = 30
    @State private var showingRaceLog = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var showingPassStudio = false

    private var store: StoreService { StoreService.shared }

    private var selectedCircuit: Circuit {
        CircuitLibrary.circuit(id: selectedCircuitID) ?? CircuitLibrary.all[0]
    }

    private var selectedTeam: Team {
        TeamLibrary.team(id: selectedTeamID) ?? TeamLibrary.all[0]
    }

    private func isLocked(_ circuit: Circuit) -> Bool {
        !circuit.isFree && !store.hasFullAccess
    }

    var body: some View {
        ZStack {
            // Background Flyover
            if CircuitGeo.coordinates(for: selectedCircuit.id) != nil {
                CircuitFlyoverView(
                    circuitID: selectedCircuit.id,
                    isPaused: false,
                    dualMode: true
                )
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.45).ignoresSafeArea())
            } else {
                LinearGradient(
                    colors: selectedCircuit.skyColors.map { Color(hex: $0).opacity(0.35) },
                    startPoint: .top,
                    endPoint: .bottom
                )
                .background(Theme.background)
                .ignoresSafeArea()
            }

            // Hidden TabView for swiping logic
            TabView(selection: $selectedCircuitID) {
                ForEach(CircuitLibrary.all) { circuit in
                    Color.clear
                        .tag(circuit.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .overlay { navigationArrows }

            // Foreground UI
            VStack(spacing: 0) {
                header
                Spacer()
                
                // Bottom overlay area
                VStack(spacing: 24) {
                    circuitInfoOverlay
                    statsOverlay
                    issueButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6), .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                    .padding(.horizontal, -24)
                    .padding(.bottom, -64)
                )
            }

            // First-run coach mark: show how to swipe between circuits.
            if swipeHintVisible {
                SwipeHintView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingRaceLog) { RaceLogView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingPassStudio) { PassStudioView() }
        .onAppear {
            customMinutes = session.customDurationMinutes
            if !hasSeenSwipeHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeIn(duration: 0.5)) { swipeHintVisible = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
                    hasSeenSwipeHint = true
                    withAnimation(.easeOut(duration: 0.5)) { swipeHintVisible = false }
                }
            }
        }
        .onChange(of: selectedCircuitID) { _, _ in
            if !hasSeenSwipeHint || swipeHintVisible {
                hasSeenSwipeHint = true
                withAnimation(.easeOut(duration: 0.3)) { swipeHintVisible = false }
            }
        }
        .onChange(of: customMinutes) { _, newValue in
            session.customDurationMinutes = newValue
        }
        .onChange(of: selectedTeamID) { _, _ in
            PassThemeStore.shared.applyTeam(selectedTeam)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            Text("GRID")
                .font(.gilroy(32, .black))
                .italic()
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)

            Spacer()

            HStack(spacing: 12) {
                actionIcon(systemName: "paintbrush.fill") { showingPassStudio = true }
                actionIcon(systemName: "flag.checkered") { showingRaceLog = true }
                actionIcon(systemName: "gearshape.fill") { showingSettings = true }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        // Make header tapable above the transparent TabView
        .zIndex(1) 
    }

    private func actionIcon(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.gilroy(16, .bold))
                .foregroundStyle(.white)
                .padding(12)
                .background(.black.opacity(0.4), in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1))
        }
    }

    private var circuitInfoOverlay: some View {
        VStack(spacing: 10) {
            HStack {
                Text(selectedCircuit.flag)
                    .font(.title2)
                Text(selectedCircuit.country.uppercased())
                    .font(.gilroy(14, .bold))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                if isLocked(selectedCircuit) {
                    Label("LOCKED", systemImage: "lock.fill")
                        .font(.gilroy(11, .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.gold.opacity(0.2), in: Capsule())
                        .foregroundStyle(Theme.gold)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCircuit.name)
                    .font(.gilroy(34, .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let durationText = selectedCircuit.isCustom ? "\(customMinutes) MIN" : "\(selectedCircuit.durationMinutes ?? 0) MIN"
                let lapsText = "\(selectedCircuit.totalLaps(customMinutes: customMinutes)) LAPS"

                HStack(spacing: 12) {
                    Text(durationText)
                    Text("•").foregroundStyle(.white.opacity(0.4))
                    Text(lapsText)
                }
                .font(.gilroy(15, .bold))
                .foregroundStyle(Theme.raceRed)
            }

            if selectedCircuit.isCustom {
                Stepper(value: $customMinutes, in: 5...240, step: 5) {
                    Text("\(customMinutes) MINUTES")
                        .font(.gilroy(14, .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)
                .zIndex(1)
            }
        }
        .zIndex(1)
    }

    private var statsOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LAST SESSION STATS")
                .font(.gilroy(11, .bold))
                .kerning(2)
                .foregroundStyle(.white.opacity(0.6))
            
            if let lastRecord = raceRecords.first(where: { $0.circuitID == selectedCircuitID }) {
                let isFinished = lastRecord.result == .finished
                Text(formatRecordResult(lastRecord, isFinished: isFinished))
                    .font(.gilroy(13, .bold))
                    .foregroundStyle(isFinished ? Theme.gold : Theme.raceRed)
            } else {
                Text("NEVER RACED")
                    .font(.gilroy(13, .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zIndex(1)
    }

    private func formatRecordResult(_ record: RaceRecord, isFinished: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateString = formatter.string(from: record.startDate).uppercased()
        return isFinished ? "COMPLETED ON \(dateString)" : "DNF (\(dateString))"
    }

    private var issueButton: some View {
        Button {
            if isLocked(selectedCircuit) {
                showingPaywall = true
            } else {
                Haptics.impact(.medium)
                session.issuePass(circuit: selectedCircuit, team: selectedTeam)
            }
        } label: {
            HStack {
                Image(systemName: isLocked(selectedCircuit) ? "lock.fill" : "ticket.fill")
                Text(isLocked(selectedCircuit) ? "UNLOCK ALL CIRCUITS" : "ISSUE PADDOCK PASS")
                    .kerning(1.5)
            }
            .font(.gilroy(15, .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.raceRed, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
            .shadow(color: Theme.raceRed.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .zIndex(1)
    }

    private var navigationArrows: some View {
        let currentIndex = CircuitLibrary.all.firstIndex(where: { $0.id == selectedCircuitID }) ?? 0
        
        return HStack {
            if currentIndex > 0 {
                Button {
                    Haptics.impact(.light)
                    withAnimation {
                        selectedCircuitID = CircuitLibrary.all[currentIndex - 1].id
                    }
                } label: {
                    Image(systemName: "chevron.compact.left")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding()
                }
            }
            
            Spacer()
            
            if currentIndex < CircuitLibrary.all.count - 1 {
                Button {
                    Haptics.impact(.light)
                    withAnimation {
                        selectedCircuitID = CircuitLibrary.all[currentIndex + 1].id
                    }
                } label: {
                    Image(systemName: "chevron.compact.right")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding()
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

/// Animated "swipe to explore" coach mark shown once on first launch.
struct SwipeHintView: View {
    @State private var handOffset: CGFloat = -26

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 26))
                .foregroundStyle(.white)
                .offset(x: handOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        handOffset = 26
                    }
                }
            HStack(spacing: 10) {
                Image(systemName: "chevron.left")
                Text("SWIPE TO EXPLORE CIRCUITS")
                    .font(.gilroy(11, .bold))
                    .kerning(2)
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
