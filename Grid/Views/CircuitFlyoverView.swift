import SwiftUI
import MapKit
import UIKit

/// Photorealistic "drone flyby" of the real circuit: MapKit's satellite
/// flyover (Apple's 3D photogrammetry) with the camera flying continuously
/// along the actual circuit polyline from CircuitGeo. Supports two modes:
/// - **Circuit**: Low-altitude chase along the track (existing behaviour).
/// - **City**: High-altitude orbit around the circuit's centre.
///
/// The two modes alternate with smooth animated camera transitions for a
/// "circuit → city → circuit" feel. Supports pause/resume for pit stops.
struct CircuitFlyoverView: UIViewRepresentable {
    let circuitID: String
    /// When true the camera freezes (pit stop). When false it resumes.
    var isPaused: Bool = false
    /// When true, alternate between circuit and city camera. Otherwise circuit only.
    var dualMode: Bool = false

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.mapType = .satelliteFlyover
        map.isUserInteractionEnabled = false
        map.showsCompass = false
        map.pointOfInterestFilter = .excludingAll
        map.isPitchEnabled = true
        context.coordinator.start(on: map, circuitID: circuitID, dualMode: dualMode)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let coord = context.coordinator
        // Handle circuit switch
        if coord.currentCircuitID != circuitID {
            coord.switchCircuit(on: uiView, circuitID: circuitID, dualMode: dualMode)
        }
        // Handle pause/resume
        if isPaused && !coord.isPaused {
            coord.pause()
        } else if !isPaused && coord.isPaused {
            coord.resume()
        }
    }

    func makeCoordinator() -> FlyoverCoordinator { FlyoverCoordinator() }

    static func dismantleUIView(_ uiView: MKMapView, coordinator: FlyoverCoordinator) {
        coordinator.stop()
    }
}

final class FlyoverCoordinator {
    private weak var map: MKMapView?
    private var coords: [CLLocationCoordinate2D] = []
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var pauseTime: CFTimeInterval = 0
    private var pauseOffset: CFTimeInterval = 0
    private(set) var isPaused = false
    private(set) var currentCircuitID: String = ""
    private var dualMode: Bool = false

    /// How long to fly one full circuit lap.
    private let loopDuration: Double = 150
    /// How long the city orbit lasts before switching back to circuit.
    private let cityDuration: Double = 20
    /// Total cycle = circuit segment + city segment.
    private let cycleDuration: Double = 40 // 20s circuit, 20s city

    private let circuitAltitude: CLLocationDistance = 550
    private let circuitPitch: CGFloat = 58
    private let cityAltitude: CLLocationDistance = 3000
    private let cityPitch: CGFloat = 45

    private var cityCenter: CLLocationCoordinate2D = CLLocationCoordinate2D()

    enum FlyoverMode {
        case circuit
        case city
    }

    func start(on map: MKMapView, circuitID: String, dualMode: Bool) {
        guard let coords = CircuitGeo.coordinates(for: circuitID), coords.count > 2 else { return }
        self.map = map
        self.coords = coords
        self.currentCircuitID = circuitID
        self.dualMode = dualMode
        self.cityCenter = centroid(of: coords)
        map.camera = circuitCamera(atLoopFraction: 0)

        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30, preferred: 30)
        link.add(to: .main, forMode: .common)
        displayLink = link
        startTime = CACurrentMediaTime()
        pauseOffset = 0
    }

    func switchCircuit(on map: MKMapView, circuitID: String, dualMode: Bool) {
        guard let newCoords = CircuitGeo.coordinates(for: circuitID), newCoords.count > 2 else { return }
        self.coords = newCoords
        self.currentCircuitID = circuitID
        self.dualMode = dualMode
        self.cityCenter = centroid(of: newCoords)
        // Smooth transition to new circuit's starting position
        let newCamera = circuitCamera(atLoopFraction: 0)
        UIView.animate(withDuration: 1.2) {
            map.camera = newCamera
        }
        startTime = CACurrentMediaTime()
        pauseOffset = 0
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func pause() {
        isPaused = true
        pauseTime = CACurrentMediaTime()
        displayLink?.isPaused = true
    }

    func resume() {
        isPaused = false
        // Account for time spent paused so the camera doesn't jump
        pauseOffset += CACurrentMediaTime() - pauseTime
        displayLink?.isPaused = false
    }

    @objc private func tick() {
        let elapsed = CACurrentMediaTime() - startTime - pauseOffset

        if dualMode {
            // Cycle between circuit and city
            let cyclePosition = elapsed.truncatingRemainder(dividingBy: cycleDuration)
            let halfCycle = cycleDuration / 2

            if cyclePosition < halfCycle {
                // Circuit mode
                let circuitFraction = (elapsed / loopDuration).truncatingRemainder(dividingBy: 1)
                map?.camera = circuitCamera(atLoopFraction: circuitFraction)
            } else {
                // City orbit mode
                let cityElapsed = cyclePosition - halfCycle
                let cityFraction = cityElapsed / halfCycle
                map?.camera = cityCamera(atOrbitFraction: cityFraction, elapsed: elapsed)
            }
        } else {
            let fraction = (elapsed / loopDuration).truncatingRemainder(dividingBy: 1)
            map?.camera = circuitCamera(atLoopFraction: fraction)
        }
    }

    private func circuitCamera(atLoopFraction fraction: Double) -> MKMapCamera {
        let position = interpolated(at: fraction)
        let lookAhead = interpolated(at: fraction + 0.02)
        return MKMapCamera(
            lookingAtCenter: lookAhead,
            fromDistance: circuitAltitude,
            pitch: circuitPitch,
            heading: bearing(from: position, to: lookAhead)
        )
    }

    private func cityCamera(atOrbitFraction fraction: Double, elapsed: Double) -> MKMapCamera {
        let heading = (elapsed * 12).truncatingRemainder(dividingBy: 360) // Slow rotation
        return MKMapCamera(
            lookingAtCenter: cityCenter,
            fromDistance: cityAltitude,
            pitch: cityPitch,
            heading: heading
        )
    }

    private func centroid(of coords: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        let lat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let lon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func interpolated(at fraction: Double) -> CLLocationCoordinate2D {
        let wrapped = fraction - fraction.rounded(.down)
        let scaled = wrapped * Double(coords.count)
        let index = Int(scaled) % coords.count
        let next = (index + 1) % coords.count
        let t = scaled - scaled.rounded(.down)
        let a = coords[index]
        let b = coords[next]
        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * t,
            longitude: a.longitude + (b.longitude - a.longitude) * t
        )
    }

    private func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let deltaLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let degrees = atan2(y, x) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }
}
