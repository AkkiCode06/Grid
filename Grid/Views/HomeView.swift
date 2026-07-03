import SwiftUI

/// Circuit selection: horizontally paged circuit cards with a per-circuit
/// grandstand seat picker. The seat decides which backdrop and flyby clips
/// play during the session.
struct HomeView: View {
    @Environment(SessionController.self) private var session

    @State private var selectedCircuitID: String = CircuitLibrary.all.first?.id ?? "monteCarlo"
    @State private var seatSelections: [String: String] = [:]
    @State private var customMinutes: Int = 30
    @State private var showingRaceLog = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var showingPassStudio = false

    private var store: StoreService { StoreService.shared }

    private var selectedCircuit: Circuit {
        CircuitLibrary.circuit(id: selectedCircuitID) ?? CircuitLibrary.all[0]
    }

    private func selectedSeat(for circuit: Circuit) -> Seat {
        let seatID = seatSelections[circuit.id]
        return circuit.seats.first { $0.id == seatID } ?? circuit.seats[0]
    }

    private func isLocked(_ circuit: Circuit) -> Bool {
        !circuit.isFree && !store.hasFullAccess
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                TabView(selection: $selectedCircuitID) {
                    ForEach(CircuitLibrary.all) { circuit in
                        CircuitCardView(
                            circuit: circuit,
                            selectedSeatID: Binding(
                                get: { seatSelections[circuit.id] ?? circuit.seats[0].id },
                                set: { seatSelections[circuit.id] = $0 }
                            ),
                            customMinutes: $customMinutes,
                            isLocked: isLocked(circuit)
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .tag(circuit.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                issueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
            .background(Theme.background)
            .sheet(isPresented: $showingRaceLog) { RaceLogView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingPassStudio) { PassStudioView() }
            .onAppear { customMinutes = session.customDurationMinutes }
            .onChange(of: customMinutes) { _, newValue in
                session.customDurationMinutes = newValue
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("GRID")
                    .font(.system(size: 28, weight: .black, design: .default))
                    .italic()
                    .foregroundStyle(Theme.textPrimary)
                Text("PICK YOUR CIRCUIT")
                    .font(.telemetry(11))
                    .foregroundStyle(Theme.textSecondary)
                    .kerning(2)
            }
            Spacer()
            Button {
                showingPassStudio = true
            } label: {
                Image(systemName: "paintbrush.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.trailing, 12)
            Button {
                showingRaceLog = true
            } label: {
                Image(systemName: "flag.checkered")
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.trailing, 12)
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var issueButton: some View {
        Button {
            if isLocked(selectedCircuit) {
                showingPaywall = true
            } else {
                Haptics.impact(.medium)
                session.issuePass(
                    circuit: selectedCircuit,
                    seat: selectedSeat(for: selectedCircuit)
                )
            }
        } label: {
            HStack {
                Image(systemName: isLocked(selectedCircuit) ? "lock.fill" : "ticket.fill")
                Text(isLocked(selectedCircuit) ? "UNLOCK ALL CIRCUITS" : "ISSUE PADDOCK PASS")
                    .kerning(1.5)
            }
            .font(.telemetry(15, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.raceRed, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
    }
}
