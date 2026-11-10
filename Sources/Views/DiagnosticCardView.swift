import SwiftUI

// MARK: - Diagnostic Card View
/// Dynamic glassmorphic HUD card explaining real-time blood physiology,
/// clinical diagnosis, hemodynamic vitals, and interactive cell inspection.
struct DiagnosticCardView: View {
    @ObservedObject var viewModel: LabViewModel
    @State private var selectedTab: DiagnosticTab = .overview
    @State private var isExpanded: Bool = true
    @State private var heartBeatPulse: Bool = false
    
    enum DiagnosticTab: String, CaseIterable, Identifiable {
        case overview = "Patient View"
        case biomedical = "Biomedical"
        case visualClues = "3D Clues"
        
        var id: String { rawValue }
    }
    
    var condition: ClinicalCondition {
        viewModel.currentCondition
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Optional Cell Inspector Banner (if user tapped a cell in 3D or slider info)
            if let inspectedCell = viewModel.selectedCellType {
                cellInspectorCard(for: inspectedCell)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 2. Main Clinical Diagnosis Card
            VStack(alignment: .leading, spacing: 12) {
                // Header Row: Condition Status + Severity Badge + Collapse Toggle
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(condition.severityColor.opacity(0.22))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: condition.statusIcon)
                            .font(.system(size: 18, weight: .semibold))
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
                
                // Hemodynamic Vitals Strip
                HStack(spacing: 8) {
                    vitalPill(
                        icon: "heart.fill",
                        iconColor: .red,
                        label: "Pulse",
                        value: "\(viewModel.heartRateBPM) BPM",
                        pulsing: true
                    )
                    
                    vitalPill(
                        icon: "drop.degreesign.fill",
                        iconColor: .orange,
                        label: "Viscosity",
                        value: String(format: "%.1fx", viewModel.relativeViscosity),
                        pulsing: false
                    )
                    
                    vitalPill(
                        icon: "figure.stand",
                        iconColor: condition.severityColor,
                        label: "Target",
                        value: condition.primaryOrganAtRisk.components(separatedBy: " (").first ?? "Systemic",
                        pulsing: false
                    )
                }
                
                if isExpanded {
                    Divider()
                        .overlay(Color.white.opacity(0.15))
                    
                    // Segmented Tab Picker
                    Picker("Detail View", selection: $selectedTab) {
                        ForEach(DiagnosticTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Tab Content
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
                                Text("Observe Inside the 3D Vessel:")
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
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(16)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: cell.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(cellColor(for: cell))
                
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
                .strokeBorder(cellColor(for: cell).opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Hemodynamic Vital Pill
    @ViewBuilder
    private func vitalPill(icon: String, iconColor: Color, label: String, value: String, pulsing: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(iconColor)
                .scaleEffect(pulsing && heartBeatPulse ? 1.22 : 1.0)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private func cellColor(for cell: BloodCellType) -> Color {
        switch cell {
        case .erythrocytes: return .red
        case .leukocytes: return .cyan
        case .platelets: return .yellow
        }
    }
}

