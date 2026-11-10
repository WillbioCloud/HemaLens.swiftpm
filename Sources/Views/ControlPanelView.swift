import SwiftUI

// MARK: - Control Panel View
/// Interactive dashboard containing real-time sliders with visual reference zones,
/// clinical patient presets, and the "Restore Homeostasis" emergency challenge.
struct ControlPanelView: View {
    @ObservedObject var viewModel: LabViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Header & Quick Actions
                headerBar
                
                // 2. Restore Homeostasis Challenge Widget (SDD Section 6)
                challengeSection
                
                // 3. Real-Time Hematology Sliders
                VStack(spacing: 14) {
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
                }
                
                // 4. Pre-configured Clinical Patient Cases
                patientCasesSection
            }
            .padding(18)
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
                viewModel.rbcCount = newValue
            }
        )
    }
    
    private var wbcBinding: Binding<Double> {
        Binding(
            get: { viewModel.wbcCount },
            set: { newValue in
                viewModel.selectedPreset = nil
                viewModel.wbcCount = newValue
            }
        )
    }
    
    private var pltBinding: Binding<Double> {
        Binding(
            get: { viewModel.pltCount },
            set: { newValue in
                viewModel.selectedPreset = nil
                viewModel.pltCount = newValue
            }
        )
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("HEMATOLOGY LAB")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                
                Text("Blood Parameters")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // Play / Pause Simulation
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isSimulationPaused.toggle()
                }
            } label: {
                Image(systemName: viewModel.isSimulationPaused ? "play.fill" : "pause.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isSimulationPaused ? "Resume flow" : "Pause flow")
            
            // Reset to Baseline
            Button {
                viewModel.resetToHomeostasis()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset to Homeostasis")
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
                
                // Live Progress Gauge
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
                    Text("Align all 3 sliders into the green target ranges.")
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
                        Text("Stabilize a critical patient case in real time")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("CLINICAL PATIENT CASES")
                .font(.caption2.weight(.heavy))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                ForEach(PatientPreset.presets) { preset in
                    let isSelected = viewModel.selectedPreset == preset
                    
                    Button {
                        viewModel.isChallengeModeActive = false
                        viewModel.challengeCompleted = false
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
                        .padding(.vertical, 10)
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
        VStack(alignment: .leading, spacing: 8) {
            // Top Row: Icon + Name + Value + Status
            HStack(spacing: 8) {
                Image(systemName: cellType.iconName)
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                    .frame(width: 24, height: 24)
                    .background(accentColor.opacity(0.16))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(cellType.shortName)
                            .font(.subheadline.weight(.bold))
                        Text("(\(cellType.scientificName))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(cellType.formattedValue(value))
                            .font(.subheadline.weight(.heavy).monospacedDigit())
                            .foregroundStyle(status.color)
                        Text(cellType.unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Slider + Stepper Controls
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
                    
                    // Visual Normal Zone Bar (Shows target homeostasis zone proportionally)
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
            
            // Footer Reference & Status Badge
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
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(status.isAbnormal ? status.color.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

