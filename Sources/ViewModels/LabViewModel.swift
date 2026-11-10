import Foundation
import SwiftUI
import Combine

// MARK: - Navigation & 3D Modes
enum MainTab: String, CaseIterable, Identifiable {
    case lab3D = "3D Lab"
    case nutrition = "Nutrition"
    case watchProfile = "My Blood"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .lab3D: return "drop.circle.fill"
        case .nutrition: return "leaf.circle.fill"
        case .watchProfile: return "applewatch.watchface"
        }
    }
}

enum SceneViewMode: String, CaseIterable, Identifiable {
    case microVein = "Micro View (Inside Vein)"
    case macroBody = "Macro View (3D Human Body)"
    
    var id: String { rawValue }
    
    var shortTitle: String {
        switch self {
        case .microVein: return "Inside Vein"
        case .macroBody: return "3D Body"
        }
    }
    
    var iconName: String {
        switch self {
        case .microVein: return "circle.hexagongrid.fill"
        case .macroBody: return "figure.stand"
        }
    }
}

@MainActor
final class LabViewModel: ObservableObject {
    // MARK: - Reactive Blood Parameters
    @Published var rbcCount: Double = 5.0 {       // million/µL (2.0 ... 7.0)
        didSet { checkChallengeProgress() }
    }
    @Published var wbcCount: Double = 7500.0 {    // /µL (1,000 ... 25,000)
        didSet { checkChallengeProgress() }
    }
    @Published var pltCount: Double = 280000.0 {  // /µL (50,000 ... 600,000)
        didSet { checkChallengeProgress() }
    }
    @Published var glucoseLevel: Double = 88.0 {  // mg/dL (50 ... 350)
        didSet { checkChallengeProgress() }
    }
    
    // MARK: - Navigation & Interactive Scene States
    @Published var activeMainTab: MainTab = .lab3D
    @Published var sceneViewMode: SceneViewMode = .microVein
    @Published var isChallengeModeActive: Bool = false
    @Published var challengeCompleted: Bool = false
    @Published var selectedPreset: PatientPreset? = PatientPreset.presets.first
    @Published var selectedCellType: BloodCellType? = nil
    @Published var selectedOrgan: TargetOrgan? = nil
    @Published var showOnboardingModal: Bool = false
    @Published var isSimulationPaused: Bool = false
    
    // MARK: - Nutrition Daily Tracker State
    @Published var dailyIntake: [String: Int] = [:] // foodId -> serving count
    
    // MARK: - Watch & HealthKit Telemetry State
    @Published var activeWatchProfile: WatchSyncProfile? = WatchSyncProfile.profiles.first
    @Published var dailyExerciseMinutes: Int = 45
    @Published var vo2Max: Double = 46.5
    @Published var sleepHours: Double = 7.6
    
    // MARK: - Automated Clinical Diagnosis
    var currentCondition: ClinicalCondition {
        // 1. Pancytopenia: Simultaneous tri-lineage marrow suppression
        if rbcCount < BloodCellType.erythrocytes.criticalLowThreshold &&
           wbcCount < BloodCellType.leukocytes.criticalLowThreshold &&
           pltCount < BloodCellType.platelets.criticalLowThreshold {
            return .pancytopenia
        }
        
        // 2. Acute Hypoglycemia (immediate neurological danger)
        if glucoseLevel < BloodCellType.glucose.criticalLowThreshold {
            return .hypoglycemia
        }
        
        // 3. Critical Hematology Thresholds
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
        } else if glucoseLevel > BloodCellType.glucose.criticalHighThreshold {
            return .hyperglycemia
        }
        
        // 4. Mild Borderline Deviations
        if rbcCount < BloodCellType.erythrocytes.normalRange.lowerBound &&
           wbcCount < BloodCellType.leukocytes.normalRange.lowerBound &&
           pltCount < BloodCellType.platelets.normalRange.lowerBound {
            return .pancytopenia
        } else if rbcCount < BloodCellType.erythrocytes.normalRange.lowerBound {
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
        } else if glucoseLevel > BloodCellType.glucose.normalRange.upperBound {
            return .hyperglycemia
        } else if glucoseLevel < BloodCellType.glucose.normalRange.lowerBound {
            return .hypoglycemia
        }
        
