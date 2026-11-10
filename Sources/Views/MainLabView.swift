import SwiftUI

// MARK: - Main Lab View (HemaLens 2.0)
/// Root 3-tab Glassmorphic workspace combining:
/// 1. 3D Lab (Micro Inside Vein <-> Macro 3D Human Body + Sliders + Diagnostics/Symptoms)
/// 2. Nutrition & Lifestyle (Catalog + Sugar Timeline + Daily Tracker)
/// 3. My Blood & Watch Sync (Apple Watch Telemetry + Profiles + Real Exam Input)
struct MainLabView: View {
    @StateObject private var viewModel = LabViewModel()
    @State private var showingInfoModal: Bool = false
    @State private var compactPanelTab: CompactPanelTab = .controls
    
    enum CompactPanelTab: String, CaseIterable, Identifiable {
        case controls = "Sliders & Cases"
        case diagnosis = "Diagnosis & Symptoms"
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Active Main Tab Content
            Group {
                switch viewModel.activeMainTab {
                case .lab3D:
                    lab3DWorkspace
                case .nutrition:
                    NutritionLifestyleView(viewModel: viewModel)
                case .watchProfile:
                    UserProfileHealthView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Glassmorphic 3-Tab Navigation Bar
            floatingBottomTabBar
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .zIndex(5)
            
            // Onboarding Modal
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
                .zIndex(20)
            }
            
            // Challenge Completed Celebration Overlay
            if viewModel.challengeCompleted {
                challengeSuccessOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(30)
            }
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: viewModel.challengeCompleted)
        .onAppear {
            viewModel.showOnboardingModal = true
        }
    }
    
    // MARK: - Tab 1: 3D Lab Workspace
    private var lab3DWorkspace: some View {
        GeometryReader { geometry in
            let isWideLayout = geometry.size.width > 768
            
            ZStack {
                // Full-Bleed 3D Scene (Micro Vein OR Macro Human Body)
                Group {
                    if viewModel.sceneViewMode == .microVein {
                        BloodVesselSceneView(viewModel: viewModel)
                    } else {
                        HumanBodySceneView(viewModel: viewModel)
                    }
                }
                .ignoresSafeArea()
                
                // Top HUD Bar + Micro/Macro Toggle
                VStack(spacing: 8) {
                    topNavigationBar(isWide: isWideLayout)
                    sceneModeTogglePill(isWide: isWideLayout)
                    Spacer()
                }
                .padding(.horizontal, isWideLayout ? 20 : 12)
                .padding(.top, 8)
                
                // Adaptive Panels
                if isWideLayout {
                    HStack(alignment: .bottom, spacing: 20) {
                        VStack {
                            Spacer()
                            DiagnosticCardView(viewModel: viewModel)
                                .frame(maxWidth: 480)
                        }
                        
                        Spacer()
                        
                        VStack {
                            ControlPanelView(viewModel: viewModel)
                                .frame(width: 410)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 82) // Clear bottom tab bar
                    .padding(.top, 108)
                } else {
                    VStack(spacing: 8) {
                        Spacer()
                        
                        Picker("Panel", selection: $compactPanelTab) {
                            ForEach(CompactPanelTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(5)
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
                        .frame(height: min(325, geometry.size.height * 0.43))
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 76) // Clear bottom tab bar
                }
            }
        }
    }
    
    // MARK: - Top Navigation Bar
    @ViewBuilder
    private func topNavigationBar(isWide: Bool) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(.red)
                
                Text("HemaLens")
                    .font(isWide ? .headline.weight(.heavy) : .subheadline.weight(.heavy))
                    .foregroundStyle(.primary)
                
                if isWide {
                    Text("2.0")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.25))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, isWide ? 14 : 10)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.currentCondition.severityColor)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.currentCondition.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(viewModel.currentCondition.severityColor.opacity(0.4), lineWidth: 1)
            )
            
            Spacer()
            
            if isWide {
                HStack(spacing: 6) {
                    Image(systemName: "rotate.3d")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.sceneViewMode == .microVein ? "Orbit 360° • Tap cells" : "Orbit 360° • Tap organs")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingInfoModal = true
                }
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(5)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("App Information & Onboarding")
        }
    }
    
    // MARK: - Micro / Macro 3D View Toggle Pill
    @ViewBuilder
    private func sceneModeTogglePill(isWide: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(SceneViewMode.allCases) { mode in
                let isSelected = viewModel.sceneViewMode == mode
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.sceneViewMode = mode
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.iconName)
                            .font(.caption2)
                        Text(isWide ? mode.rawValue : mode.shortTitle)
                            .font(.caption2.weight(.bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        isSelected
                        ? (mode == .microVein ? Color.red.opacity(0.75) : Color.cyan.opacity(0.75))
                        : Color.clear
                    )
                    .foregroundStyle(isSelected ? Color.white : Color.secondary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Floating 3-Tab Navigation Bar
    private var floatingBottomTabBar: some View {
        HStack(spacing: 6) {
            ForEach(MainTab.allCases) { tab in
                let isSelected = viewModel.activeMainTab == tab
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        viewModel.activeMainTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .font(.subheadline.weight(.semibold))
                        Text(tab.rawValue)
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? tabAccentColor(for: tab).opacity(0.28) : Color.clear)
                    .foregroundStyle(isSelected ? tabAccentColor(for: tab) : .secondary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(isSelected ? tabAccentColor(for: tab).opacity(0.55) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(maxWidth: 460)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 6)
    }
    
    private func tabAccentColor(for tab: MainTab) -> Color {
        switch tab {
        case .lab3D: return .red
        case .nutrition: return .green
        case .watchProfile: return .cyan
        }
    }
    
    // MARK: - Challenge Success Overlay
    private var challengeSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.green.opacity(0.5), radius: 14, x: 0, y: 6)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 4) {
                    Text("Homeostasis Restored!")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.primary)
                    
                    Text("Critical Patient Successfully Stabilized")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
                
                VStack(spacing: 8) {
                    metricCheckRow(
                        title: "Erythrocytes (RBC)",
                        value: "\(BloodCellType.erythrocytes.formattedValue(viewModel.rbcCount)) million/µL",
                        outcome: "Tissue hypoxia resolved; cardiac tachycardia normalized."
                    )
                    
                    metricCheckRow(
                        title: "Leukocytes (WBC)",
                        value: "\(BloodCellType.leukocytes.formattedValue(viewModel.wbcCount)) /µL",
                        outcome: "Leukocytosis quelled; cytokine flare deactivated."
                    )
                    
                    metricCheckRow(
                        title: "Platelets (PLT)",
                        value: "\(BloodCellType.platelets.formattedValue(viewModel.pltCount)) /µL",
                        outcome: "Thrombosis risk prevented; fibrin strands stabilized."
                    )
                    
                    metricCheckRow(
                        title: "Blood Glucose",
                        value: "\(BloodCellType.glucose.formattedValue(viewModel.glucoseLevel)) mg/dL",
                        outcome: "Normoglycemia achieved; vascular glycation halted."
                    )
                }
                .padding(14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                VStack(spacing: 4) {
                    Label("Health Literacy Impact", systemImage: "heart.text.square.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                    
                    Text("\"By transforming complex laboratory numbers into living 3D physiology across vein and body, HemaLens empowers individuals to understand their blood health.\"")
                        .font(.caption)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                
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
            .padding(24)
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
