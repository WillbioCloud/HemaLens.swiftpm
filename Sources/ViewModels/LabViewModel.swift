import Foundation
import SwiftUI
import Combine

@MainActor
final class LabViewModel: ObservableObject {
    // MARK: - Reactive States (Core Sliders & Values)
    @Published var rbcCount: Double = 5.0 {       // million/µL (2.0 ... 7.0)
        didSet { checkChallengeProgress() }
    }
    @Published var wbcCount: Double = 7500.0 {    // /µL (1,000 ... 25,000)
        didSet { checkChallengeProgress() }
    }
    @Published var pltCount: Double = 280000.0 {  // /µL (50,000 ... 600,000)
        didSet { checkChallengeProgress() }
    }
    
    // MARK: - Interactive Mode States
    @Published var isChallengeModeActive: Bool = false
    @Published var challengeCompleted: Bool = false
    @Published var selectedPreset: PatientPreset? = PatientPreset.presets.first
    @Published var selectedCellType: BloodCellType? = nil
    @Published var showOnboardingModal: Bool = false
    @Published var isSimulationPaused: Bool = false
    
    // MARK: - Automated Clinical Diagnosis (Section 4.2 SDD)
    /// Evaluates all 3 blood cell counts with biomedical priority ordering
    var currentCondition: ClinicalCondition {
        // 1. Critical thresholds evaluation (Primary clinical urgency)
        if rbcCount < BloodCellType.erythrocytes.criticalLowThreshold {
            return .anemia
        } else if rbcCount > BloodCellType.erythrocytes.criticalHighThreshold {
            return .polycythemia
        } else if wbcCount > BloodCellType.leukocytes.criticalHighThreshold {
            return .infectionResponse
        } else if wbcCount < BloodCellType.leukocytes.criticalLowThreshold {
            return .leukopenia
        } else if pltCount > BloodCellType.platelets.criticalHighThreshold {
            return .thrombosisRisk
        } else if pltCount < BloodCellType.platelets.criticalLowThreshold {
            return .thrombocytopenia
        }
        
        // 2. Mild threshold deviations
        if rbcCount < BloodCellType.erythrocytes.normalRange.lowerBound {
            return .anemia
        } else if rbcCount > BloodCellType.erythrocytes.normalRange.upperBound {
            return .polycythemia
        } else if wbcCount > BloodCellType.leukocytes.normalRange.upperBound {
            return .infectionResponse
        } else if wbcCount < BloodCellType.leukocytes.normalRange.lowerBound {
            return .leukopenia
        } else if pltCount > BloodCellType.platelets.normalRange.upperBound {
            return .thrombosisRisk
        } else if pltCount < BloodCellType.platelets.normalRange.lowerBound {
            return .thrombocytopenia
        }
        
        // 3. Perfect physiological balance
        return .homeostasis
    }
    
    var isHomeostasis: Bool {
        currentCondition == .homeostasis
    }
    
    // MARK: - Lineage Specific Statuses
    var rbcStatus: ParameterStatus {
        BloodCellType.erythrocytes.status(for: rbcCount)
    }
    
    var wbcStatus: ParameterStatus {
        BloodCellType.leukocytes.status(for: wbcCount)
    }
    
    var pltStatus: ParameterStatus {
        BloodCellType.platelets.status(for: pltCount)
    }
    
    var abnormalParameters: [BloodCellType] {
        var list: [BloodCellType] = []
        if rbcStatus.isAbnormal { list.append(.erythrocytes) }
        if wbcStatus.isAbnormal { list.append(.leukocytes) }
        if pltStatus.isAbnormal { list.append(.platelets) }
        return list
    }
    
