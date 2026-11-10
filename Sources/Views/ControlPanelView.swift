import SwiftUI

// MARK: - Control Panel View
/// Interactive dashboard containing all 4 real-time biomarker sliders (RBC, WBC, PLT, Glucose)
/// with visual reference zones, clinical patient presets, and the "Restore Homeostasis" challenge.
struct ControlPanelView: View {
    @ObservedObject var viewModel: LabViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 1. Header & Quick Actions
                headerBar
                
                // 2. Restore Homeostasis Challenge Widget
                challengeSection
                
                // 3. Macro Body Quick Organ Selector (visible in Macro View)
                if viewModel.sceneViewMode == .macroBody {
                    macroOrganQuickBar
                }
                
                // 4. Real-Time Hematology & Glycemia Sliders
                VStack(spacing: 12) {
                    BloodParameterSliderRow(
                        cellType: .erythrocytes,
                        value: rbcBinding,
                        status: viewModel.rbcStatus,
                        accentColor: .red,
                        onStep: { inc in viewModel.stepParameter(.erythrocytes, increment: inc) },
                        onInspect: { toggleInspect(.erythrocytes) }
                    )
                    
                    BloodParameterSliderRow(
                        cellType: .leukocytes,
                        value: wbcBinding,
                        status: viewModel.wbcStatus,
                        accentColor: .cyan,
                        onStep: { inc in viewModel.stepParameter(.leukocytes, increment: inc) },
                        onInspect: { toggleInspect(.leukocytes) }
                    )
                    
                    BloodParameterSliderRow(
                        cellType: .platelets,
                        value: pltBinding,
                        status: viewModel.pltStatus,
                        accentColor: .yellow,
                        onStep: { inc in viewModel.stepParameter(.platelets, increment: inc) },
                        onInspect: { toggleInspect(.platelets) }
                    )
                    
                    BloodParameterSliderRow(
                        cellType: .glucose,
                        value: glucoseBinding,
                        status: viewModel.glucoseStatus,
                        accentColor: .mint,
                        onStep: { inc in viewModel.stepParameter(.glucose, increment: inc) },
                        onInspect: { toggleInspect(.glucose) }
                    )
                }
                
