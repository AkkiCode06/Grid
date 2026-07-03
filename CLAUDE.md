# Grid

iOS focus/app-blocker themed as attending an F1 race weekend. User picks a
circuit (sets session duration) + grandstand seat, commits via a stamped
"paddock pass", watches a five-light start, then their chosen apps are
shielded (Screen Time API) for the session. Progress is shown as laps.
Early quit is allowed but stamped DNF. SwiftUI, iOS 17+, dark theme only.

## Targets

- **Grid** — the app. Sources under `Grid/` (synchronized group: new files
  are picked up automatically, no pbxproj edits needed).
- **GridMonitor** — DeviceActivityMonitor extension; backstop that lifts the
  shield via `intervalDidEnd` if the app is killed mid-session.
- **GridWidgets** — WidgetKit extension hosting the race Live Activity.
- **Shared/** — compiled into all three targets (`SharedConstants.swift`,
  `RaceActivityAttributes.swift`). App Group: `group.Akki.Grid`.

## Build / run

```sh
xcodebuild -project Grid.xcodeproj -scheme Grid \
  -destination 'generic/platform=iOS Simulator' build
```

Launch: install `Grid.app` from DerivedData with `xcrun simctl install`,
bundle id `Akki.Grid`.

## Architecture notes

- State machine in `SessionController`: idle → passIssued → lightsSequence →
  racing → ended(finished|dnf) → idle. Active sessions persist to the App
  Group as `ActiveSessionSnapshot`; `restoreOnLaunch()` resumes or finalises
  after app kill.
- **Simulation mode** (`simulationMode` UserDefaults key, default ON): the
  whole flow runs without touching FamilyControls — the distribution
  entitlement (`com.apple.developer.family-controls`) is still pending with
  Apple. Flip the default in `AppConfig.simulationModeDefault` once granted.
- DeviceActivity schedules require ≥15 min intervals; `BlockingService`
  clamps the backstop accordingly (the app itself lifts the shield on time).
- Asset resolution goes through `AssetResolver`; real 9:16 backdrops and
  flyby .mp4 clips drop in later under the names declared on each `Seat`
  (`<circuitID>_<seatID>_backdrop`, `<circuitID>_<seatID>_flyby<n>`). Until
  then views fall back to gradient backdrops and a streak-flyby placeholder.
- Race Log is SwiftData (`RaceRecord`).
- StoreKit 2 one-time unlock, product id in `AppConfig`
  (`com.akki.grid.unlock.full`); free tier = Monte Carlo + Midlands.

## Legal constraint

No F1/Formula 1 logos, team/driver names, or official circuit branding.
Circuit display names are invented-but-obvious and data-driven in
`CircuitLibrary` ("Monte Carlo Street Circuit", "Ardennes GP", ...). Keep
generated assets to generic open-wheel silhouettes.

## Gotchas

- The app target builds with `MemberImportVisibility`: import every module
  whose members you use (e.g. `import StoreKit` where `displayPrice` is read).
- App target uses default MainActor isolation (Xcode 26 defaults); the two
  extension targets use nonisolated defaults.
- When poking app-group UserDefaults on the simulator from outside the app,
  the sim's cfprefsd caches domains — shut the simulator down before editing
  the plist under `data/Containers/Shared/AppGroup/<uuid>/Library/Preferences/`.
