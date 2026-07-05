import SwiftUI
import SwiftData
import PhotosUI

/// The driver's home base: avatar, quick stats, a way back to the Grid Pass,
/// and an entry into Settings. Replaces the bare gear icon in the paddock
/// header with a proper profile hub.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RaceRecord.startDate, order: .reverse) private var records: [RaceRecord]

    @AppStorage("driverName") private var driverName = ""
    @AppStorage("selectedTeamID") private var selectedTeamID = TeamLibrary.all[0].id

    @State private var showingSettings = false
    @State private var showingPass = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var pfpImage: UIImage?
    @State private var paywallLock: PaywallLock?

    private var isPro: Bool { StoreService.shared.hasFullAccess }

    private var finishedSessions: Int {
        records.filter { $0.result == .finished }.count
    }

    private var team: Team {
        TeamLibrary.team(id: selectedTeamID) ?? TeamLibrary.all[0]
    }

    private var displayName: String {
        driverName.trimmingCharacters(in: .whitespaces).isEmpty ? "Driver" : driverName
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    passButton
                    liverySection
                    statsSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.impact(.light)
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.gilroy(16, .bold))
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.gilroy(15, .bold))
                        .foregroundStyle(Theme.raceRed)
                }
            }
            .onAppear { pfpImage = ProfileImageStore.load() }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        let saved = ProfileImageStore.save(image)
                        await MainActor.run {
                            pfpImage = saved
                            Haptics.success()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .fullScreenCover(isPresented: $showingPass) {
                GridPassViewer(driverName: displayName,
                               finishedSessions: finishedSessions) { showingPass = false }
            }
            .fullScreenCover(item: $paywallLock) { lock in
                OnboardingPaywallView(
                    onSubscribe: {
                        paywallLock = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showingPass = true
                        }
                    },
                    onClose: { paywallLock = nil },
                    lock: lock
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                avatar
            }

            VStack(spacing: 3) {
                Text(displayName)
                    .font(.gilroy(24, .heavy))
                    .foregroundStyle(.white)
                Text("\(team.name.uppercased()) • #\(team.carNumber)")
                    .font(.gilroy(12, .bold))
                    .kerning(1)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var avatar: some View {
        ZStack {
            if let pfpImage {
                Image(uiImage: pfpImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 2))
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: team.accentHex),
                                     Color(hex: team.accentHex).opacity(0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 2))
                    .shadow(color: Color(hex: team.accentHex).opacity(0.5), radius: 12, y: 4)
                Text(initials)
                    .font(.gilroy(34, .black))
                    .foregroundStyle(Color(hex: team.inkHex))
            }

            // Camera badge to signal it's tappable.
            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(7)
                .background(Theme.raceRed, in: Circle())
                .overlay(Circle().strokeBorder(Theme.background, lineWidth: 2))
                .offset(x: 34, y: 34)
        }
    }

    // MARK: - Grid Pass

    private var passButton: some View {
        Button {
            Haptics.impact(.medium)
            if isPro {
                showingPass = true
            } else {
                paywallLock = .proCard
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isPro ? "person.text.rectangle.fill" : "lock.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.raceRed)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Grid Pass")
                        .font(.gilroy(16, .bold))
                        .foregroundStyle(.white)
                    Text(isPro ? "View your membership card" : "Go Pro to claim your 3D card")
                        .font(.gilroy(12, .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.raceRed.opacity(0.35), lineWidth: 1)
            )
        }
    }

    // MARK: - Livery

    private var liverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR LIVERY")
                .font(.gilroy(12, .bold)).kerning(2)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TeamLibrary.all) { t in
                        liveryChip(t)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func liveryChip(_ t: Team) -> some View {
        let selected = t.id == selectedTeamID
        let locked = t.isPro && !isPro
        return Button {
            Haptics.impact(.light)
            if locked {
                paywallLock = .livery(t)
            } else {
                selectedTeamID = t.id
                PassThemeStore.shared.applyTeam(t)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: t.accentHex), Color(hex: t.accentHex).opacity(0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .overlay(Circle().strokeBorder(
                            selected ? .white : .white.opacity(0.15),
                            lineWidth: selected ? 2.5 : 1))
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Color(hex: t.inkHex))
                    } else {
                        Text(t.threeLetterCode)
                            .font(.gilroy(13, .black))
                            .foregroundStyle(Color(hex: t.inkHex))
                    }
                }
                Text(t.isPro ? "PRO" : t.name.split(separator: " ").first.map(String.init) ?? t.name)
                    .font(.gilroy(9, .bold))
                    .foregroundStyle(selected ? .white : Theme.textTertiary)
                    .lineLimit(1)
            }
            .frame(width: 62)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR STATS")
                .font(.gilroy(12, .bold))
                .kerning(2)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 4)
            StatsView(records: records)
        }
    }
}

/// Full-screen viewer for the Grid Pro membership pass, reachable from Profile.
private struct GridPassViewer: View {
    let driverName: String
    var finishedSessions: Int = 0
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                GridProPassView(driverName: driverName, finishedSessions: finishedSessions)
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 40)
                Text("TAP TO FLIP · TILT TO SHINE")
                    .font(.gilroy(11, .bold))
                    .kerning(2)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Button {
                    Haptics.impact(.light)
                    onClose()
                } label: {
                    Text("CLOSE")
                        .font(.gilroy(14, .bold))
                        .kerning(1.5)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.08), in: Capsule())
                }
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { MotionTilt.shared.start() }
        .onDisappear { MotionTilt.shared.stop() }
    }
}
