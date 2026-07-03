import SwiftUI

/// Pass Studio: live-preview editor for the user's paddock pass. Wording,
/// colours, and printed details are all customisable; the card format and
/// the circuits stay on-theme.
struct PassStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var store = PassThemeStore.shared
    @AppStorage("driverName") private var driverName = ""

    private var sampleModel: PassCardModel {
        let circuit = CircuitLibrary.all[0]
        let pass = PassDetails(
            driverName: driverName.isEmpty ? "DRIVER" : driverName,
            circuit: circuit,
            team: TeamLibrary.all[0],
            issuedAt: .now,
            sessionNumber: SharedStore.nextSessionNumber,
            durationSeconds: circuit.duration(customMinutes: 30)
        )
        return PassCardModel(pass: pass)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PassCardView(
                        model: sampleModel,
                        stamped: true,
                        themeOverride: store.theme
                    )
                    .padding(.horizontal, 36)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section("Wording") {
                    LabeledContent("Big print") {
                        TextField("VIP", text: $store.theme.roleText)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Flourish") {
                        TextField("Guest", text: $store.theme.scriptText)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Year") {
                        TextField(PassTheme.currentYear, text: $store.theme.yearText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    LabeledContent("Event line") {
                        TextField("Event", text: $store.theme.eventText)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Driver name") {
                        TextField("Your name", text: $driverName)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Card colour") {
                    SwatchRow(selection: $store.theme.accentHex,
                              options: PassThemeStore.accentPresets)
                    ColorPicker("Custom", selection: colorBinding(\.accentHex),
                                supportsOpacity: false)
                }

                Section("Print colour") {
                    SwatchRow(selection: $store.theme.inkHex,
                              options: PassThemeStore.inkPresets)
                    ColorPicker("Custom", selection: colorBinding(\.inkHex),
                                supportsOpacity: false)
                }

                Section("Flourish colour") {
                    SwatchRow(selection: $store.theme.foilHex,
                              options: PassThemeStore.foilPresets)
                    ColorPicker("Custom", selection: colorBinding(\.foilHex),
                                supportsOpacity: false)
                }

                Section("Printed details") {
                    Picker("Date & time", selection: $store.theme.dateStyle) {
                        ForEach(PassDateStyle.allCases, id: \.self) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    Toggle("Session number", isOn: $store.theme.showSessionNumber)
                    Toggle("Track outline", isOn: $store.theme.showTrackOutline)
                    Toggle("Barcode", isOn: $store.theme.showBarcode)
                }

                Section {
                    Button("Reset to papaya", role: .destructive) {
                        store.reset()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Pass Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func colorBinding(_ keyPath: WritableKeyPath<PassTheme, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: store.theme[keyPath: keyPath]) },
            set: { store.theme[keyPath: keyPath] = $0.hexString() }
        )
    }
}

/// Horizontal row of preset colour swatches.
struct SwatchRow: View {
    @Binding var selection: String
    let options: [(String, String)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(options, id: \.1) { name, hex in
                    let isSelected = selection.caseInsensitiveCompare(hex) == .orderedSame
                    Button {
                        Haptics.impact(.light)
                        selection = hex
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(
                                        isSelected ? Color.white : Color.white.opacity(0.15),
                                        lineWidth: isSelected ? 2.5 : 1
                                    )
                                )
                            Text(name)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