    // MARK: - Homeostasis Score (Challenge Mode Metric: 0.0 to 1.0)
    /// Computes how close the patient is to physiological equilibrium
    var homeostasisProgress: Double {
        func score(value: Double, normal: ClosedRange<Double>, min: Double, max: Double) -> Double {
            if normal.contains(value) { return 1.0 }
            if value < normal.lowerBound {
                let dist = normal.lowerBound - value
                let span = normal.lowerBound - min
                return Swift.max(0.0, 1.0 - (dist / Swift.max(span, 0.001)))
            } else {
                let dist = value - normal.upperBound
                let span = max - normal.upperBound
                return Swift.max(0.0, 1.0 - (dist / Swift.max(span, 0.001)))
            }
        }
        
        let sRBC = score(
            value: rbcCount,
            normal: BloodCellType.erythrocytes.normalRange,
            min: BloodCellType.erythrocytes.minRange,
            max: BloodCellType.erythrocytes.maxRange
        )
        let sWBC = score(
            value: wbcCount,
            normal: BloodCellType.leukocytes.normalRange,
            min: BloodCellType.leukocytes.minRange,
            max: BloodCellType.leukocytes.maxRange
        )
        let sPLT = score(
            value: pltCount,
            normal: BloodCellType.platelets.normalRange,
            min: BloodCellType.platelets.minRange,
            max: BloodCellType.platelets.maxRange
        )
        
        return (sRBC + sWBC + sPLT) / 3.0
    }
    
    // MARK: - Mathematical Bridge for 3D SceneKit Engine (Section 4 & 5 SDD)
    
    /// Target number of 3D Red Blood Cell nodes to render (Range: 15 to 75)
    var targetRBCNodeCount: Int {
        let norm = BloodCellType.erythrocytes.normalizedValue(rbcCount)
        return Int(15.0 + (norm * 60.0))
    }
    
    /// Target number of 3D White Blood Cell nodes to render (Range: 2 to 25)
    var targetWBCNodeCount: Int {
        let norm = BloodCellType.leukocytes.normalizedValue(wbcCount)
        return Int(2.0 + (norm * 23.0))
    }
    
    /// Target number of 3D Platelet nodes to render (Range: 5 to 55)
    var targetPLTNodeCount: Int {
        let norm = BloodCellType.platelets.normalizedValue(pltCount)
        return Int(5.0 + (norm * 50.0))
    }
    
    /// Multiplier for blood stream velocity in 3D:
    /// In polycythemia, hyperviscosity significantly drags flow speed down.
    /// In anemia, lower viscosity and compensatory hyperdynamic output adjust velocity.
    var bloodFlowSpeedMultiplier: Float {
        if isSimulationPaused { return 0.0 }
        
        if rbcCount > 5.9 {
            // High hematocrit / viscous drag (drags down to 0.35x speed)
            let excess = Float(rbcCount - 5.9) / Float(7.0 - 5.9)
            return Swift.max(0.35, 1.0 - (excess * 0.65))
        } else if rbcCount < 4.0 {
            // Low hematocrit / rapid watery stream with high shear rate
            return 1.25
        } else {
            return 1.0
        }
    }
    
    /// Oxygenation light saturation in the 3D lumen (0.35 pale pink in anemia up to 1.0 vibrant crimson)
    var oxygenationGlowFactor: Float {
        let norm = Float(BloodCellType.erythrocytes.normalizedValue(rbcCount))
        return Swift.min(1.0, Swift.max(0.35, 0.35 + (norm * 0.65)))
    }
    
    /// Triggers cytokine particle emissions and leukocyte patrol motions when WBC > 11,000 /µL
    var isImmuneResponseActive: Bool {
        wbcCount > BloodCellType.leukocytes.normalRange.upperBound
    }
    
    /// Cytokine particle intensity from 0.0 (baseline) to 1.0 (severe storm)
    var cytokineParticleIntensity: Float {
        guard wbcCount > 11000.0 else { return 0.0 }
        let excess = Float(wbcCount - 11000.0) / Float(25000.0 - 11000.0)
        return Swift.min(1.0, Swift.max(0.0, excess))
    }
    
    /// Triggers platelet clumping and fibrin threads when PLT > 450,000 /µL
    var isClottingRiskActive: Bool {
        pltCount > BloodCellType.platelets.normalRange.upperBound
    }
    
