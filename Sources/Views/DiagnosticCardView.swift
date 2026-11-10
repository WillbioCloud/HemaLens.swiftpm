import SwiftUI

// MARK: - Diagnostic Card View
/// Dynamic glassmorphic HUD card explaining real-time blood physiology,
/// categorized system symptoms, hemodynamic vitals, and cell/organ inspection.
struct DiagnosticCardView: View {
    @ObservedObject var viewModel: LabViewModel
    @State private var selectedTab: DiagnosticTab = .overview
    @State private var isExpanded: Bool = true
    @State private var heartBeatPulse: Bool = false
    
    enum DiagnosticTab: String, CaseIterable, Identifiable {
        case overview = "Patient"
        case symptoms = "Symptoms"
        case biomedical = "Biomedical"
        case visualClues = "3D Clues"
        
        var id: String { rawValue }
    }
    
    var condition: ClinicalCondition {
        viewModel.currentCondition
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Optional Cell Inspector Banner (Micro View tap)
            if let inspectedCell = viewModel.selectedCellType,
               viewModel.sceneViewMode == .microVein {
                cellInspectorCard(for: inspectedCell)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 2. Optional Organ Impact Inspector Banner (Macro View tap)
            if let inspectedOrgan = viewModel.selectedOrgan,
               viewModel.sceneViewMode == .macroBody {
                organInspectorCard(for: inspectedOrgan)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 3. Main Clinical Diagnosis Card
            VStack(alignment: .leading, spacing: 10) {
                // Header Row
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(condition.severityColor.opacity(0.22))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: condition.statusIcon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(condition.severityColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(condition.badgeTitle)
                                .font(.caption2.weight(.heavy))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(condition.severityColor.opacity(0.25))
                                .foregroundStyle(condition.severityColor)
                                .clipShape(Capsule())
                            
                            Text(condition.medicalTerm)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Text(condition.displayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isExpanded ? "Collapse diagnostic details" : "Expand diagnostic details")
                }
                
                // Hemodynamic & Metabolic Vitals Strip
                HStack(spacing: 6) {
                    vitalPill(
                        icon: "heart.fill",
                        iconColor: .red,
                        label: "Pulse",
                        value: "\(viewModel.heartRateBPM) BPM",
                        pulsing: true
                    )
                    
                    vitalPill(
                        icon: "lungs.fill",
                        iconColor: .cyan,
                        label: "SpO2",
                        value: "\(viewModel.estimatedSpO2)%",
                        pulsing: false
                    )
                    
                    vitalPill(
                        icon: "drop.degreesign.fill",
                        iconColor: .orange,
                        label: "Viscosity",
                        value: String(format: "%.1fx", viewModel.relativeViscosity),
                        pulsing: false
                    )
                    
                    vitalPill(
                        icon: "cube.fill",
                        iconColor: .mint,
                        label: "Est. HbA1c",
                        value: String(format: "%.1f%%", viewModel.estimatedHbA1c),
                        pulsing: false
                    )
                }
                
                if isExpanded {
                    Divider()
                        .overlay(Color.white.opacity(0.15))
                    
                    Picker("Detail View", selection: $selectedTab) {
                        ForEach(DiagnosticTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        Group {
                            switch selectedTab {
                            case .overview:
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(condition.laypersonExplanation)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary.opacity(0.95))
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "stethoscope")
                                            .font(.caption)
                                            .foregroundStyle(condition.severityColor)
                                            .padding(.top, 2)
                                        Text(condition.clinicalAction)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                
                            case .symptoms:
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(condition.symptomsBySystem) { group in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Label {
                                                Text(group.system.rawValue)
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(group.system.color)
                                            } icon: {
                                                Image(systemName: group.system.iconName)
                                                    .font(.caption2)
                                                    .foregroundStyle(group.system.color)
                                            }
                                            
                                            ForEach(group.symptoms, id: \.self) { symptom in
                                                HStack(alignment: .top, spacing: 6) {
                                                    Text("•")
                                                        .font(.caption.weight(.bold))
                                                        .foregroundStyle(group.system.color)
                                                    Text(symptom)
                                                        .font(.caption)
                                                        .foregroundStyle(.primary.opacity(0.92))
                                                        .fixedSize(horizontal: false, vertical: true)
                                                }
                                            }
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                                
                            case .biomedical:
                                VStack(alignment: .leading, spacing: 8) {
                                    Label {
                                        Text("Pathophysiology")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    } icon: {
                                        Image(systemName: "waveform.path.ecg")
                                            .font(.caption)
                                            .foregroundStyle(.cyan)
                                    }
                                    
                                    Text(condition.biomedicalNote)
                                        .font(.caption)
                                        .foregroundStyle(.primary.opacity(0.95))
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Label {
                                        Text("Hemodynamic Impact")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    } icon: {
                                        Image(systemName: "heart.text.square.fill")
                                            .font(.caption)
                                            .foregroundStyle(condition.severityColor)
                                    }
                                    .padding(.top, 2)
                                    
                                    Text(condition.cardiovascularImpact)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                            case .visualClues:
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Observe in 3D Scene:")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.secondary)
                                    
                                    ForEach(condition.visual3DClues, id: \.self) { clue in
                                        HStack(alignment: .center, spacing: 8) {
                                            Image(systemName: "eye.fill")
                                                .font(.caption2)
                                                .foregroundStyle(condition.severityColor)
                                            Text(clue)
                                                .font(.caption)
                                                .foregroundStyle(.primary.opacity(0.92))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    
                                    if viewModel.sceneViewMode == .macroBody {
                                        Divider().overlay(Color.white.opacity(0.1))
                                        Text("Tap any glowing organ in the 3D Human Body (or pick below):")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(TargetOrgan.allCases) { organ in
                                                    Button {
                                                        withAnimation(.spring()) {
                                                            viewModel.selectedOrgan = organ
                                                        }
                                                    } label: {
                                                        Label(organ.rawValue, systemImage: organ.iconName)
                                                            .font(.caption2.weight(.semibold))
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 5)
                                                            .background(viewModel.selectedOrgan == organ ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1))
                                                            .clipShape(Capsule())
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 195)
                    .transition(.opacity)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(condition.severityColor.opacity(0.45), lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                heartBeatPulse = true
            }
        }
    }
    
    // MARK: - Cell Inspector Sub-card
    @ViewBuilder
    private func cellInspectorCard(for cell: BloodCellType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: cell.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(cell.themeColor)
                
                Text("\(cell.commonName) (\(cell.scientificName))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        viewModel.selectedCellType = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(cell.primaryFunction)
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            Text("3D Representation: \(cell.visual3DDescription)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(cell.themeColor.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Organ Impact Inspector Sub-card
    @ViewBuilder
    private func organInspectorCard(for organ: TargetOrgan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: organ.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.cyan)
                
                Text("Organ Impact: \(organ.rawValue)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        viewModel.selectedOrgan = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(organ.impactDescription(
                for: condition,
                rbc: viewModel.rbcCount,
                wbc: viewModel.wbcCount,
                plt: viewModel.pltCount,
                glucose: viewModel.glucoseLevel
            ))
            .font(.caption)
            .foregroundStyle(.primary.opacity(0.94))
            .fixedSize(horizontal: false, vertical: true)
            
            Text(organ.physiologicalRole)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.cyan.opacity(0.55), lineWidth: 1.2)
        )
    }
    
    // MARK: - Hemodynamic Vital Pill
    @ViewBuilder
    private func vitalPill(icon: String, iconColor: Color, label: String, value: String, pulsing: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(iconColor)
                .scaleEffect(pulsing && heartBeatPulse ? 1.22 : 1.0)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 10.5, weight: .bold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
