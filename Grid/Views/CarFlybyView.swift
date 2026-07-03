import SwiftUI
import SceneKit
import UIKit

/// 3D flyby: a generic open-wheel car, tinted in the chosen team's livery,
/// crosses the lower third of the screen over the backdrop still. Replaces
/// pre-rendered video clips entirely. The SCNView only renders while a car
/// is on screen, so it costs nothing while the racing screen idles.
struct CarFlybySceneView: UIViewRepresentable {
    let trigger: Int
    let team: Team

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.antialiasingMode = .multisampling2X
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        view.isPlaying = false
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.applyLivery(team)
        if trigger != context.coordinator.lastTrigger {
            context.coordinator.lastTrigger = trigger
            context.coordinator.fire()
        }
    }

    func makeCoordinator() -> FlybyCarCoordinator { FlybyCarCoordinator() }
}

final class FlybyCarCoordinator {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    weak var view: SCNView?
    var lastTrigger = 0

    private let carA: SCNNode
    private let carB: SCNNode
    private let bodyMaterial: SCNMaterial
    private var liveryHex = ""

    /// Slow, frequent flybys for screenshot automation.
    private static var isUITest: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-uitest-flyby")
        #else
        return false
        #endif
    }

    init() {
        let camera = SCNCamera()
        camera.motionBlurIntensity = 1.0
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 1.3, 8.5)
        // Aim so the car crosses mid-screen, in the open band between the
        // header and the telemetry panel.
        cameraNode.look(at: SCNVector3(0, 0.9, 0))
        scene.rootNode.addChildNode(cameraNode)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1100
        sun.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 6, 0)
        scene.rootNode.addChildNode(sun)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 500
        scene.rootNode.addChildNode(ambient)

        let (car, body) = Self.buildCar()
        bodyMaterial = body
        carA = car
        carB = car.clone()
        carA.position = SCNVector3(100, 0, 0)
        carB.position = SCNVector3(100, 0, 0)
        scene.rootNode.addChildNode(carA)
        scene.rootNode.addChildNode(carB)
    }

    func applyLivery(_ team: Team) {
        guard team.accentHex != liveryHex else { return }
        liveryHex = team.accentHex
        bodyMaterial.diffuse.contents = UIColor(Color(hex: team.accentHex))
    }

    func fire() {
        guard let view else { return }
        view.isPlaying = true

        let leftToRight = Bool.random()
        let duration = Self.isUITest ? 2.2 : Double.random(in: 0.55...0.85)
        run(car: carA, leftToRight: leftToRight, duration: duration, delay: 0)

        // Occasionally a second car follows nose-to-tail.
        var total = duration
        if Double.random(in: 0...1) < 0.35 {
            let gap = Double.random(in: 0.18...0.3)
            run(car: carB, leftToRight: leftToRight, duration: duration, delay: gap)
            total += gap
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + total + 0.2) { [weak view] in
            view?.isPlaying = false
        }
    }

    private func run(car: SCNNode, leftToRight: Bool, duration: TimeInterval, delay: TimeInterval) {
        let startX: Float = leftToRight ? -13 : 13
        car.position = SCNVector3(startX, 0, Float.random(in: -2.8...(-1.2)))
        car.eulerAngles = SCNVector3(0, leftToRight ? 0 : Float.pi, 0)
        let end = SCNVector3(-startX, 0, car.position.z)
        car.runAction(.sequence([
            .wait(duration: delay),
            .move(to: end, duration: duration),
            .run { $0.position = SCNVector3(100, 0, 0) },
        ]))
    }

    /// Procedural generic open-wheel car — legally safe, ~zero asset cost.
    /// Swappable later for a proper .usdz under the same node.
    private static func buildCar() -> (SCNNode, SCNMaterial) {
        let car = SCNNode()

        let body = SCNMaterial()
        body.lightingModel = .physicallyBased
        body.diffuse.contents = UIColor.orange
        body.metalness.contents = 0.25
        body.roughness.contents = 0.35

        let carbon = SCNMaterial()
        carbon.lightingModel = .physicallyBased
        carbon.diffuse.contents = UIColor(white: 0.08, alpha: 1)
        carbon.roughness.contents = 0.55

        let tyre = SCNMaterial()
        tyre.diffuse.contents = UIColor(white: 0.05, alpha: 1)
        tyre.roughness.contents = 0.9

        @discardableResult
        func add(_ geometry: SCNGeometry, _ material: SCNMaterial,
                 _ position: SCNVector3, euler: SCNVector3 = SCNVector3(0, 0, 0)) -> SCNNode {
            geometry.materials = [material]
            let node = SCNNode(geometry: geometry)
            node.position = position
            node.eulerAngles = euler
            car.addChildNode(node)
            return node
        }

        // Car faces +x. Rough F1 proportions: ~5 units long, ~2 wide.
        // Main tub
        add(SCNBox(width: 2.4, height: 0.32, length: 0.62, chamferRadius: 0.06),
            body, SCNVector3(0, 0.34, 0))
        // Nose cone
        add(SCNCone(topRadius: 0.02, bottomRadius: 0.18, height: 1.15),
            body, SCNVector3(1.75, 0.32, 0), euler: SCNVector3(0, 0, -Float.pi / 2))
        // Cockpit + engine cover
        add(SCNBox(width: 1.0, height: 0.32, length: 0.5, chamferRadius: 0.1),
            body, SCNVector3(-0.25, 0.58, 0))
        // Roll hoop
        add(SCNBox(width: 0.22, height: 0.24, length: 0.3, chamferRadius: 0.05),
            carbon, SCNVector3(-0.45, 0.82, 0))
        // Sidepods
        add(SCNBox(width: 1.15, height: 0.3, length: 1.05, chamferRadius: 0.08),
            body, SCNVector3(-0.35, 0.3, 0))
        // Front wing
        add(SCNBox(width: 0.5, height: 0.05, length: 1.55, chamferRadius: 0.02),
            carbon, SCNVector3(2.15, 0.12, 0))
        // Rear wing
        add(SCNBox(width: 0.45, height: 0.06, length: 1.3, chamferRadius: 0.02),
            carbon, SCNVector3(-1.95, 0.78, 0))
        // Rear wing pylons
        add(SCNBox(width: 0.06, height: 0.5, length: 0.06, chamferRadius: 0),
            carbon, SCNVector3(-1.95, 0.5, 0))
        // Wheels (axles along z)
        let wheelPositions: [(Float, Float)] = [
            (1.35, 0.78), (1.35, -0.78), (-1.4, 0.82), (-1.4, -0.82),
        ]
        for (x, z) in wheelPositions {
            add(SCNCylinder(radius: 0.34, height: 0.32),
                tyre, SCNVector3(x, 0.34, z), euler: SCNVector3(Float.pi / 2, 0, 0))
        }
        // Soft shadow blob so the car sits on the backdrop instead of
        // floating over it.
        let blob = SCNCylinder(radius: 1.0, height: 0.01)
        let blobMaterial = SCNMaterial()
        blobMaterial.diffuse.contents = UIColor.black
        blobMaterial.transparency = 0.35
        blobMaterial.lightingModel = .constant
        blob.materials = [blobMaterial]
        let blobNode = SCNNode(geometry: blob)
        blobNode.position = SCNVector3(0, 0.005, 0)
        blobNode.scale = SCNVector3(2.3, 1, 0.95)
        car.addChildNode(blobNode)

        return (car, body)
    }
}