        return .homeostasis
    }
    
    var isHomeostasis: Bool {
        currentCondition == .homeostasis
    }
    
    // MARK: - Individual Statuses
    var rbcStatus: ParameterStatus { BloodCellType.erythrocytes.status(for: rbcCount) }
    var wbcStatus: ParameterStatus { BloodCellType.leukocytes.status(for: wbcCount) }
    var pltStatus: ParameterStatus { BloodCellType.platelets.status(for: pltCount) }
    var glucoseStatus: ParameterStatus { BloodCellType.glucose.status(for: glucoseLevel) }
    
    func status(for type: BloodCellType) -> ParameterStatus {
        switch type {
        case .erythrocytes: return rbcStatus
        case .leukocytes: return wbcStatus
        case .platelets: return pltStatus
        case .glucose: return glucoseStatus
        }
    }
    
    // MARK: - Homeostasis Challenge Score (0.0 to 1.0)
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
        
        let sRBC = score(value: rbcCount, normal: BloodCellType.erythrocytes.normalRange, min: BloodCellType.erythrocytes.minRange, max: BloodCellType.erythrocytes.maxRange)
        let sWBC = score(value: wbcCount, normal: BloodCellType.leukocytes.normalRange, min: BloodCellType.leukocytes.minRange, max: BloodCellType.leukocytes.maxRange)
        let sPLT = score(value: pltCount, normal: BloodCellType.platelets.normalRange, min: BloodCellType.platelets.minRange, max: BloodCellType.platelets.maxRange)
        let sGLU = score(value: glucoseLevel, normal: BloodCellType.glucose.normalRange, min: BloodCellType.glucose.minRange, max: BloodCellType.glucose.maxRange)
        
        return (sRBC + sWBC + sPLT + sGLU) / 4.0
    }
    
    // MARK: - Mathematical Bridge for 3D SceneKit Engine
    var targetRBCNodeCount: Int {
        let norm = BloodCellType.erythrocytes.normalizedValue(rbcCount)
        return Int(15.0 + (norm * 60.0))
    }
    
    var targetWBCNodeCount: Int {
        let norm = BloodCellType.leukocytes.normalizedValue(wbcCount)
        return Int(2.0 + (norm * 23.0))
    }
    
    var targetPLTNodeCount: Int {
        let norm = BloodCellType.platelets.normalizedValue(pltCount)
        return Int(5.0 + (norm * 50.0))
    }
    
    /// Renders glucose crystals above 140 mg/dL (up to 45 floating crystals at 350 mg/dL)
    var targetGlucoseNodeCount: Int {
        guard glucoseLevel > 140.0 else { return 0 }
        let excess = (glucoseLevel - 140.0) / (350.0 - 140.0)
        return Int(6.0 + (Swift.min(1.0, excess) * 39.0))
    }
    
    /// Intensity of vascular glycation darkening & hyperosmolar drag (0.0 to 1.0)
    var hyperglycemiaIntensity: Float {
        guard glucoseLevel > 140.0 else { return 0.0 }
        let excess = Float(glucoseLevel - 140.0) / Float(350.0 - 140.0)
        return Swift.min(1.0, Swift.max(0.0, excess))
    }
    
    /// Blood flow velocity multiplier incorporating polycythemia viscosity AND hyperglycemia hyperosmolarity
    var bloodFlowSpeedMultiplier: Float {
        if isSimulationPaused { return 0.0 }
        
        var speed: Float = 1.0
        if rbcCount > 5.9 {
            let excess = Float(rbcCount - 5.9) / Float(7.0 - 5.9)
            speed = Swift.max(0.35, 1.0 - (excess * 0.65))
        } else if rbcCount < 4.0 {
            speed = 1.25
        }
        
        // Hyperglycemia slows plasma velocity via osmotic drag
        if hyperglycemiaIntensity > 0 {
            speed *= Swift.max(0.60, 1.0 - (hyperglycemiaIntensity * 0.35))
        }
        return speed
    }
    
    var oxygenationGlowFactor: Float {
        let norm = Float(BloodCellType.erythrocytes.normalizedValue(rbcCount))
        return Swift.min(1.0, Swift.max(0.35, 0.35 + (norm * 0.65)))
    }
    
    var isImmuneResponseActive: Bool {
        wbcCount > BloodCellType.leukocytes.normalRange.upperBound
    }
    
    var cytokineParticleIntensity: Float {
        guard wbcCount > 11000.0 else { return 0.0 }
        let excess = Float(wbcCount - 11000.0) / Float(25000.0 - 11000.0)
        return Swift.min(1.0, Swift.max(0.0, excess))
    }
    
    var isClottingRiskActive: Bool {
        pltCount > BloodCellType.platelets.normalRange.upperBound
    }
    
    var fibrinMeshIntensity: Float {
        guard pltCount > 450000.0 else { return 0.0 }
        let excess = Float(pltCount - 450000.0) / Float(600000.0 - 450000.0)
        return Swift.min(1.0, Swift.max(0.0, excess))
    }
    
    var isBleedingRiskActive: Bool {
        pltCount < BloodCellType.platelets.criticalLowThreshold
    }
    
    // MARK: - Physiological & Watch Derived Metrics
    var heartRateBPM: Int {
        if let profile = activeWatchProfile,
           abs(rbcCount - profile.rbc) < 0.05 &&
           abs(glucoseLevel - profile.glucose) < 1.0 {
            return profile.restingHeartRateBPM
        }
        if rbcCount < 4.0 {
            let deficit = (4.0 - rbcCount) / (4.0 - 2.0)
            return Int(88.0 + (deficit * 28.0))
        } else if glucoseLevel < 65.0 {
            return 104 // Adrenergic hypoglycemia surge
        } else if wbcCount > 12000.0 {
            return 96
        } else if glucoseLevel > 180.0 {
            return 84
        } else if rbcCount > 6.0 {
            return 64
        } else {
            return 72
        }
    }
    
    var estimatedSpO2: Int {
        if rbcCount < 4.0 {
            let deficit = (4.0 - rbcCount) / 2.0
            return Swift.max(88, Int(96.0 - (deficit * 7.0)))
        } else if rbcCount > 6.2 {
            return 95
        }
        return 99
    }
    
    /// Estimated Glycated Hemoglobin (ADAG clinical equation: HbA1c = (Mean Glucose + 46.7) / 28.7)
    var estimatedHbA1c: Double {
        (glucoseLevel + 46.7) / 28.7
    }
    
    var relativeViscosity: Double {
        let hematocritApprox = (rbcCount / 5.0) * 0.45
        let glucoseDrag = hyperglycemiaIntensity > 0 ? Double(hyperglycemiaIntensity) * 1.4 : 0.0
        return 1.0 + (hematocritApprox * 8.5) + glucoseDrag
    }
    
    // MARK: - Nutrition Tracker Calculations
    var activeIntakeEntries: [DailyIntakeEntry] {
        FoodHabitItem.catalog.compactMap { item in
            let count = dailyIntake[item.id] ?? 0
            return count > 0 ? DailyIntakeEntry(item: item, servings: count) : nil
        }
    }
    
    var projectedDietValues: (rbc: Double, wbc: Double, plt: Double, glucose: Double) {
        var rbc = BloodCellType.erythrocytes.defaultValue
        var wbc = BloodCellType.leukocytes.defaultValue
        var plt = BloodCellType.platelets.defaultValue
        var glu = BloodCellType.glucose.defaultValue
        
        for entry in activeIntakeEntries {
            let s = Double(entry.servings)
            rbc += entry.item.rbcDeltaPerServing * s
            wbc += entry.item.wbcDeltaPerServing * s
            plt += entry.item.pltDeltaPerServing * s
            glu += entry.item.glucoseDeltaPerServing * s
        }
        
        return (
            rbc: Swift.min(BloodCellType.erythrocytes.maxRange, Swift.max(BloodCellType.erythrocytes.minRange, rbc)),
            wbc: Swift.min(BloodCellType.leukocytes.maxRange, Swift.max(BloodCellType.leukocytes.minRange, wbc)),
            plt: Swift.min(BloodCellType.platelets.maxRange, Swift.max(BloodCellType.platelets.minRange, plt)),
            glucose: Swift.min(BloodCellType.glucose.maxRange, Swift.max(BloodCellType.glucose.minRange, glu))
        )
    }
    
    func addIntakeServing(for item: FoodHabitItem) {
        dailyIntake[item.id, default: 0] += 1
    }
    
    func removeIntakeServing(for item: FoodHabitItem) {
        let current = dailyIntake[item.id] ?? 0
        if current > 1 {
            dailyIntake[item.id] = current - 1
        } else {
            dailyIntake.removeValue(forKey: item.id)
        }
    }
    
    func clearDailyIntake() {
        dailyIntake.removeAll()
    }
    
    func applyDietToBloodstream() {
        let projected = projectedDietValues
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isChallengeModeActive = false
            challengeCompleted = false
            selectedPreset = nil
            activeWatchProfile = nil
            rbcCount = projected.rbc
            wbcCount = projected.wbc
            pltCount = projected.plt
            glucoseLevel = projected.glucose
            activeMainTab = .lab3D
        }
    }
    
    // MARK: - Watch Sync & Personal Exam Actions
    func applyWatchProfile(_ profile: WatchSyncProfile) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            activeWatchProfile = profile
            dailyExerciseMinutes = profile.dailyExerciseMinutes
            vo2Max = profile.vo2Max
            sleepHours = profile.sleepHours
            isChallengeModeActive = false
            challengeCompleted = false
            selectedPreset = nil
            rbcCount = profile.rbc
            wbcCount = profile.wbc
            pltCount = profile.plt
            glucoseLevel = profile.glucose
        }
    }
    
    func applyPersonalBloodExam(rbc: Double, wbc: Double, plt: Double, glucose: Double) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            activeWatchProfile = nil
            selectedPreset = nil
            isChallengeModeActive = false
            challengeCompleted = false
            rbcCount = Swift.min(BloodCellType.erythrocytes.maxRange, Swift.max(BloodCellType.erythrocytes.minRange, rbc))
            wbcCount = Swift.min(BloodCellType.leukocytes.maxRange, Swift.max(BloodCellType.leukocytes.minRange, wbc))
            pltCount = Swift.min(BloodCellType.platelets.maxRange, Swift.max(BloodCellType.platelets.minRange, plt))
            glucoseLevel = Swift.min(BloodCellType.glucose.maxRange, Swift.max(BloodCellType.glucose.minRange, glucose))
            activeMainTab = .lab3D
        }
    }
    
    // MARK: - Preset & Challenge Actions
    func applyPreset(_ preset: PatientPreset) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isChallengeModeActive = false
            challengeCompleted = false
            activeWatchProfile = nil
            selectedPreset = preset
            rbcCount = preset.rbc
            wbcCount = preset.wbc
            pltCount = preset.plt
            glucoseLevel = preset.glucose
        }
    }
    
    func startEmergencyChallenge() {
        withAnimation(.easeInOut(duration: 0.35)) {
            isChallengeModeActive = true
            challengeCompleted = false
            selectedPreset = nil
            activeWatchProfile = nil
            rbcCount = 2.6
            wbcCount = 21500.0
            pltCount = 560000.0
            glucoseLevel = 240.0
        }
    }
    
    func resetToHomeostasis() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isChallengeModeActive = false
            challengeCompleted = false
            activeWatchProfile = nil
            selectedPreset = PatientPreset.presets.first
            rbcCount = BloodCellType.erythrocytes.defaultValue
            wbcCount = BloodCellType.leukocytes.defaultValue
            pltCount = BloodCellType.platelets.defaultValue
            glucoseLevel = BloodCellType.glucose.defaultValue
        }
    }
    
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
    
    func stepParameter(_ cellType: BloodCellType, increment: Bool) {
        let delta = increment ? cellType.step : -cellType.step
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedPreset = nil
            switch cellType {
            case .erythrocytes:
                rbcCount = Swift.min(cellType.maxRange, Swift.max(cellType.minRange, rbcCount + delta))
            case .leukocytes:
                wbcCount = Swift.min(cellType.maxRange, Swift.max(cellType.minRange, wbcCount + delta))
            case .platelets:
                pltCount = Swift.min(cellType.maxRange, Swift.max(cellType.minRange, pltCount + delta))
            case .glucose:
                glucoseLevel = Swift.min(cellType.maxRange, Swift.max(cellType.minRange, glucoseLevel + delta))
            }
        }
    }
}
