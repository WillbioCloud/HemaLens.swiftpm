import Foundation
import SceneKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Human Body 3D Scene Controller (Macro View)
/// Procedural translucent glass medical hologram mannequin with dynamic internal organs
/// responding in real time to hematology and glycemic conditions.
final class HumanBodySceneController: NSObject, SCNSceneRendererDelegate {
    // MARK: - Public Scene
    let scene = SCNScene()
    
    // MARK: - Nodes
    private(set) var cameraNode = SCNNode()
    private(set) var bodyRootNode = SCNNode()
    private(set) var brainNode = SCNNode()
    private(set) var lungsNode = SCNNode()
    private(set) var heartNode = SCNNode()
    private(set) var liverSpleenNode = SCNNode()
    private(set) var boneMarrowNode = SCNNode()
    
    // MARK: - Materials
    private var glassBodyMaterial = SCNMaterial()
    private var vesselLineMaterial = SCNMaterial()
    private var brainMaterial = SCNMaterial()
    private var lungsMaterial = SCNMaterial()
    private var heartMaterial = SCNMaterial()
    private var liverSpleenMaterial = SCNMaterial()
    private var boneMarrowMaterial = SCNMaterial()
    
    // MARK: - Thread-Safe Snapshot
    private struct BodySnapshot: Equatable {
        var condition: ClinicalCondition = .homeostasis
        var heartRateBPM: Int = 72
        var isPaused: Bool = false
        var selectedOrgan: TargetOrgan? = nil
    }
    
    private let stateLock = NSLock()
    private var pendingSnapshot = BodySnapshot()
    private var currentSnapshot = BodySnapshot()
    
    override init() {
        super.init()
        buildScene()
    }
    
    // MARK: - Scene Assembly
    private func buildScene() {
        setupMaterials()
        setupCamera()
        setupLighting()
        setupGlassMannequin()
        setupVascularNetwork()
        setupInternalOrgans()
        scene.rootNode.addChildNode(bodyRootNode)
    }
    
    private func setupMaterials() {
        // Translucent frosted glass hologram body (writesToDepthBuffer = false lets organs shine clearly)
        glassBodyMaterial.lightingModel = .physicallyBased
        glassBodyMaterial.diffuse.contents = PlatformColor(red: 0.35, green: 0.80, blue: 0.98, alpha: 0.16)
        glassBodyMaterial.emission.contents = PlatformColor(red: 0.05, green: 0.16, blue: 0.28, alpha: 1.0)
        glassBodyMaterial.roughness.contents = 0.15
        glassBodyMaterial.metalness.contents = 0.05
        glassBodyMaterial.transparencyMode = .dualLayer
        glassBodyMaterial.writesToDepthBuffer = false
        glassBodyMaterial.isDoubleSided = true
        
        vesselLineMaterial.lightingModel = .physicallyBased
        vesselLineMaterial.diffuse.contents = PlatformColor(red: 0.85, green: 0.18, blue: 0.22, alpha: 0.45)
        vesselLineMaterial.emission.contents = PlatformColor(red: 0.35, green: 0.05, blue: 0.08, alpha: 1.0)
        vesselLineMaterial.writesToDepthBuffer = false
        
        configureOrganMaterial(brainMaterial, baseColor: PlatformColor(red: 0.55, green: 0.72, blue: 0.98, alpha: 0.94))
        configureOrganMaterial(lungsMaterial, baseColor: PlatformColor(red: 0.82, green: 0.48, blue: 0.58, alpha: 0.88))
        configureOrganMaterial(heartMaterial, baseColor: PlatformColor(red: 0.88, green: 0.16, blue: 0.20, alpha: 0.98))
        configureOrganMaterial(liverSpleenMaterial, baseColor: PlatformColor(red: 0.68, green: 0.28, blue: 0.25, alpha: 0.92))
        configureOrganMaterial(boneMarrowMaterial, baseColor: PlatformColor(red: 0.95, green: 0.65, blue: 0.25, alpha: 0.92))
    }
    
