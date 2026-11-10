import SwiftUI
import SceneKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Blood Vessel Scene View (SwiftUI Bridge)
/// Bridges the high-performance procedural SceneKit engine into SwiftUI.
/// Supports both iOS/iPadOS (`UIViewRepresentable`) and macOS (`NSViewRepresentable`).
struct BloodVesselSceneView: View {
    @ObservedObject var viewModel: LabViewModel
    
    var body: some View {
        #if canImport(UIKit)
        BloodVesselSceneViewRepresentable(viewModel: viewModel)
        #elseif canImport(AppKit)
        BloodVesselSceneViewRepresentableMac(viewModel: viewModel)
        #endif
    }
}

// MARK: - iOS / iPadOS Implementation
#if canImport(UIKit)
struct BloodVesselSceneViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: LabViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(sceneController: VesselSceneController())
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let controller = context.coordinator.sceneController
        
        scnView.scene = controller.scene
        scnView.delegate = controller
        scnView.isPlaying = true
        scnView.loops = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = UIColor(red: 0.04, green: 0.01, blue: 0.02, alpha: 1.0)
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true // Allows 360-degree inspection for judges
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scnView.addGestureRecognizer(tapGesture)
        context.coordinator.scnView = scnView
        context.coordinator.viewModel = viewModel
        
        controller.update(with: viewModel)
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.viewModel = viewModel
        context.coordinator.sceneController.update(with: viewModel)
    }
    
    class Coordinator: NSObject {
        let sceneController: VesselSceneController
        weak var scnView: SCNView?
        var viewModel: LabViewModel?
        
        init(sceneController: VesselSceneController) {
            self.sceneController = sceneController
        }
        
        @MainActor
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView, let viewModel = viewModel else { return }
            let point = gesture.location(in: scnView)
            let hits = scnView.hitTest(point, options: [
                .ignoreHiddenNodes: true,
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ])
            
            // Filter out the surrounding vessel wall so hits match the first blood cell
            for hit in hits {
                switch hit.node.name {
                case "RBC":
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedCellType = .erythrocytes
                    }
                    return
                case "WBC":
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedCellType = .leukocytes
                    }
                    return
                case "PLT":
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedCellType = .platelets
                    }
                    return
                default:
                    continue
                }
            }
        }
    }
}
#endif

// MARK: - macOS Implementation (For Swift Playgrounds on Mac / Native macOS)
#if canImport(AppKit) && !canImport(UIKit)
struct BloodVesselSceneViewRepresentableMac: NSViewRepresentable {
    @ObservedObject var viewModel: LabViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(sceneController: VesselSceneController())
    }
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        let controller = context.coordinator.sceneController
        
        scnView.scene = controller.scene
        scnView.delegate = controller
        scnView.isPlaying = true
        scnView.loops = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = NSColor(red: 0.04, green: 0.01, blue: 0.02, alpha: 1.0)
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true
        
        let clickGesture = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleClick(_:))
        )
        scnView.addGestureRecognizer(clickGesture)
        context.coordinator.scnView = scnView
        context.coordinator.viewModel = viewModel
        
        controller.update(with: viewModel)
        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        context.coordinator.viewModel = viewModel
        context.coordinator.sceneController.update(with: viewModel)
    }
    
    class Coordinator: NSObject {
        let sceneController: VesselSceneController
        weak var scnView: SCNView?
        var viewModel: LabViewModel?
        
        init(sceneController: VesselSceneController) {
            self.sceneController = sceneController
        }
        
        @MainActor
        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let scnView = scnView, let viewModel = viewModel else { return }
            let point = gesture.location(in: scnView)
            let hits = scnView.hitTest(point, options: [
                .ignoreHiddenNodes: true,
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ])
            
            for hit in hits {
                switch hit.node.name {
                case "RBC":
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedCellType = .erythrocytes
                    }
                    return
                case "WBC":
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedCellType = .leukocytes
                    }
                    return
                case "PLT":
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedCellType = .platelets
                    }
                    return
                default:
                    continue
                }
            }
        }
    }
}
#endif
