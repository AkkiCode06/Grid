import SwiftUI

/// Full-screen immersive circuit selection matching the racing view.
/// Swipe left/right for circuits (TabView with transparent pages).
/// Photorealistic flyover cycling between circuit and city modes.
struct HomeView: View {
    @Environment(SessionController.self) private var session

    @State private var selectedCircuitID: String = CircuitLibrary.all.first?.id ?? "monteCarlo"
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

            // Foreground UI
            VStack(spacing: 0) {
                header
                Spacer()
                
                // Bottom overlay area
                VStack(spacing: 24) {
                    circuitInfoOverlay
                    teamPicker
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
        }
        .sheet(isPresented: $showingRaceLog) { RaceLogView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingPassStudio) { PassStudioView() }
        .onAppear { customMinutes = session.customDurationMinutes }
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

    private var teamPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGN FOR A TEAM")
                .font(.gilroy(11, .bold))
                .kerning(2)
                .foregroundStyle(.white.opacity(0.6))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TeamLibrary.all) { team in
                        let isSelected = team.id == selectedTeamID
                        Button {
                            Haptics.impact(.light)
                            selectedTeamID = team.id
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: team.accentHex))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                    )
                                Text(team.name)
                                    .font(.gilroy(13, .bold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                isSelected ? Color(hex: team.accentHex).opacity(0.3) : .black.opacity(0.5),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Color(hex: team.accentHex) : .white.opacity(0.15),
                                    lineWidth: 1.5
                                )
                            )
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .zIndex(1)
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
}
