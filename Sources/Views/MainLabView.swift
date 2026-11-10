import SwiftUI

// MARK: - Main Lab View
/// Primary container coordinating the 3D procedural SceneKit simulation,
/// real-time diagnostic card, interactive control panel, and challenge overlays.
struct MainLabView: View {
    @StateObject private var viewModel = LabViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingInfoModal: Bool = false
    @State private var compactPanelTab: CompactPanelTab = .controls
    
    enum CompactPanelTab: String, CaseIterable, Identifiable {
        case controls = "Lab Controls"
        case diagnosis = "Diagnosis"
        var id: String { rawValue }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isWideLayout = geometry.size.width > 768
            
            ZStack {
                // Background: Full-Bleed 3D Blood Vessel Scene
                BloodVesselSceneView(viewModel: viewModel)
                    .ignoresSafeArea()
                
                // Top HUD Bar (Title + Live Status + Help Button)
                VStack {
                    topNavigationBar(isWide: isWideLayout)
                    Spacer()
                }
                .padding(.horizontal, isWideLayout ? 20 : 12)
                .padding(.top, 10)
                
                // Adaptive Content Layout
                if isWideLayout {
                    // iPad / Mac Split Layout
                    HStack(alignment: .bottom, spacing: 20) {
                        // Left Column: Live Diagnostic Card over 3D Vessel
                        VStack {
                            Spacer()
                            DiagnosticCardView(viewModel: viewModel)
                                .frame(maxWidth: 480)
                        }
                        
                        Spacer()
                        
                        // Right Column: Control Panel Dock
                        VStack {
                            ControlPanelView(viewModel: viewModel)
                                .frame(width: 410)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .padding(.top, 64)
                } else {
                    // iPhone Compact Layout: Keep top 45% open for the 3D Vessel!
                    VStack(spacing: 8) {
                        Spacer()
                        
                        // Compact Switcher between Sliders and Full Diagnosis
                        Picker("Panel", selection: $compactPanelTab) {
                            ForEach(CompactPanelTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        Group {
                            if compactPanelTab == .controls {
                                ControlPanelView(viewModel: viewModel)
                            } else {
                                ScrollView(.vertical, showsIndicators: false) {
                                    DiagnosticCardView(viewModel: viewModel)
                                }
                            }
                        }
                        .frame(height: min(360, geometry.size.height * 0.48))
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
                
                // Onboarding Modal (0:00–0:30 min experience)
                if showingInfoModal || viewModel.showOnboardingModal {
                    OnboardingModalView(
                        isPresented: Binding(
                            get: { showingInfoModal || viewModel.showOnboardingModal },
                            set: { newVal in
                                showingInfoModal = newVal
                                viewModel.showOnboardingModal = newVal
                            }
                        )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(10)
                }
                
                // Challenge Completed Celebration Overlay (2:00–3:00 min experience)
                if viewModel.challengeCompleted {
                    challengeSuccessOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .zIndex(20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: viewModel.challengeCompleted)
        .onAppear {
            // Display onboarding on initial launch
            viewModel.showOnboardingModal = true
        }
    }
    
    // MARK: - Top Navigation Bar
    @ViewBuilder
    private func topNavigationBar(isWide: Bool) -> some View {
        HStack(spacing: 10) {
            // App Branding Pill
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.red)
                
                Text("HemaLens")
                    .font(isWide ? .headline.weight(.heavy) : .subheadline.weight(.heavy))
                    .foregroundStyle(.primary)
                
                if isWide {
                    Text("LAB")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.25))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, isWide ? 14 : 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            
            // Live Condition Capsule
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.currentCondition.severityColor)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.currentCondition.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(viewModel.currentCondition.severityColor.opacity(0.4), lineWidth: 1)
            )
            
            Spacer()
            
            // 360 Camera Interaction Indicator (shown on iPad / Mac)
            if isWide {
                HStack(spacing: 6) {
                    Image(systemName: "rotate.3d")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Drag to orbit 360° • Tap cells")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            
            // Info / Onboarding Button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingInfoModal = true
                }
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("App Information & Onboarding")
        }
    }
    
    // MARK: - Challenge Success Overlay (SDD Section 6)
    private var challengeSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Celebratory Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.green.opacity(0.5), radius: 14, x: 0, y: 6)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 6) {
                    Text("Homeostasis Restored!")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.primary)
                    
                    Text("Critical Patient Successfully Stabilized")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
                
                // Physiological Equilibrium Proof
                VStack(spacing: 8) {
                    metricCheckRow(
                        title: "Erythrocytes (RBC)",
                        value: "\(BloodCellType.erythrocytes.formattedValue(viewModel.rbcCount)) million/µL",
                        outcome: "Tissue hypoxia resolved; cardiac tachycardia normalized."
                    )
                    
                    metricCheckRow(
                        title: "Leukocytes (WBC)",
                        value: "\(BloodCellType.leukocytes.formattedValue(viewModel.wbcCount)) /µL",
                        outcome: "Leukocytosis quelled; cytokine inflammatory flare deactivated."
                    )
                    
                    metricCheckRow(
                        title: "Platelets (PLT)",
                        value: "\(BloodCellType.platelets.formattedValue(viewModel.pltCount)) /µL",
                        outcome: "Thrombosis risk prevented; fibrin cross-linking stabilized."
                    )
                }
                .padding(14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                // Social & Educational Impact Statement
                VStack(spacing: 4) {
                    Label("Health Literacy Impact", systemImage: "heart.text.square.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                    
                    Text("\"By transforming complex laboratory numbers into living 3D physiology, HemaLens empowers individuals to understand their blood health and take control of their clinical journey.\"")
                        .font(.caption)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button {
                        viewModel.startEmergencyChallenge()
                    } label: {
                        Text("Try Another Case")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.spring()) {
                            viewModel.challengeCompleted = false
                            viewModel.isChallengeModeActive = false
                        }
                    } label: {
                        Text("Continue Exploring")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(26)
            .frame(maxWidth: 500)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.green.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
            .padding(20)
        }
    }
    
    @ViewBuilder
    private func metricCheckRow(title: String, value: String, outcome: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(value)
                        .font(.caption2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.green)
                }
                Text(outcome)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
