import SwiftUI

/// Pass Studio: a direct-manipulation editor. In edit mode every part of the
/// pass wiggles and is tappable; tapping one zooms the pass to the top and
/// raises a panel to change that part's text, font, size, colour, and the
/// card's texture. Pro users unlock the holographic finish.
struct PassStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var store = PassThemeStore.shared
    @AppStorage("driverName") private var driverName = ""

    @State private var selectedPart: PassPart?

    private var isPro: Bool { StoreService.shared.hasFullAccess }

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
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Pass preview. When a part is selected it zooms into that
                    // part (anchored) and rises to the top; the editor rides up
                    // as a bottom sheet below it.
                    passViewport
                        .frame(height: 420)
                        .padding(.top, 8)

                    if selectedPart == nil {
                        Text("TAP ANY PART OF THE PASS TO EDIT IT")
                            .font(.gilroy(11, .bold))
                            .kerning(2)
                            .foregroundStyle(Theme.textTertiary)
                        proBadge
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Pass Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { store.reset() }
                        .font(.gilroy(14, .semiBold))
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.gilroy(15, .bold))
                        .foregroundStyle(Theme.raceRed)
                }
            }
            .sheet(item: $selectedPart) { part in
                PartEditorPanel(
                    part: part,
                    theme: $store.theme,
                    isPro: isPro
                )
                .presentationDetents([.height(380)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(380)))
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
        }
        .preferredColorScheme(.dark)
    }

    /// The pass inside a clipped viewport so zooming never spills over.
    private var passViewport: some View {
        PassCardView(
            model: sampleModel,
            stamped: true,
            themeOverride: store.theme,
            editing: true,
            selectedPart: selectedPart,
            onSelectPart: { part in
                withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                    selectedPart = part
                }
            }
        )
        .frame(width: 300)
        .scaleEffect(
            selectedPart == nil ? 1.0 : 1.85,
            anchor: PassStudioView.anchor(for: selectedPart)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    /// Approximate on-card position of each part, so zoom centres on it.
    static func anchor(for part: PassPart?) -> UnitPoint {
        switch part {
        case .bigPrint: return UnitPoint(x: 0.5, y: 0.42)
        case .script: return UnitPoint(x: 0.55, y: 0.52)
        case .year: return UnitPoint(x: 0.85, y: 0.18)
        case .detailsStrip: return UnitPoint(x: 0.5, y: 0.60)
        case .track: return UnitPoint(x: 0.22, y: 0.82)
        case .event: return UnitPoint(x: 0.55, y: 0.82)
        case .card, .none: return .center
        }
    }

    /// Radiant holographic "PRO GRID" badge.
    private var proBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: isPro ? "seal.fill" : "lock.fill")
                .font(.system(size: 11, weight: .bold))
            Text(isPro ? "PRO GRID MEMBER" : "PRO — UNLOCK HOLO")
                .font(.gilroy(11, .black))
                .kerning(1.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            ZStack {
                Capsule().fill(.black)
                HolographicSheen().clipShape(Capsule())
            }
        )
        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Editor panel

/// The bottom sheet that edits the currently-selected part.
struct PartEditorPanel: View {
    let part: PassPart
    @Binding var theme: PassTheme
    let isPro: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(part.title.uppercased())
                    .font(.gilroy(14, .black))
                    .kerning(2)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Theme.raceRed, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if part.editsText { textEditor }
                    if part.editsFontAndSize {
                        fontEditor
                        sizeEditor
                    }
                    colorEditor
                    if part == .card { textureEditor }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.card)
    }

    // MARK: Editors

    @ViewBuilder
    private var textEditor: some View {
        editorLabel("TEXT")
        TextField("", text: textBinding)
            .font(.gilroy(16, .semiBold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .autocorrectionDisabled()
    }

    @ViewBuilder
    private var fontEditor: some View {
        editorLabel("FONT")
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PassFont.allCases, id: \.self) { font in
                    let selected = fontBinding.wrappedValue == font
                    Button {
                        Haptics.impact(.light)
                        fontBinding.wrappedValue = font
                    } label: {
                        Text("Ag")
                            .font(font.font(20))
                            .frame(width: 52, height: 44)
                            .background(
                                selected ? Theme.raceRed.opacity(0.25) : .white.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(selected ? Theme.raceRed : .clear, lineWidth: 1.5)
                            )
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sizeEditor: some View {
        editorLabel("SIZE")
        Slider(value: sizeBinding, in: 0.6...1.4)
            .tint(Theme.raceRed)
    }

    @ViewBuilder
    private var colorEditor: some View {
        editorLabel("COLOUR")
        let binding = colorHexBinding
        HStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PassStudioPalette.all, id: \.self) { hex in
                        let selected = binding.wrappedValue.caseInsensitiveCompare(hex) == .orderedSame
                        Button {
                            Haptics.impact(.light)
                            binding.wrappedValue = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(
                                        selected ? .white : .white.opacity(0.15),
                                        lineWidth: selected ? 2.5 : 1
                                    )
                                )
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            ColorPicker("", selection: Binding(
                get: { Color(hex: binding.wrappedValue) },
                set: { binding.wrappedValue = $0.hexString() }
            ), supportsOpacity: false)
            .labelsHidden()
            .frame(width: 34)
        }
    }

    @ViewBuilder
    private var textureEditor: some View {
        editorLabel("TEXTURE")
        HStack(spacing: 8) {
            ForEach(PassTexture.allCases, id: \.self) { texture in
                let locked = texture == .holographic && !isPro
                let selected = theme.texture == texture
                Button {
                    guard !locked else { Haptics.warning(); return }
                    Haptics.impact(.light)
                    theme.texture = texture
                } label: {
                    VStack(spacing: 4) {
                        Text(texture.label)
                            .font(.gilroy(11, .bold))
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selected ? Theme.raceRed.opacity(0.25) : .white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(selected ? Theme.raceRed : .clear, lineWidth: 1.5)
                    )
                    .foregroundStyle(locked ? Theme.textTertiary : .white)
                }
            }
        }
    }

    private func editorLabel(_ text: String) -> some View {
        Text(text)
            .font(.gilroy(10, .bold))
            .kerning(2)
            .foregroundStyle(Theme.textTertiary)
    }

    // MARK: Bindings per part

    private var textBinding: Binding<String> {
        switch part {
        case .bigPrint: return $theme.roleText
        case .script: return $theme.scriptText
        case .year: return $theme.yearText
        case .event: return $theme.eventText
        default: return .constant("")
        }
    }

    private var fontBinding: Binding<PassFont> {
        part == .script ? $theme.scriptFont : $theme.roleFont
    }

    private var sizeBinding: Binding<Double> {
        part == .script ? $theme.scriptScale : $theme.roleScale
    }

    private var colorHexBinding: Binding<String> {
        switch part {
        case .card: return $theme.accentHex
        case .script: return $theme.foilHex
        case .track: return $theme.trackHex
        case .detailsStrip, .bigPrint, .year, .event: return $theme.inkHex
        }
    }
}

enum PassStudioPalette {
    static let all = [
        "FF8700", "E10A17", "1E5A46", "0A7E8C", "5D3FD3",
        "D9B45B", "E8E9EC", "17171A", "10182B", "F5F5F7",
    ]
}
