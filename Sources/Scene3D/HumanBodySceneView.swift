import SwiftUI
import SceneKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Human Body 3D Scene View (Macro View Bridge)
struct HumanBodySceneView: View {
    @ObservedObject var viewModel: LabViewModel
    
    var body: some View {
        #if canImport(UIKit)
        HumanBodySceneViewRepresentable(viewModel: viewModel)
        #elseif canImport(AppKit)
        HumanBodySceneViewRepresentableMac(viewModel: viewModel)
        #endif
    }
}

#if canImport(UIKit)
struct HumanBodySceneViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: LabViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: HumanBodySceneController())
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let controller = context.coordinator.controller
        
        scnView.scene = controller.scene
        scnView.delegate = controller
        scnView.isPlaying = true
        scnView.loops = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = UIColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0)
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true
        
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
        context.coordinator.controller.update(with: viewModel)
    }
    
    class Coordinator: NSObject {
        let controller: HumanBodySceneController
        weak var scnView: SCNView?
        var viewModel: LabViewModel?
        
        init(controller: HumanBodySceneController) {
            self.controller = controller
        }
        
        @MainActor
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView, let viewModel = viewModel else { return }
            let point = gesture.location(in: scnView)
            let hits = scnView.hitTest(point, options: [
                .ignoreHiddenNodes: true,
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ])
            
            for hit in hits {
                if let name = hit.node.name,
                   let organ = TargetOrgan(rawValue: name) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedOrgan = organ
                    }
                    return
                }
            }
        }
    }
}
#endif

#if canImport(AppKit) && !canImport(UIKit)
struct HumanBodySceneViewRepresentableMac: NSViewRepresentable {
    @ObservedObject var viewModel: LabViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: HumanBodySceneController())
    }
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        let controller = context.coordinator.controller
        
        scnView.scene = controller.scene
        scnView.delegate = controller
        scnView.isPlaying = true
        scnView.loops = true
        scnView.preferredFramesPerSecond = 60
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = NSColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0)
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
        context.coordinator.controller.update(with: viewModel)
    }
    
    class Coordinator: NSObject {
        let controller: HumanBodySceneController
        weak var scnView: SCNView?
        var viewModel: LabViewModel?
        
        init(controller: HumanBodySceneController) {
            self.controller = controller
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
                if let name = hit.node.name,
                   let organ = TargetOrgan(rawValue: name) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectedOrgan = organ
                    }
                    return
                }
            }
        }
    }
}
#endif