    private func configureOrganMaterial(_ material: SCNMaterial, baseColor: PlatformColor) {
        material.lightingModel = .physicallyBased
        material.diffuse.contents = baseColor
        material.roughness.contents = 0.32
        material.metalness.contents = 0.06
    }
    
    private func setupCamera() {
        let camera = SCNCamera()
        camera.zNear = 0.2
        camera.zFar = 40.0
        camera.fieldOfView = 45.0
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0.0, y: 0.35, z: 7.4)
        cameraNode.look(at: SCNVector3(x: 0.0, y: 0.25, z: 0.0))
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLighting() {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = PlatformColor(red: 0.65, green: 0.78, blue: 0.92, alpha: 1.0)
        ambient.intensity = 520.0
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
        
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.color = PlatformColor.white
        keyLight.intensity = 820.0
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(x: 3.0, y: 5.0, z: 6.0)
        keyNode.look(at: SCNVector3(x: 0.0, y: 0.0, z: 0.0))
        scene.rootNode.addChildNode(keyNode)
        
        let rimLight = SCNLight()
        rimLight.type = .omni
        rimLight.color = PlatformColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 1.0)
        rimLight.intensity = 600.0
        let rimNode = SCNNode()
        rimNode.light = rimLight
        rimNode.position = SCNVector3(x: -3.5, y: 1.5, z: -3.5)
        scene.rootNode.addChildNode(rimNode)
    }
    
    // MARK: - Stylized Glass Mannequin Geometry
    private func setupGlassMannequin() {
        // Head
        let head = SCNSphere(radius: 0.44)
        head.materials = [glassBodyMaterial]
        let headNode = SCNNode(geometry: head)
        headNode.name = "BodyShell"
        headNode.scale = SCNVector3(x: 0.92, y: 1.12, z: 1.0)
        headNode.position = SCNVector3(x: 0.0, y: 2.38, z: 0.0)
        bodyRootNode.addChildNode(headNode)
        
        // Neck
        let neck = SCNCylinder(radius: 0.17, height: 0.45)
        neck.materials = [glassBodyMaterial]
        let neckNode = SCNNode(geometry: neck)
        neckNode.name = "BodyShell"
        neckNode.position = SCNVector3(x: 0.0, y: 1.85, z: 0.0)
        bodyRootNode.addChildNode(neckNode)
        
        // Torso
        let torso = SCNCapsule(capRadius: 0.72, height: 2.35)
        torso.materials = [glassBodyMaterial]
        let torsoNode = SCNNode(geometry: torso)
        torsoNode.name = "BodyShell"
        torsoNode.scale = SCNVector3(x: 1.14, y: 1.0, z: 0.62)
        torsoNode.position = SCNVector3(x: 0.0, y: 0.78, z: 0.0)
        bodyRootNode.addChildNode(torsoNode)
        
        // Arms (Left & Right)
        for side: Float in [-1.0, 1.0] {
            let arm = SCNCapsule(capRadius: 0.17, height: 1.95)
            arm.materials = [glassBodyMaterial]
            let armNode = SCNNode(geometry: arm)
            armNode.name = "BodyShell"
            armNode.position = SCNVector3(x: side * 1.05, y: 0.76, z: 0.0)
            armNode.eulerAngles = SCNVector3(x: 0.0, y: 0.0, z: side * 0.16)
            bodyRootNode.addChildNode(armNode)
        }
        
        // Legs / Thighs (Housing Femur Bone Marrow)
        for side: Float in [-1.0, 1.0] {
            let leg = SCNCapsule(capRadius: 0.25, height: 2.35)
            leg.materials = [glassBodyMaterial]
            let legNode = SCNNode(geometry: leg)
            legNode.name = "BodyShell"
            legNode.position = SCNVector3(x: side * 0.36, y: -1.25, z: 0.0)
            bodyRootNode.addChildNode(legNode)
        }
    }
    
    // MARK: - Subtle Vascular Vessels
    private func setupVascularNetwork() {
        // Descending Aorta & Carotid Axis
        let aorta = SCNCylinder(radius: 0.035, height: 2.4)
        aorta.materials = [vesselLineMaterial]
        let aortaNode = SCNNode(geometry: aorta)
        aortaNode.name = "BodyShell"
        aortaNode.position = SCNVector3(x: 0.0, y: 1.05, z: 0.02)
        bodyRootNode.addChildNode(aortaNode)
        
        // Femoral Arteries
        for side: Float in [-1.0, 1.0] {
            let femoral = SCNCylinder(radius: 0.025, height: 1.8)
            femoral.materials = [vesselLineMaterial]
            let femNode = SCNNode(geometry: femoral)
            femNode.name = "BodyShell"
            femNode.position = SCNVector3(x: side * 0.22, y: -0.95, z: 0.05)
            femNode.eulerAngles = SCNVector3(x: 0.0, y: 0.0, z: side * -0.10)
            bodyRootNode.addChildNode(femNode)
        }
    }
    
    // MARK: - Internal Target Organs (Tap-to-Inspect)
    private func setupInternalOrgans() {
        // 1. Brain (Dual Cerebral Hemispheres)
        brainNode.name = TargetOrgan.brain.rawValue
        let hemiGeo = SCNSphere(radius: 0.22)
        hemiGeo.materials = [brainMaterial]
        for side: Float in [-1.0, 1.0] {
            let hemi = SCNNode(geometry: hemiGeo)
            hemi.name = TargetOrgan.brain.rawValue
            hemi.scale = SCNVector3(x: 0.88, y: 0.85, z: 1.18)
            hemi.position = SCNVector3(x: side * 0.13, y: 2.42, z: 0.0)
            brainNode.addChildNode(hemi)
        }
        bodyRootNode.addChildNode(brainNode)
        
        // 2. Lungs (Left & Right Lobes)
        lungsNode.name = TargetOrgan.lungs.rawValue
        let lungGeo = SCNCapsule(capRadius: 0.22, height: 0.82)
        lungGeo.materials = [lungsMaterial]
        for side: Float in [-1.0, 1.0] {
            let lobe = SCNNode(geometry: lungGeo)
            lobe.name = TargetOrgan.lungs.rawValue
            lobe.scale = SCNVector3(x: 0.95, y: 1.0, z: 0.78)
            lobe.position = SCNVector3(x: side * 0.34, y: 1.24, z: -0.04)
            lobe.eulerAngles = SCNVector3(x: 0.0, y: 0.0, z: side * -0.10)
            lungsNode.addChildNode(lobe)
        }
        bodyRootNode.addChildNode(lungsNode)
        
        // 3. Heart (Centrally Anchored, Tilted Slightly Left)
        heartNode.name = TargetOrgan.heart.rawValue
        heartNode.position = SCNVector3(x: 0.10, y: 1.15, z: 0.14)
        let heartGeo = SCNSphere(radius: 0.23)
        heartGeo.materials = [heartMaterial]
        let heartBody = SCNNode(geometry: heartGeo)
        heartBody.name = TargetOrgan.heart.rawValue
        heartBody.scale = SCNVector3(x: 0.92, y: 1.18, z: 0.88)
        heartBody.eulerAngles = SCNVector3(x: 0.0, y: 0.0, z: -0.35)
        heartNode.addChildNode(heartBody)
        bodyRootNode.addChildNode(heartNode)
        
        // 4. Liver & Spleen (Abdominal Filtration Axis)
        liverSpleenNode.name = TargetOrgan.liverSpleen.rawValue
        let liverGeo = SCNCapsule(capRadius: 0.21, height: 0.65)
        liverGeo.materials = [liverSpleenMaterial]
        let liver = SCNNode(geometry: liverGeo)
        liver.name = TargetOrgan.liverSpleen.rawValue
        liver.position = SCNVector3(x: -0.25, y: 0.56, z: 0.08)
        liver.eulerAngles = SCNVector3(x: 0.0, y: 0.0, z: 1.25)
        liverSpleenNode.addChildNode(liver)
        
        let spleenGeo = SCNSphere(radius: 0.14)
        spleenGeo.materials = [liverSpleenMaterial]
        let spleen = SCNNode(geometry: spleenGeo)
        spleen.name = TargetOrgan.liverSpleen.rawValue
        spleen.scale = SCNVector3(x: 0.9, y: 1.2, z: 0.8)
        spleen.position = SCNVector3(x: 0.42, y: 0.58, z: 0.02)
        liverSpleenNode.addChildNode(spleen)
        bodyRootNode.addChildNode(liverSpleenNode)
        
        // 5. Bone Marrow (Sternum + Bilateral Femurs)
        boneMarrowNode.name = TargetOrgan.boneMarrow.rawValue
        let sternumGeo = SCNCapsule(capRadius: 0.055, height: 0.55)
        sternumGeo.materials = [boneMarrowMaterial]
        let sternum = SCNNode(geometry: sternumGeo)
        sternum.name = TargetOrgan.boneMarrow.rawValue
        sternum.position = SCNVector3(x: 0.0, y: 1.24, z: 0.24)
        boneMarrowNode.addChildNode(sternum)
        
        let femurGeo = SCNCapsule(capRadius: 0.075, height: 1.35)
        femurGeo.materials = [boneMarrowMaterial]
        for side: Float in [-1.0, 1.0] {
            let femur = SCNNode(geometry: femurGeo)
            femur.name = TargetOrgan.boneMarrow.rawValue
            femur.position = SCNVector3(x: side * 0.36, y: -1.18, z: 0.0)
            boneMarrowNode.addChildNode(femur)
        }
        bodyRootNode.addChildNode(boneMarrowNode)
    }
    
    // MARK: - Thread-Safe Update from ViewModel
    @MainActor
    func update(with viewModel: LabViewModel) {
        let snapshot = BodySnapshot(
            condition: viewModel.currentCondition,
            heartRateBPM: viewModel.heartRateBPM,
            isPaused: viewModel.isSimulationPaused,
            selectedOrgan: viewModel.selectedOrgan
        )
        stateLock.lock()
        pendingSnapshot = snapshot
        stateLock.unlock()
    }
    
    // MARK: - 60 FPS Render Loop (Organ Pulsing & Condition Alerting)
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        stateLock.lock()
        currentSnapshot = pendingSnapshot
        stateLock.unlock()
        
        let state = currentSnapshot
        if state.isPaused { return }
        
        // Gentle hologram turntable sway
        bodyRootNode.eulerAngles.y = Float(sin(time * 0.35)) * 0.14
        
        // 1. Heart Beat Animation (Exact heartRateBPM)
        let beatFreq = Float(state.heartRateBPM) / 60.0
        let beatPhase = Float(time) * beatFreq * Float.pi * 2.0
        let systolePulse = powf(Swift.max(0.0, sin(beatPhase)), 4.0) * 0.16
        let heartScale: Float = 1.0 + systolePulse
        heartNode.scale = SCNVector3(x: heartScale, y: heartScale, z: heartScale)
        
        // 2. Lung Respiratory Expansion (Faster during hypoxia)
        let isHypoxic = state.condition == .anemia || state.condition == .pancytopenia || state.condition == .thrombosisRisk
        let breathRate: Float = isHypoxic ? 2.2 : 1.15
        let breathAmp: Float = isHypoxic ? 0.065 : 0.035
        let breathScale: Float = 1.0 + sin(Float(time) * breathRate) * breathAmp
        lungsNode.scale = SCNVector3(x: breathScale, y: 1.0 + (breathScale - 1.0) * 0.5, z: breathScale)
        
        // 3. Alert Pulse Envelope (0.0 ... 1.0)
        let alertPulse = Float(sin(time * 5.0) * 0.5 + 0.5)
        applyOrganConditionGlows(condition: state.condition, selected: state.selectedOrgan, pulse: alertPulse)
    }
    
    private func applyOrganConditionGlows(condition: ClinicalCondition, selected: TargetOrgan?, pulse: Float) {
        let p = CGFloat(pulse)
        
        // Default healthy baselines
        var brainColor = PlatformColor(red: 0.45, green: 0.72, blue: 0.98, alpha: 0.94)
        var brainEmit = PlatformColor(red: 0.08, green: 0.18, blue: 0.35, alpha: 1.0)
        
        var lungsColor = PlatformColor(red: 0.85, green: 0.48, blue: 0.58, alpha: 0.88)
        var lungsEmit = PlatformColor(red: 0.14, green: 0.06, blue: 0.10, alpha: 1.0)
        
        var heartColor = PlatformColor(red: 0.90, green: 0.16, blue: 0.22, alpha: 0.98)
        var heartEmit = PlatformColor(red: 0.25, green: 0.03, blue: 0.05, alpha: 1.0)
        
        var liverColor = PlatformColor(red: 0.72, green: 0.30, blue: 0.24, alpha: 0.92)
        var liverEmit = PlatformColor(red: 0.12, green: 0.04, blue: 0.03, alpha: 1.0)
        
        var marrowColor = PlatformColor(red: 0.95, green: 0.65, blue: 0.25, alpha: 0.92)
        var marrowEmit = PlatformColor(red: 0.20, green: 0.12, blue: 0.02, alpha: 1.0)
        
        switch condition {
        case .homeostasis:
            break
            
        case .anemia:
            // Hypoxia alert flashing in Brain & Lungs + Tachycardia glow in Heart
            brainColor = PlatformColor(red: 0.95, green: 0.45, blue: 0.25, alpha: 0.96)
            brainEmit = PlatformColor(red: 0.55 * p, green: 0.18 * p, blue: 0.05, alpha: 1.0)
            lungsColor = PlatformColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 0.92)
            lungsEmit = PlatformColor(red: 0.55 * p, green: 0.10 * p, blue: 0.10 * p, alpha: 1.0)
            heartEmit = PlatformColor(red: 0.45, green: 0.12, blue: 0.05, alpha: 1.0)
            
        case .polycythemia:
            // Heavy hyperviscous congestion across Heart, Brain & Liver/Spleen
            heartColor = PlatformColor(red: 0.65, green: 0.05, blue: 0.12, alpha: 1.0)
            heartEmit = PlatformColor(red: 0.50 * p, green: 0.02, blue: 0.06, alpha: 1.0)
            brainEmit = PlatformColor(red: 0.40 * p, green: 0.08, blue: 0.10, alpha: 1.0)
            liverEmit = PlatformColor(red: 0.35, green: 0.06, blue: 0.06, alpha: 1.0)
            
        case .infectionResponse:
            // Bone Marrow & Spleen surging with electric cyan leukocyte production
            marrowColor = PlatformColor(red: 0.35, green: 0.90, blue: 1.0, alpha: 0.98)
            marrowEmit = PlatformColor(red: 0.15, green: 0.55 + 0.35 * p, blue: 0.85, alpha: 1.0)
            liverColor = PlatformColor(red: 0.35, green: 0.72, blue: 0.88, alpha: 0.94)
            liverEmit = PlatformColor(red: 0.10, green: 0.35 * p, blue: 0.55 * p, alpha: 1.0)
            
        case .leukopenia:
            // Dimmed, suppressed bone marrow
            marrowColor = PlatformColor(red: 0.42, green: 0.38, blue: 0.35, alpha: 0.78)
            marrowEmit = PlatformColor(red: 0.30 * p, green: 0.12 * p, blue: 0.02, alpha: 1.0)
            
        case .thrombocytopenia:
            // Spleen & Marrow bleeding risk alert
            liverEmit = PlatformColor(red: 0.50 * p, green: 0.22 * p, blue: 0.05, alpha: 1.0)
            marrowEmit = PlatformColor(red: 0.45 * p, green: 0.18 * p, blue: 0.02, alpha: 1.0)
            
        case .thrombosisRisk:
            // Critical clotting hazard flashing in Heart, Lungs & Brain
            heartEmit = PlatformColor(red: 0.80 * p, green: 0.08, blue: 0.05, alpha: 1.0)
            lungsEmit = PlatformColor(red: 0.75 * p, green: 0.08, blue: 0.08, alpha: 1.0)
            brainEmit = PlatformColor(red: 0.70 * p, green: 0.12, blue: 0.05, alpha: 1.0)
            
        case .hyperglycemia:
            // Oxidative glycation stress across vessels, Brain, Heart & Liver
            brainEmit = PlatformColor(red: 0.45 * p, green: 0.32 * p, blue: 0.08, alpha: 1.0)
            heartEmit = PlatformColor(red: 0.42, green: 0.22, blue: 0.05, alpha: 1.0)
            liverColor = PlatformColor(red: 0.85, green: 0.52, blue: 0.20, alpha: 0.94)
            liverEmit = PlatformColor(red: 0.38 * p, green: 0.22 * p, blue: 0.05, alpha: 1.0)
            
        case .hypoglycemia:
            // Urgent acute neuroglycopenia alarm in Brain
            brainColor = PlatformColor(red: 1.0, green: 0.82, blue: 0.20, alpha: 0.98)
            brainEmit = PlatformColor(red: 0.85 * p, green: 0.45 * p, blue: 0.05, alpha: 1.0)
            heartEmit = PlatformColor(red: 0.50 * p, green: 0.15, blue: 0.05, alpha: 1.0)
            
        case .pancytopenia:
            // Critical tri-lineage failure across Marrow, Brain, Lungs, Heart
            marrowColor = PlatformColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 0.92)
            marrowEmit = PlatformColor(red: 0.80 * p, green: 0.10 * p, blue: 0.10 * p, alpha: 1.0)
            brainEmit = PlatformColor(red: 0.55 * p, green: 0.15 * p, blue: 0.10, alpha: 1.0)
            lungsEmit = PlatformColor(red: 0.55 * p, green: 0.15 * p, blue: 0.15 * p, alpha: 1.0)
            heartEmit = PlatformColor(red: 0.50 * p, green: 0.12, blue: 0.12, alpha: 1.0)
        }
        
        // Selection highlight boost
        if selected == .brain { brainEmit = PlatformColor(red: 0.35, green: 0.65, blue: 1.0, alpha: 1.0) }
        if selected == .lungs { lungsEmit = PlatformColor(red: 0.35, green: 0.70, blue: 0.95, alpha: 1.0) }
        if selected == .heart { heartEmit = PlatformColor(red: 0.85, green: 0.25, blue: 0.35, alpha: 1.0) }
        if selected == .liverSpleen { liverEmit = PlatformColor(red: 0.70, green: 0.45, blue: 0.20, alpha: 1.0) }
        if selected == .boneMarrow { marrowEmit = PlatformColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 1.0) }
        
        brainMaterial.diffuse.contents = brainColor
        brainMaterial.emission.contents = brainEmit
        
        lungsMaterial.diffuse.contents = lungsColor
        lungsMaterial.emission.contents = lungsEmit
        
        heartMaterial.diffuse.contents = heartColor
        heartMaterial.emission.contents = heartEmit
        
        liverSpleenMaterial.diffuse.contents = liverColor
        liverSpleenMaterial.emission.contents = liverEmit
        
        boneMarrowMaterial.diffuse.contents = marrowColor
        boneMarrowMaterial.emission.contents = marrowEmit
    }
}
