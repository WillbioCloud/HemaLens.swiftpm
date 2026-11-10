import Foundation
import SceneKit
import CoreGraphics

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
#endif

// MARK: - Vessel Scene Controller
/// High-performance procedural SceneKit engine driving the 3D blood vessel simulation.
/// Uses strict Object Pooling with zero runtime node allocations to achieve 60 FPS.
/// Thread-safe synchronization between SwiftUI MainActor updates and SceneKit's render thread.
final class VesselSceneController: NSObject, SCNSceneRendererDelegate {
    // MARK: - Public Properties
    let scene = SCNScene()
    
    // MARK: - Scene Hierarchy Nodes
    private(set) var cameraNode = SCNNode()
    private(set) var vesselNode = SCNNode()
    private(set) var ambientLightNode = SCNNode()
    private(set) var directionalLightNode = SCNNode()
    private(set) var pointLightNode = SCNNode()
    private(set) var cytokineEmitterNode = SCNNode()
    
    // MARK: - Object Pools
    private let maxRBC = 80
    private let maxWBC = 28
    private let maxPLT = 60
    private let maxGlucose = 48
    private let maxFibrinStrands = 18
    
    private var rbcNodes: [SCNNode] = []
    private var wbcNodes: [SCNNode] = []
    private var pltNodes: [SCNNode] = []
    private var glucoseNodes: [SCNNode] = []
    private var fibrinNodes: [SCNNode] = []
    
    // MARK: - Dynamic Per-Cell Flow Metadata
    private struct CellDynamics {
        var radius: Float
        var angle: Float
        var axialZ: Float
        var spinSpeed: SCNVector3
        var orbitalSpeed: Float
        var flowSpeedBias: Float
    }
    
    private var rbcDynamics: [CellDynamics] = []
    private var wbcDynamics: [CellDynamics] = []
    private var pltDynamics: [CellDynamics] = []
    private var glucoseDynamics: [CellDynamics] = []
    
    // MARK: - Thread-Safe Simulation Snapshot
    private struct SimulationSnapshot: Equatable {
        var rbcNodeCount: Int = 45
        var wbcNodeCount: Int = 8
        var pltNodeCount: Int = 26
        var glucoseNodeCount: Int = 0
        var speedMultiplier: Float = 1.0
        var oxygenationFactor: Float = 1.0
        var hyperglycemiaIntensity: Float = 0.0
        var isImmuneResponseActive: Bool = false
        var cytokineIntensity: Float = 0.0
        var isClottingActive: Bool = false
        var fibrinIntensity: Float = 0.0
        var heartRateBPM: Int = 72
        var isPaused: Bool = false
        var selectedCellType: BloodCellType? = nil
    }
    
    private let stateLock = NSLock()
    private var pendingSnapshot = SimulationSnapshot()
    private var appliedSnapshot = SimulationSnapshot()
    private var hasPendingSnapshot = true
    
    // MARK: - Render Thread State
    private var currentSpeedMultiplier: Float = 1.0
    private var lastFrameTime: TimeInterval = 0.0
    
    // MARK: - Boundaries
    private let spawnZ: Float = -22.0
    private let despawnZ: Float = 8.5
    private let vesselRadius: Float = 3.35
    
    // MARK: - Materials Cache
    private var rbcMaterial = SCNMaterial()
    private var wbcMaterial = SCNMaterial()
    private var pltMaterial = SCNMaterial()
    private var glucoseMaterial = SCNMaterial()
    private var vesselMaterial = SCNMaterial()
    private var fibrinMaterial = SCNMaterial()
    
    // MARK: - Initialization
    override init() {
        super.init()
        buildScene()
    }
    
    // MARK: - Scene Construction
    private func buildScene() {
        setupMaterials()
        setupCamera()
        setupLighting()
        setupVesselTunnel()
        setupObjectPools()
        setupFibrinMesh()
        setupCytokineEmitter()
    }
    
