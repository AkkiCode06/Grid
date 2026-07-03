import SwiftUI
import FamilyControls

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("driverName") private var driverName = ""
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("keepScreenAwake") private var keepScreenAwake = true
    @AppStorage("simulationMode") private var simulationMode = true

    @State private var showingActivityPicker = false
    @State private var showingPassStudio = false
    @State private var activitySelection = BlockingService.shared.selection
    @State private var restoring = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Driver") {
                    TextField("Name on your pass", text: $driverName)
                        .autocorrectionDisabled()
                    Button {
                        showingPassStudio = true
                    } label: {
                        Label("Pass Studio", systemImage: "paintbrush.fill")
                    }
                }

                Section {
                    Button {
                        Task {
                            await BlockingService.shared.requestAuthorizationIfNeeded()
                            showingActivityPicker = true
                        }
                    } label: {
                        HStack {
                            Label("Blocked apps", systemImage: "shield.fill")
                            Spacer()
                            Text(BlockingService.shared.hasSelection ? "Configured" : "None")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle("Simulation mode", isOn: $simulationMode)
                } header: {
                    Text("Blocking")
                } footer: {
                    Text("Simulation mode runs the full session flow without applying a real Screen Time shield — for testing while the FamilyControls entitlement is pending.")
                }

                Section("Experience") {
                    Toggle("Sound effects", isOn: $soundEnabled)
                    Toggle("Keep screen awake during sessions", isOn: $keepScreenAwake)
                }

                Section("Purchases") {
                    Button {
                        restoring = true
                        Task {
                            await StoreService.shared.restorePurchases()
                            restoring = false
                        }
                    } label: {
                        if restoring {
                            ProgressView()
                        } else {
                            Text("Restore purchases")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPassStudio) { PassStudioView() }
            .familyActivityPicker(
                isPresented: $showingActivityPicker,
                selection: $activitySelection
            )
            .onChange(of: showingActivityPicker) { _, isPresented in
                if !isPresented {
                    BlockingService.shared.selection = activitySelection
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