                // 5. Pre-configured Clinical Patient Cases
                patientCasesSection
            }
            .padding(16)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Bindings
    private var rbcBinding: Binding<Double> {
        Binding(
            get: { viewModel.rbcCount },
            set: { newValue in
                viewModel.selectedPreset = nil
                viewModel.activeWatchProfile = nil
                viewModel.rbcCount = newValue
            }
        )
    }
    
    private var wbcBinding: Binding<Double> {
        Binding(
            get: { viewModel.wbcCount },
            set: { newValue in
                viewModel.selectedPreset = nil
                viewModel.activeWatchProfile = nil
                viewModel.wbcCount = newValue
            }
        )
    }
    
    private var pltBinding: Binding<Double> {
        Binding(
            get: { viewModel.pltCount },
            set: { newValue in
                viewModel.selectedPreset = nil
                viewModel.activeWatchProfile = nil
                viewModel.pltCount = newValue
            }
        )
    }
    
    private var glucoseBinding: Binding<Double> {
        Binding(
            get: { viewModel.glucoseLevel },
            set: { newValue in
                viewModel.selectedPreset = nil
                viewModel.activeWatchProfile = nil
                viewModel.glucoseLevel = newValue
            }
        )
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("HEMATOLOGY & METABOLIC LAB")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                
                Text("Blood Parameters")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isSimulationPaused.toggle()
                }
            } label: {
                Image(systemName: viewModel.isSimulationPaused ? "play.fill" : "pause.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isSimulationPaused ? "Resume simulation" : "Pause simulation")
            
            Button {
                viewModel.resetToHomeostasis()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset to Homeostasis")
        }
    }
    
    // MARK: - Macro Organ Quick Bar
    private var macroOrganQuickBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("INSPECT TARGET ORGAN")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.0)
                .foregroundStyle(.cyan)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TargetOrgan.allCases) { organ in
                        let isSelected = viewModel.selectedOrgan == organ
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.selectedOrgan = isSelected ? nil : organ
                            }
                        } label: {
                            Label(organ.rawValue, systemImage: organ.iconName)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.cyan.opacity(0.35) : Color.white.opacity(0.08))
                                .foregroundStyle(isSelected ? .white : .secondary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(isSelected ? Color.cyan : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Restore Homeostasis Challenge Section
    @ViewBuilder
    private var challengeSection: some View {
        if viewModel.isChallengeModeActive {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Emergency Stabilization", systemImage: "waveform.path.ecg")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.homeostasisProgress * 100))%")
                        .font(.subheadline.weight(.heavy).monospacedDigit())
                        .foregroundStyle(viewModel.isHomeostasis ? .green : .orange)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: viewModel.isHomeostasis ? [.green, .mint] : [.red, .orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(viewModel.homeostasisProgress)))
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.homeostasisProgress)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("Align all 4 sliders into the green target ranges.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Exit") {
                        viewModel.resetToHomeostasis()
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
            )
        } else {
            Button {
                viewModel.startEmergencyChallenge()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Restore Homeostasis Challenge")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Stabilize a critical multi-system patient")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        colors: [Color.red.opacity(0.85), Color.orange.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Patient Presets Section
    private var patientCasesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CLINICAL PATIENT CASES")
                .font(.caption2.weight(.heavy))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 7) {
                ForEach(PatientPreset.presets) { preset in
                    let isSelected = viewModel.selectedPreset == preset
                    
                    Button {
                        viewModel.applyPreset(preset)
                    } label: {
                        HStack(spacing: 10) {
                            Text(preset.caseNumber)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                                .foregroundStyle(isSelected ? .white : .secondary)
                                .clipShape(Capsule())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.primary)
                                Text(preset.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(isSelected ? Color.white.opacity(0.14) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isSelected ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func toggleInspect(_ cell: BloodCellType) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            viewModel.sceneViewMode = .microVein
            if viewModel.selectedCellType == cell {
                viewModel.selectedCellType = nil
            } else {
                viewModel.selectedCellType = cell
            }
        }
    }
}

// MARK: - Blood Parameter Slider Row
struct BloodParameterSliderRow: View {
    let cellType: BloodCellType
    @Binding var value: Double
    let status: ParameterStatus
    let accentColor: Color
    let onStep: (Bool) -> Void
    let onInspect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: cellType.iconName)
                    .font(.caption)
                    .foregroundStyle(accentColor)
                    .frame(width: 24, height: 24)
                    .background(accentColor.opacity(0.16))
                    .clipShape(Circle())
                
                HStack(spacing: 4) {
                    Text(cellType.shortName)
                        .font(.subheadline.weight(.bold))
                    Text("(\(cellType.scientificName))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Button {
                    onInspect()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Inspect \(cellType.commonName)")
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(cellType.formattedValue(value))
                        .font(.subheadline.weight(.heavy).monospacedDigit())
                        .foregroundStyle(status.color)
                    Text(cellType.unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                Button {
                    onStep(false)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                VStack(spacing: 4) {
                    Slider(
                        value: $value,
                        in: cellType.minRange...cellType.maxRange,
                        step: cellType.step
                    )
                    .tint(status.color)
                    
                    GeometryReader { geo in
                        let lowerNorm = cellType.normalizedValue(cellType.normalRange.lowerBound)
                        let upperNorm = cellType.normalizedValue(cellType.normalRange.upperBound)
                        let startX = geo.size.width * CGFloat(lowerNorm)
                        let zoneWidth = geo.size.width * CGFloat(upperNorm - lowerNorm)
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.green.opacity(0.75))
                                .frame(width: max(6, zoneWidth), height: 4)
                                .offset(x: startX)
                        }
                    }
                    .frame(height: 4)
                }
                
                Button {
                    onStep(true)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                Text("Normal Ref: \(cellType.formattedValue(cellType.normalRange.lowerBound)) – \(cellType.formattedValue(cellType.normalRange.upperBound)) \(cellType.unit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(status.shortLabel)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.2))
                    .foregroundStyle(status.color)
                    .clipShape(Capsule())
            }
        }
        .padding(11)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(status.isAbnormal ? status.color.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