    // MARK: - Procedural CoreGraphics Textures (Zero External Assets)
    private func createEndotheliumTexture() -> CGImage? {
        let size = 256
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        ctx.setFillColor(red: 0.45, green: 0.05, blue: 0.09, alpha: 0.92)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        
        for i in 0..<24 {
            let y = CGFloat(i) * (CGFloat(size) / 24.0)
            let shade = CGFloat(0.04 + Double((i % 3)) * 0.025)
            ctx.setFillColor(red: 0.35 + shade, green: 0.03, blue: 0.06, alpha: 0.55)
            ctx.fill(CGRect(x: 0, y: y, width: CGFloat(size), height: 4.0))
        }
        
        for _ in 0..<45 {
            let x = CGFloat.random(in: 0..<CGFloat(size))
            let y = CGFloat.random(in: 0..<CGFloat(size))
            let w = CGFloat.random(in: 14...36)
            let h = CGFloat.random(in: 8...18)
            ctx.setFillColor(red: 0.62, green: 0.10, blue: 0.14, alpha: 0.25)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: w, height: h))
        }
        
        return ctx.makeImage()
    }
    
    private func createLeukocyteBumpTexture() -> CGImage? {
        let size = 128
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        ctx.setFillColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        
        for _ in 0..<180 {
            let x = CGFloat.random(in: 0..<CGFloat(size))
            let y = CGFloat.random(in: 0..<CGFloat(size))
            let r = CGFloat.random(in: 3...9)
            ctx.setFillColor(red: 0.72, green: 0.72, blue: 1.0, alpha: 0.7)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
        }
        
        return ctx.makeImage()
    }
    
    /// Creates a soft radial circle particle image so SCNParticleSystem renders glowing orbs instead of white squares.
    private func createSoftCircleParticleImage() -> CGImage? {
        let size = 64
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        ctx.clear(CGRect(x: 0, y: 0, width: size, height: size))
        
        let colors = [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            CGColor(red: 0.55, green: 0.92, blue: 1.0, alpha: 0.55),
            CGColor(red: 0.25, green: 0.85, blue: 1.0, alpha: 0.0)
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.42, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
            return nil
        }
        
        let center = CGPoint(x: CGFloat(size) * 0.5, y: CGFloat(size) * 0.5)
        ctx.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0.0,
            endCenter: center,
            endRadius: CGFloat(size) * 0.5,
            options: .drawsAfterEndLocation
        )
        
        return ctx.makeImage()
    }
    
    // MARK: - Materials Configuration
    private func setupMaterials() {
        // RBC: Velvety biconcave disc appearance
        rbcMaterial.lightingModel = .physicallyBased
        rbcMaterial.diffuse.contents = PlatformColor(red: 0.85, green: 0.12, blue: 0.14, alpha: 1.0)
        rbcMaterial.roughness.contents = 0.48
        rbcMaterial.metalness.contents = 0.04
        
        // WBC: Pearlescent, textured microvilli immune sentry
        wbcMaterial.lightingModel = .physicallyBased
        wbcMaterial.diffuse.contents = PlatformColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 0.96)
        wbcMaterial.emission.contents = PlatformColor(red: 0.14, green: 0.24, blue: 0.42, alpha: 1.0)
        wbcMaterial.normal.contents = createLeukocyteBumpTexture()
        wbcMaterial.normal.intensity = 0.65
        wbcMaterial.roughness.contents = 0.35
        wbcMaterial.metalness.contents = 0.08
        
        // PLT: Deeper warm amber-gold biconvex fragments (high roughness avoids white specular blowout)
        pltMaterial.lightingModel = .physicallyBased
        pltMaterial.diffuse.contents = PlatformColor(red: 0.88, green: 0.62, blue: 0.12, alpha: 1.0)
        pltMaterial.roughness.contents = 0.55
        pltMaterial.metalness.contents = 0.05
        
        // Glucose Crystals: Translucent frosty-white sugar molecules in plasma
        glucoseMaterial.lightingModel = .physicallyBased
        glucoseMaterial.diffuse.contents = PlatformColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 0.62)
        glucoseMaterial.emission.contents = PlatformColor(red: 0.18, green: 0.28, blue: 0.26, alpha: 1.0)
        glucoseMaterial.roughness.contents = 0.22
        glucoseMaterial.metalness.contents = 0.10
        glucoseMaterial.transparencyMode = .dualLayer
        
        // Endothelial Wall: Translucent striated vascular tunnel
        vesselMaterial.lightingModel = .physicallyBased
        if let endoTex = createEndotheliumTexture() {
            vesselMaterial.diffuse.contents = endoTex
            vesselMaterial.diffuse.wrapS = .repeat
            vesselMaterial.diffuse.wrapT = .repeat
            vesselMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(4.0, 10.0, 1.0)
        } else {
            vesselMaterial.diffuse.contents = PlatformColor(red: 0.52, green: 0.07, blue: 0.11, alpha: 0.90)
        }
        vesselMaterial.multiply.contents = PlatformColor.white
        vesselMaterial.roughness.contents = 0.52
        vesselMaterial.metalness.contents = 0.05
        vesselMaterial.isDoubleSided = true
        vesselMaterial.cullMode = .front
        
        // Fibrin Strands: Amber-white protein mesh
        fibrinMaterial.lightingModel = .physicallyBased
        fibrinMaterial.diffuse.contents = PlatformColor(red: 0.95, green: 0.88, blue: 0.55, alpha: 0.80)
        fibrinMaterial.emission.contents = PlatformColor(red: 0.32, green: 0.26, blue: 0.10, alpha: 1.0)
        fibrinMaterial.roughness.contents = 0.38
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        let camera = SCNCamera()
        camera.zNear = 0.4
        camera.zFar = 65.0
        camera.fieldOfView = 62.0
        camera.motionBlurIntensity = 0.12
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0.0, y: 0.0, z: 7.2)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    // MARK: - Lighting Setup
    private func setupLighting() {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = PlatformColor(red: 0.45, green: 0.10, blue: 0.12, alpha: 1.0)
        ambientLight.intensity = 520.0
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = PlatformColor(red: 1.0, green: 0.92, blue: 0.90, alpha: 1.0)
        directionalLight.intensity = 780.0
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(x: 2.0, y: 4.0, z: 8.0)
        directionalLightNode.eulerAngles = SCNVector3(x: -Float.pi / 4, y: Float.pi / 6, z: 0.0)
        scene.rootNode.addChildNode(directionalLightNode)
        
        let pointLight = SCNLight()
        pointLight.type = .omni
        pointLight.color = PlatformColor(red: 0.95, green: 0.25, blue: 0.20, alpha: 1.0)
        pointLight.intensity = 650.0
        pointLight.attenuationStartDistance = 2.0
        pointLight.attenuationEndDistance = 22.0
        pointLightNode.light = pointLight
        pointLightNode.position = SCNVector3(x: 0.0, y: 0.0, z: -5.0)
        scene.rootNode.addChildNode(pointLightNode)
    }
    
    // MARK: - Vessel Tunnel
    private func setupVesselTunnel() {
        let cylinder = SCNCylinder(radius: CGFloat(vesselRadius), height: 40.0)
        cylinder.radialSegmentCount = 48
        cylinder.heightSegmentCount = 10
        cylinder.materials = [vesselMaterial]
        
        vesselNode.name = "VesselWall"
        vesselNode.geometry = cylinder
        vesselNode.eulerAngles = SCNVector3(x: Float.pi / 2, y: 0.0, z: 0.0)
        vesselNode.position = SCNVector3(x: 0.0, y: 0.0, z: -8.0)
        scene.rootNode.addChildNode(vesselNode)
    }
    
    // MARK: - Object Pools (Zero Allocation in Frame Loop)
    private func setupObjectPools() {
        // 1. Erythrocytes (RBC) Pool: True biconcave disc
        let rbcRimGeometry = SCNTorus(ringRadius: 0.24, pipeRadius: 0.145)
        rbcRimGeometry.ringSegmentCount = 24
        rbcRimGeometry.pipeSegmentCount = 12
        rbcRimGeometry.materials = [rbcMaterial]
        
        let rbcCenterGeometry = SCNSphere(radius: 0.23)
        rbcCenterGeometry.segmentCount = 14
        rbcCenterGeometry.materials = [rbcMaterial]
        
        for i in 0..<maxRBC {
            let parentNode = SCNNode()
            parentNode.name = "RBC"
            
            let rimNode = SCNNode(geometry: rbcRimGeometry)
            rimNode.name = "RBC"
            
            let centerNode = SCNNode(geometry: rbcCenterGeometry)
            centerNode.name = "RBC"
            centerNode.scale = SCNVector3(x: 1.0, y: 0.26, z: 1.0)
            
            parentNode.addChildNode(rimNode)
            parentNode.addChildNode(centerNode)
            
            let r = Float.random(in: 0.2...2.35)
            let theta = Float.random(in: 0...(Float.pi * 2))
            let z = spawnZ + (Float(i) / Float(maxRBC)) * (despawnZ - spawnZ)
            
            parentNode.position = SCNVector3(x: r * cos(theta), y: r * sin(theta), z: z)
            parentNode.eulerAngles = SCNVector3(
                x: Float.random(in: 0...(Float.pi * 2)),
                y: Float.random(in: 0...(Float.pi * 2)),
                z: Float.random(in: 0...(Float.pi * 2))
            )
            
            parentNode.isHidden = i >= appliedSnapshot.rbcNodeCount
            scene.rootNode.addChildNode(parentNode)
            rbcNodes.append(parentNode)
            
            rbcDynamics.append(CellDynamics(
                radius: r,
                angle: theta,
                axialZ: z,
                spinSpeed: SCNVector3(
                    x: Float.random(in: -1.3...1.3),
                    y: Float.random(in: -0.9...0.9),
                    z: Float.random(in: -1.1...1.1)
                ),
                orbitalSpeed: Float.random(in: -0.25...0.25),
                flowSpeedBias: Float.random(in: 0.90...1.15)
            ))
        }
        
        // 2. Leukocytes (WBC) Pool: Spherical textured sentinels rolling along endothelium
        let wbcGeometry = SCNSphere(radius: 0.72)
        wbcGeometry.segmentCount = 24
        wbcGeometry.materials = [wbcMaterial]
        
        for i in 0..<maxWBC {
            let node = SCNNode(geometry: wbcGeometry)
            node.name = "WBC"
            
            let r = Float.random(in: 1.95...2.75)
            let theta = Float.random(in: 0...(Float.pi * 2))
            let z = spawnZ + (Float(i) / Float(maxWBC)) * (despawnZ - spawnZ)
            
            node.position = SCNVector3(x: r * cos(theta), y: r * sin(theta), z: z)
            node.isHidden = i >= appliedSnapshot.wbcNodeCount
            scene.rootNode.addChildNode(node)
            wbcNodes.append(node)
            
            wbcDynamics.append(CellDynamics(
                radius: r,
                angle: theta,
                axialZ: z,
                spinSpeed: SCNVector3(
                    x: Float.random(in: -0.5...0.5),
                    y: Float.random(in: -0.5...0.5),
                    z: Float.random(in: -0.4...0.4)
                ),
                orbitalSpeed: Float.random(in: 0.15...0.45),
                flowSpeedBias: Float.random(in: 0.52...0.78)
            ))
        }
        
        // 3. Platelets (PLT) Pool: Organic flattened biconvex spheres (Fixes white box blowout)
        let pltGeometry = SCNSphere(radius: 0.14)
        pltGeometry.segmentCount = 16
        pltGeometry.materials = [pltMaterial]
        
        for i in 0..<maxPLT {
            let node = SCNNode(geometry: pltGeometry)
            node.name = "PLT"
            node.scale = SCNVector3(x: 1.0, y: 0.35, z: 0.85)
            
            let r = Float.random(in: 0.4...2.8)
            let theta = Float.random(in: 0...(Float.pi * 2))
            let z = spawnZ + (Float(i) / Float(maxPLT)) * (despawnZ - spawnZ)
            
            node.position = SCNVector3(x: r * cos(theta), y: r * sin(theta), z: z)
            node.isHidden = i >= appliedSnapshot.pltNodeCount
            scene.rootNode.addChildNode(node)
            pltNodes.append(node)
            
            pltDynamics.append(CellDynamics(
                radius: r,
                angle: theta,
                axialZ: z,
                spinSpeed: SCNVector3(
                    x: Float.random(in: -2.4...2.4),
                    y: Float.random(in: -1.9...1.9),
                    z: Float.random(in: -2.1...2.1)
                ),
                orbitalSpeed: Float.random(in: -0.4...0.4),
                flowSpeedBias: Float.random(in: 0.95...1.20)
            ))
        }
        
        // 4. Glucose Crystal Pool: Translucent bipyramid sugar crystals in plasma
        let topPyramid = SCNPyramid(width: 0.12, height: 0.10, length: 0.12)
        topPyramid.materials = [glucoseMaterial]
        let bottomPyramid = SCNPyramid(width: 0.12, height: 0.10, length: 0.12)
        bottomPyramid.materials = [glucoseMaterial]
        
        for i in 0..<maxGlucose {
            let crystalParent = SCNNode()
            crystalParent.name = "GLU"
            
            let topNode = SCNNode(geometry: topPyramid)
            topNode.name = "GLU"
            
            let bottomNode = SCNNode(geometry: bottomPyramid)
            bottomNode.name = "GLU"
            bottomNode.eulerAngles = SCNVector3(x: Float.pi, y: 0.0, z: 0.0)
            
            crystalParent.addChildNode(topNode)
            crystalParent.addChildNode(bottomNode)
            
            let r = Float.random(in: 0.15...2.85)
            let theta = Float.random(in: 0...(Float.pi * 2))
            let z = spawnZ + (Float(i) / Float(maxGlucose)) * (despawnZ - spawnZ)
            
            crystalParent.position = SCNVector3(x: r * cos(theta), y: r * sin(theta), z: z)
            crystalParent.isHidden = i >= appliedSnapshot.glucoseNodeCount
            scene.rootNode.addChildNode(crystalParent)
            glucoseNodes.append(crystalParent)
            
            glucoseDynamics.append(CellDynamics(
                radius: r,
                angle: theta,
                axialZ: z,
                spinSpeed: SCNVector3(
                    x: Float.random(in: -1.8...1.8),
                    y: Float.random(in: -2.2...2.2),
                    z: Float.random(in: -1.5...1.5)
                ),
                orbitalSpeed: Float.random(in: -0.35...0.35),
                flowSpeedBias: Float.random(in: 0.78...1.05)
            ))
        }
    }
    
    // MARK: - Fibrin Mesh Strands (Thrombosis Risk)
    private func setupFibrinMesh() {
        let strandGeometry = SCNCylinder(radius: 0.018, height: 1.0)
        strandGeometry.radialSegmentCount = 6
        strandGeometry.materials = [fibrinMaterial]
        
        for _ in 0..<maxFibrinStrands {
            let strandNode = SCNNode(geometry: strandGeometry)
            strandNode.name = "Fibrin"
            strandNode.isHidden = true
            scene.rootNode.addChildNode(strandNode)
            fibrinNodes.append(strandNode)
        }
    }
    
    // MARK: - Procedural Cytokine Emitter (Soft Radial Circle Texture)
    private func setupCytokineEmitter() {
        let particles = SCNParticleSystem()
        particles.birthRate = 0.0
        particles.particleLifeSpan = 1.4
        particles.particleSize = 0.14
        particles.particleColor = PlatformColor(red: 0.35, green: 0.88, blue: 1.0, alpha: 0.85)
        particles.blendMode = .additive
        particles.emitterShape = SCNSphere(radius: 1.9)
        particles.spreadingAngle = 180.0
        particles.speedFactor = 1.15
        particles.acceleration = SCNVector3(x: 0.0, y: 0.0, z: 2.0)
        
        if let cgCircle = createSoftCircleParticleImage() {
            #if canImport(UIKit)
            particles.particleImage = PlatformImage(cgImage: cgCircle)
            #elseif canImport(AppKit)
            particles.particleImage = PlatformImage(cgImage: cgCircle, size: NSSize(width: 64, height: 64))
            #endif
        }
        
        cytokineEmitterNode.position = SCNVector3(x: 0.0, y: 0.0, z: -2.0)
        cytokineEmitterNode.addParticleSystem(particles)
        scene.rootNode.addChildNode(cytokineEmitterNode)
    }
    
    // MARK: - Thread-Safe State Push from MainActor ViewModel
    @MainActor
    func update(with viewModel: LabViewModel) {
        let snapshot = SimulationSnapshot(
            rbcNodeCount: Swift.min(maxRBC, viewModel.targetRBCNodeCount),
            wbcNodeCount: Swift.min(maxWBC, viewModel.targetWBCNodeCount),
            pltNodeCount: Swift.min(maxPLT, viewModel.targetPLTNodeCount),
            glucoseNodeCount: Swift.min(maxGlucose, viewModel.targetGlucoseNodeCount),
            speedMultiplier: viewModel.bloodFlowSpeedMultiplier,
            oxygenationFactor: viewModel.oxygenationGlowFactor,
            hyperglycemiaIntensity: viewModel.hyperglycemiaIntensity,
            isImmuneResponseActive: viewModel.isImmuneResponseActive,
            cytokineIntensity: viewModel.cytokineParticleIntensity,
            isClottingActive: viewModel.isClottingRiskActive,
            fibrinIntensity: viewModel.fibrinMeshIntensity,
            heartRateBPM: viewModel.heartRateBPM,
            isPaused: viewModel.isSimulationPaused,
            selectedCellType: viewModel.selectedCellType
        )
        
        stateLock.lock()
        if snapshot != pendingSnapshot {
            pendingSnapshot = snapshot
            hasPendingSnapshot = true
        }
        stateLock.unlock()
    }
    
    // MARK: - Apply Visual Snapshot on Render Thread
    private func applySnapshotIfNeeded() -> SimulationSnapshot {
        stateLock.lock()
        let needsApply = hasPendingSnapshot
        let snapshot = pendingSnapshot
        if needsApply {
            hasPendingSnapshot = false
        }
        stateLock.unlock()
        
        guard needsApply else { return appliedSnapshot }
        appliedSnapshot = snapshot
        
        // 1. Update cell & crystal visibility
        for i in 0..<maxRBC {
            rbcNodes[i].isHidden = i >= snapshot.rbcNodeCount
        }
        for i in 0..<maxWBC {
            wbcNodes[i].isHidden = i >= snapshot.wbcNodeCount
        }
        for i in 0..<maxPLT {
            pltNodes[i].isHidden = i >= snapshot.pltNodeCount
        }
        for i in 0..<maxGlucose {
            glucoseNodes[i].isHidden = i >= snapshot.glucoseNodeCount
        }
        
        // 2. Oxygenation lumen color modulation
        let redComponent = CGFloat(0.50 + (0.36 * snapshot.oxygenationFactor))
        let greenComponent = CGFloat(0.08 + (0.16 * (1.0 - snapshot.oxygenationFactor)))
        let blueComponent = CGFloat(0.10 + (0.16 * (1.0 - snapshot.oxygenationFactor)))
        
        rbcMaterial.diffuse.contents = PlatformColor(
            red: redComponent,
            green: greenComponent,
            blue: blueComponent,
            alpha: 1.0
        )
        
        ambientLightNode.light?.color = PlatformColor(
            red: CGFloat(0.32 + (0.25 * snapshot.oxygenationFactor)),
            green: CGFloat(0.06 + (0.08 * (1.0 - snapshot.oxygenationFactor))),
            blue: CGFloat(0.08 + (0.08 * (1.0 - snapshot.oxygenationFactor))),
            alpha: 1.0
        )
        
        // 3. Endothelial glycation / oxidative stress darkening during hyperglycemia
        let glycationDarken = CGFloat(1.0 - (0.58 * snapshot.hyperglycemiaIntensity))
        vesselMaterial.multiply.contents = PlatformColor(
            red: glycationDarken,
            green: glycationDarken * 0.85,
            blue: glycationDarken * 0.85,
            alpha: 1.0
        )
        
        // 4. Highlight selected lineage if inspected
        rbcMaterial.emission.contents = snapshot.selectedCellType == .erythrocytes
            ? PlatformColor(red: 0.38, green: 0.05, blue: 0.05, alpha: 1.0)
            : PlatformColor.black
            
        wbcMaterial.emission.contents = snapshot.selectedCellType == .leukocytes
            ? PlatformColor(red: 0.25, green: 0.65, blue: 0.90, alpha: 1.0)
            : PlatformColor(red: 0.14, green: 0.24, blue: 0.42, alpha: 1.0)
            
        pltMaterial.emission.contents = snapshot.selectedCellType == .platelets
            ? PlatformColor(red: 0.45, green: 0.30, blue: 0.04, alpha: 1.0)
            : PlatformColor.black
            
        glucoseMaterial.emission.contents = snapshot.selectedCellType == .glucose
            ? PlatformColor(red: 0.30, green: 0.65, blue: 0.55, alpha: 1.0)
            : PlatformColor(red: 0.18, green: 0.28, blue: 0.26, alpha: 1.0)
        
        // 5. Cytokine emitter intensity
        if let emitter = cytokineEmitterNode.particleSystems?.first {
            emitter.birthRate = snapshot.isImmuneResponseActive
                ? CGFloat(45.0 * snapshot.cytokineIntensity + 12.0)
                : 0.0
        }
        
        // 6. Hide fibrin strands if clotting is inactive
        if !snapshot.isClottingActive {
            for strand in fibrinNodes {
                strand.isHidden = true
            }
        }
        
        return snapshot
    }
    
    // MARK: - SCNSceneRendererDelegate (60 FPS Render Loop)
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let state = applySnapshotIfNeeded()
        
        if lastFrameTime == 0.0 {
            lastFrameTime = time
            return
        }
        
        let delta = Float(time - lastFrameTime)
        lastFrameTime = time
        
        guard delta > 0.0, delta < 0.2, !state.isPaused else { return }
        
        currentSpeedMultiplier += (state.speedMultiplier - currentSpeedMultiplier) * Swift.min(1.0, delta * 3.5)
        let baseVelocity: Float = 6.2 * currentSpeedMultiplier
        
        // 1. Animate Erythrocytes
        for i in 0..<state.rbcNodeCount {
            var dyn = rbcDynamics[i]
            let node = rbcNodes[i]
            
            dyn.axialZ += baseVelocity * dyn.flowSpeedBias * delta
            if dyn.axialZ > despawnZ {
                dyn.axialZ = spawnZ + Float.random(in: 0.0...1.5)
                dyn.angle = Float.random(in: 0...(Float.pi * 2))
                dyn.radius = Float.random(in: 0.2...2.35)
            }
            
            dyn.angle += dyn.orbitalSpeed * delta
            node.position = SCNVector3(x: dyn.radius * cos(dyn.angle), y: dyn.radius * sin(dyn.angle), z: dyn.axialZ)
            node.eulerAngles.x += dyn.spinSpeed.x * delta
            node.eulerAngles.y += dyn.spinSpeed.y * delta
            node.eulerAngles.z += dyn.spinSpeed.z * delta
            
            rbcDynamics[i] = dyn
        }
        
        // 2. Animate Leukocytes (Endothelial Margination & Rolling)
        for i in 0..<state.wbcNodeCount {
            var dyn = wbcDynamics[i]
            let node = wbcNodes[i]
            
            dyn.axialZ += baseVelocity * dyn.flowSpeedBias * delta
            if dyn.axialZ > despawnZ {
                dyn.axialZ = spawnZ + Float.random(in: 0.0...2.0)
                dyn.angle = Float.random(in: 0...(Float.pi * 2))
            }
            
            dyn.angle += dyn.orbitalSpeed * delta
            node.position = SCNVector3(x: dyn.radius * cos(dyn.angle), y: dyn.radius * sin(dyn.angle), z: dyn.axialZ)
            node.eulerAngles.x += dyn.spinSpeed.x * delta
            node.eulerAngles.y += dyn.spinSpeed.y * delta
            
            wbcDynamics[i] = dyn
        }
        
        // 3. Animate Platelets
        for i in 0..<state.pltNodeCount {
            var dyn = pltDynamics[i]
            let node = pltNodes[i]
            
            if state.isClottingActive && i > 3 {
                let leadDyn = pltDynamics[i % 4]
                dyn.radius += (leadDyn.radius - dyn.radius) * delta * 0.85
            }
            
            dyn.axialZ += baseVelocity * dyn.flowSpeedBias * delta
            if dyn.axialZ > despawnZ {
                dyn.axialZ = spawnZ + Float.random(in: 0.0...1.2)
                dyn.angle = Float.random(in: 0...(Float.pi * 2))
                dyn.radius = Float.random(in: 0.4...2.8)
            }
            
            dyn.angle += dyn.orbitalSpeed * delta
            node.position = SCNVector3(x: dyn.radius * cos(dyn.angle), y: dyn.radius * sin(dyn.angle), z: dyn.axialZ)
            node.eulerAngles.x += dyn.spinSpeed.x * delta
            node.eulerAngles.y += dyn.spinSpeed.y * delta
            node.eulerAngles.z += dyn.spinSpeed.z * delta
            
            pltDynamics[i] = dyn
        }
        
        // 4. Animate Glucose Crystals (Hyperglycemia > 140 mg/dL)
        for i in 0..<state.glucoseNodeCount {
            var dyn = glucoseDynamics[i]
            let node = glucoseNodes[i]
            
            dyn.axialZ += baseVelocity * dyn.flowSpeedBias * delta
            if dyn.axialZ > despawnZ {
                dyn.axialZ = spawnZ + Float.random(in: 0.0...1.8)
                dyn.angle = Float.random(in: 0...(Float.pi * 2))
                dyn.radius = Float.random(in: 0.15...2.85)
            }
            
            dyn.angle += dyn.orbitalSpeed * delta
            node.position = SCNVector3(x: dyn.radius * cos(dyn.angle), y: dyn.radius * sin(dyn.angle), z: dyn.axialZ)
            node.eulerAngles.x += dyn.spinSpeed.x * delta
            node.eulerAngles.y += dyn.spinSpeed.y * delta
            node.eulerAngles.z += dyn.spinSpeed.z * delta
            
            glucoseDynamics[i] = dyn
        }
        
        // 5. Update Oriented Fibrin Strands bridging close platelets
        if state.isClottingActive && state.pltNodeCount >= 3 {
            let activeStrands = Int(Float(maxFibrinStrands) * state.fibrinIntensity)
            for s in 0..<maxFibrinStrands {
                let strandNode = fibrinNodes[s]
                guard s < activeStrands else {
                    strandNode.isHidden = true
                    continue
                }
                
                let p1Index = s % state.pltNodeCount
                let p2Index = (s + 2) % state.pltNodeCount
                let pos1 = pltNodes[p1Index].position
                let pos2 = pltNodes[p2Index].position
                
                let dx = pos2.x - pos1.x
                let dy = pos2.y - pos1.y
                let dz = pos2.z - pos1.z
                let dist = sqrt(dx * dx + dy * dy + dz * dz)
                
                guard dist > 0.08 && dist < 3.6 else {
                    strandNode.isHidden = true
                    continue
                }
                
                strandNode.isHidden = false
                strandNode.position = SCNVector3(
                    x: (pos1.x + pos2.x) * 0.5,
                    y: (pos1.y + pos2.y) * 0.5,
                    z: (pos1.z + pos2.z) * 0.5
                )
                strandNode.scale = SCNVector3(x: 1.0, y: dist, z: 1.0)
                strandNode.look(
                    at: pos2,
                    up: SCNVector3(x: 0.0, y: 0.0, z: 1.0),
                    localFront: SCNVector3(x: 0.0, y: 1.0, z: 0.0)
                )
            }
        }
        
        // 6. Physiological Arterial Pulse Oscillation
        let pulseFreq = Float(state.heartRateBPM) / 60.0 * Float.pi * 2.0
        let pulseAmplitude: Float = 0.042
        let pulseOffset = sin(Float(time) * pulseFreq) * pulseAmplitude
        vesselNode.scale = SCNVector3(
            x: 1.0 + pulseOffset,
            y: 1.0 + pulseOffset,
            z: 1.0
        )
    }
}