    /// Fibrin mesh cross-linking intensity from 0.0 (none) to 1.0 (dense thrombus)
    var fibrinMeshIntensity: Float {
        guard pltCount > 450000.0 else { return 0.0 }
        let excess = Float(pltCount - 450000.0) / Float(600000.0 - 450000.0)
        return Swift.min(1.0, Swift.max(0.0, excess))
    }
    
    /// Indicates hemorrhagic risk due to critically low platelets (< 140,000 /µL)
    var isBleedingRiskActive: Bool {
        pltCount < BloodCellType.platelets.criticalLowThreshold
    }
    
    // MARK: - Physiological Metrics (Educational Display)
    
    /// Estimated pulse rate (BPM) responding dynamically to hematology
    var heartRateBPM: Int {
        if rbcCount < 4.0 {
            // Compensatory tachycardia in tissue hypoxia
            let deficit = (4.0 - rbcCount) / (4.0 - 2.0)
            return Int(85.0 + (deficit * 30.0)) // up to 115 bpm
        } else if wbcCount > 12000.0 {
            // Inflammatory tachycardia
            return 98
        } else if rbcCount > 6.0 {
            // Heavy stroke volume with high afterload
            return 64
        } else {
            // Resting healthy rhythm
            return 72
        }
    }
    
    /// Whole blood relative viscosity compared to water (1.0)
    var relativeViscosity: Double {
        // Poiseuille approximation: normal blood ~3.5–4.5 mPa·s
        let hematocritApprox = (rbcCount / 5.0) * 0.45
        return 1.0 + (hematocritApprox * 8.5)
    }
    
    // MARK: - User Actions
    
    /// Applies a pre-configured patient case
    func applyPreset(_ preset: PatientPreset) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isChallengeModeActive = false
            challengeCompleted = false
            selectedPreset = preset
            rbcCount = preset.rbc
            wbcCount = preset.wbc
            pltCount = preset.plt
        }
    }
    
    /// Launches the 3-minute challenge mode ("Restore Homeostasis")
    func startEmergencyChallenge() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isChallengeModeActive = true
            challengeCompleted = false
            selectedPreset = nil
            // Initial emergency state: Severe Anemia + Sepsis + Thrombocytosis
            rbcCount = 2.6
            wbcCount = 21500.0
            pltCount = 560000.0
        }
    }
    
    /// Resets all values to standard healthy homeostasis
    func resetToHomeostasis() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isChallengeModeActive = false
            challengeCompleted = false
            selectedPreset = PatientPreset.presets.first
            rbcCount = BloodCellType.erythrocytes.defaultValue
            wbcCount = BloodCellType.leukocytes.defaultValue
            pltCount = BloodCellType.platelets.defaultValue
        }
    }
    
    /// Validates if the user successfully restored homeostasis in challenge mode
    /// Dispatches asynchronously on MainActor to avoid publishing changes inside SwiftUI view update cycles
    func checkChallengeProgress() {
        guard isChallengeModeActive, !challengeCompleted, isHomeostasis else { return }
        Task { @MainActor [weak self] in
            guard let self = self,
                  self.isChallengeModeActive,
                  !self.challengeCompleted,
                  self.isHomeostasis else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                self.challengeCompleted = true
            }
        }
    }
    
    /// Increments or decrements a specific parameter by its standard step
    func stepParameter(_ cellType: BloodCellType, increment: Bool) {
        let delta = increment ? cellType.step : -cellType.step
        withAnimation(.easeInOut(duration: 0.15)) {
            switch cellType {
            case .erythrocytes:
                rbcCount = Swift.min(cellType.maxRange, Swift.max(cellType.minRange, rbcCount + delta))
            case .leukocytes:
                wbcCount = Swift.min(cellType.maxRange, Swift.max(cellType.minRange, wbcCount + delta))
            case .platelets:
                pltCount = Swift.min(cellType.maxRange, Swift.max(cellType.minRange, pltCount + delta))
            }
        }
    }
}
