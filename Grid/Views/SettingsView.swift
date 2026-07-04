import SwiftUI
import FamilyControls

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("driverName") private var driverName = ""
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("keepScreenAwake") private var keepScreenAwake = true
    @AppStorage("simulationMode") private var simulationMode = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("customDurationMinutes") private var customMinutes = 30
    #if DEBUG
    @AppStorage("debugFullAccess") private var debugFullAccess = true
    #endif

    @State private var showingActivityPicker = false
    @State private var showingPassStudio = false
    @State private var activitySelection = BlockingService.shared.selection
    @State private var restoring = false

    private let durationPresets = [15, 25, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    driverSection
                    customDurationSection
                    blockingSection
                    experienceSection
                    purchasesSection
                    developerSection
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.gilroy(15, .bold))
                        .foregroundStyle(Theme.raceRed)
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

    // MARK: - Sections

    private var driverSection: some View {
        SettingsCard(title: "DRIVER", icon: "person.fill") {
            HStack {
                Image(systemName: "signature")
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 26)
                TextField("Name on your pass", text: $driverName)
                    .font(.gilroy(15, .semiBold))
                    .autocorrectionDisabled()
            }
            .settingsRow()

            Button {
                Haptics.impact(.light)
                showingPassStudio = true
            } label: {
                SettingsRowLabel(icon: "paintbrush.fill", title: "Pass Studio",
                                 accessory: .disclosure)
            }
        }
    }

    private var customDurationSection: some View {
        SettingsCard(title: "CUSTOM DURATION", icon: "timer") {
            HStack {
                Text("\(customMinutes)")
                    .font(.gilroy(34, .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("MIN")
                    .font(.gilroy(13, .bold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Stepper("", value: $customMinutes, in: 5...180, step: 5)
                    .labelsHidden()
                    .tint(Theme.raceRed)
            }
            .settingsRow()

            // Quick-pick pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(durationPresets, id: \.self) { mins in
                        let selected = customMinutes == mins
                        Button {
                            Haptics.impact(.light)
                            withAnimation(.snappy) { customMinutes = mins }
                        } label: {
                            Text("\(mins)M")
                                .font(.gilroy(13, .bold))
                                .foregroundStyle(selected ? .white : Theme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selected ? Theme.raceRed : Color.white.opacity(0.06),
                                    in: Capsule()
                                )
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
    }

    private var blockingSection: some View {
        SettingsCard(title: "BLOCKING", icon: "shield.lefthalf.filled") {
            Button {
                Task {
                    await BlockingService.shared.requestAuthorizationIfNeeded()
                    showingActivityPicker = true
                }
            } label: {
                SettingsRowLabel(
                    icon: "shield.fill",
                    title: "Blocked apps",
                    accessory: .badge(BlockingService.shared.hasSelection ? "Configured" : "None")
                )
            }
            GridToggle(icon: "cpu.fill", title: "Simulation mode", isOn: $simulationMode)
        }
    }

    private var experienceSection: some View {
        SettingsCard(title: "EXPERIENCE", icon: "slider.horizontal.3") {
            GridToggle(icon: "speaker.wave.2.fill", title: "Sound effects", isOn: $soundEnabled)
            GridToggle(icon: "sun.max.fill", title: "Keep screen awake", isOn: $keepScreenAwake)
        }
    }

    private var purchasesSection: some View {
        SettingsCard(title: "PURCHASES", icon: "bag.fill") {
            Button {
                restoring = true
                Task {
                    await StoreService.shared.restorePurchases()
                    restoring = false
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Theme.raceRed)
                        .frame(width: 26)
                    Text("Restore purchases")
                        .font(.gilroy(15, .semiBold))
                        .foregroundStyle(.white)
                    Spacer()
                    if restoring { ProgressView().tint(Theme.raceRed) }
                }
                .settingsRow()
            }
        }
    }

    private var developerSection: some View {
        SettingsCard(title: "DEVELOPER", icon: "hammer.fill") {
            #if DEBUG
            HStack {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(Theme.raceRed)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Pro access")
                        .font(.gilroy(15, .semiBold))
                        .foregroundStyle(.white)
                    Text(debugFullAccess ? "Everything unlocked" : "Free tier — paywalls active")
                        .font(.gilroy(11, .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $debugFullAccess)
                    .labelsHidden()
                    .tint(Theme.raceRed)
            }
            .settingsRow()
            .onChange(of: debugFullAccess) { _, newValue in
                StoreService.shared.debugSetFullAccess(newValue)
            }
            #endif

            Button {
                Haptics.warning()
                hasCompletedOnboarding = false
                dismiss()
            } label: {
                SettingsRowLabel(icon: "arrow.counterclockwise",
                                 title: "Reset onboarding",
                                 tint: Theme.raceRed)
            }
        }
    }
}

// MARK: - Building blocks

/// A titled dark card holding grouped rows.
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.gilroy(11, .bold))
                    .kerning(2)
            }
            .foregroundStyle(Theme.textTertiary)
            .padding(.leading, 6)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

enum RowAccessory {
    case disclosure
    case badge(String)
    case none
}

struct SettingsRowLabel: View {
    let icon: String
    let title: String
    var accessory: RowAccessory = .disclosure
    var tint: Color = .white

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(tint == .white ? Theme.textSecondary : tint)
                .frame(width: 26)
            Text(title)
                .font(.gilroy(15, .semiBold))
                .foregroundStyle(tint)
            Spacer()
            switch accessory {
            case .disclosure:
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            case .badge(let text):
                Text(text)
                    .font(.gilroy(12, .semiBold))
                    .foregroundStyle(Theme.raceRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.raceRed.opacity(0.15), in: Capsule())
            case .none:
                EmptyView()
            }
        }
        .settingsRow()
    }
}

/// Red-tinted toggle row.
struct GridToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 26)
            Toggle(isOn: $isOn) {
                Text(title)
                    .font(.gilroy(15, .semiBold))
                    .foregroundStyle(.white)
            }
            .tint(Theme.raceRed)
        }
        .settingsRow()
    }
}

private struct SettingsRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.leading, 14)
            }
    }
}

extension View {
    func settingsRow() -> some View { modifier(SettingsRowModifier()) }
}
