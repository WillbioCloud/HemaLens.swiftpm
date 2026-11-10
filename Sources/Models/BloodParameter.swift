import Foundation
import SwiftUI

// MARK: - Parameter Status
enum ParameterStatus: Equatable {
    case criticalLow
    case low
    case normal
    case high
    case criticalHigh
    
    var label: String {
        switch self {
        case .criticalLow: return "Critically Low"
        case .low: return "Below Normal"
        case .normal: return "Optimal (Homeostasis)"
        case .high: return "Above Normal"
        case .criticalHigh: return "Critically High"
        }
    }
    
    var shortLabel: String {
        switch self {
        case .criticalLow: return "Crit. Low"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .criticalHigh: return "Crit. High"
        }
    }
    
    var color: Color {
        switch self {
        case .normal:
            return .green
        case .low, .high:
            return .orange
        case .criticalLow, .criticalHigh:
            return .red
        }
    }
    
    var isAbnormal: Bool {
        self != .normal
    }
    
    var isCritical: Bool {
        self == .criticalLow || self == .criticalHigh
    }
}

// MARK: - Blood Cell Type
enum BloodCellType: String, CaseIterable, Identifiable {
    case erythrocytes = "Red Blood Cells (RBC)"
    case leukocytes = "White Blood Cells (WBC)"
    case platelets = "Platelets (PLT)"
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .erythrocytes: return "RBC"
        case .leukocytes: return "WBC"
        case .platelets: return "PLT"
        }
    }
    
    var commonName: String {
        switch self {
        case .erythrocytes: return "Red Blood Cells"
        case .leukocytes: return "White Blood Cells"
        case .platelets: return "Platelets"
        }
    }
    
    var scientificName: String {
        switch self {
        case .erythrocytes: return "Erythrocytes"
        case .leukocytes: return "Leukocytes"
        case .platelets: return "Thrombocytes"
        }
    }
    
    var unit: String {
        switch self {
        case .erythrocytes: return "million/µL"
        case .leukocytes: return "/µL"
        case .platelets: return "/µL"
        }
    }
    
    var iconName: String {
        switch self {
        case .erythrocytes: return "drop.fill"
        case .leukocytes: return "shield.lefthalf.filled"
        case .platelets: return "bandage.fill"
        }
    }
    
    // MARK: - Sliders & Ranges (Section 4.1 SDD)
    var minRange: Double {
        switch self {
        case .erythrocytes: return 2.0
        case .leukocytes: return 1000.0
        case .platelets: return 50000.0
        }
    }
    
    var maxRange: Double {
        switch self {
        case .erythrocytes: return 7.0
        case .leukocytes: return 25000.0
        case .platelets: return 600000.0
        }
    }
    
    var step: Double {
        switch self {
        case .erythrocytes: return 0.1
        case .leukocytes: return 500.0
        case .platelets: return 10000.0
        }
    }
    
    var defaultValue: Double {
        switch self {
        case .erythrocytes: return 5.0
        case .leukocytes: return 7500.0
        case .platelets: return 280000.0
        }
    }
    
    var normalRange: ClosedRange<Double> {
        switch self {
        case .erythrocytes: return 4.5...5.9
        case .leukocytes: return 4500.0...11000.0
        case .platelets: return 150000.0...450000.0
        }
    }
    
    // Critical diagnosis thresholds defined in Section 4.2 of SDD
    var criticalLowThreshold: Double {
        switch self {
        case .erythrocytes: return 4.0
        case .leukocytes: return 4000.0
        case .platelets: return 140000.0
        }
    }
    
    var criticalHighThreshold: Double {
        switch self {
        case .erythrocytes: return 6.0
        case .leukocytes: return 12000.0
        case .platelets: return 450000.0
        }
    }
    
    // MARK: - Helper Methods
    func status(for value: Double) -> ParameterStatus {
        if value < criticalLowThreshold {
            return .criticalLow
        } else if value < normalRange.lowerBound {
            return .low
        } else if value > criticalHighThreshold {
            return .criticalHigh
        } else if value > normalRange.upperBound {
            return .high
        } else {
            return .normal
        }
    }
    
    func formattedValue(_ value: Double) -> String {
        switch self {
        case .erythrocytes:
            return String(format: "%.1f", value)
        case .leukocytes:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
        case .platelets:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
        }
    }
    
    func normalizedValue(_ value: Double) -> Double {
        let clamped = min(max(value, minRange), maxRange)
        return (clamped - minRange) / (maxRange - minRange)
    }
    
    // MARK: - Biomedical & Visual Insights
    var primaryFunction: String {
        switch self {
        case .erythrocytes:
            return "Transports oxygen from the lungs to peripheral tissues via hemoglobin, and returns carbon dioxide."
        case .leukocytes:
            return "Active immune surveillance, phagocytosis of pathogens, and cytokine-mediated defense against infections."
        case .platelets:
            return "Primary hemostasis: adheres to vascular subendothelial collagen to form a plug and initiate coagulation."
        }
    }
    
    var visual3DDescription: String {
        switch self {
        case .erythrocytes:
            return "Biconcave red discs dynamically tumbling in the laminar stream. Their concentration dictates plasma color and vessel luminosity."
        case .leukocytes:
            return "Larger, granular white-bluish spheres slowly rolling along the endothelial wall. During active infection, they release bright cytokine particles."
        case .platelets:
            return "Minute golden discoid fragments. When triggered by high counts, they aggregate into dense clusters and weave fibrin thread networks."
        }
    }
    
    var deficiencyImpact: String {
        switch self {
        case .erythrocytes:
            return "Hypoxia, tissue oxygen debt, extreme fatigue, tachycardia, and visible pallor in the bloodstream."
        case .leukocytes:
            return "Severe immunosuppression (neutropenia), making the body helpless against opportunistic bacterial and viral infections."
        case .platelets:
            return "Impaired primary hemostasis, prolonged bleeding time, spontaneous petechiae, and hemorrhagic risks."
        }
    }
    
    var excessImpact: String {
        switch self {
        case .erythrocytes:
            return "Blood hyperviscosity, sluggish microcirculation, elevated cardiac afterload, and thrombosis risks."
        case .leukocytes:
            return "Acute leukocytosis, high systemic inflammatory markers, cytokine storm potential, and hypermetabolic state."
        case .platelets:
            return "Spontaneous intravascular aggregation, hypercoagulability, and risk of deep vein thrombosis or stroke."
        }
    }
}

// MARK: - Patient Preset
struct PatientPreset: Identifiable, Equatable {
    let id = UUID()
    let caseNumber: String
    let title: String
    let subtitle: String
    let rbc: Double
    let wbc: Double
    let plt: Double
    let clinicalSummary: String
    let visualClues: String
    let conditionName: String
    
    static func == (lhs: PatientPreset, rhs: PatientPreset) -> Bool {
        lhs.id == rhs.id
    }
    
    // Presets configured according to Section 6 of SDD
    static let presets: [PatientPreset] = [
        PatientPreset(
            caseNumber: "Baseline",
            title: "Healthy Control",
            subtitle: "Normal physiological homeostasis",
            rbc: 5.0,
            wbc: 7500.0,
            plt: 280000.0,
            clinicalSummary: "Optimal cellular balance. Tissue perfusion is uninterrupted, immune defenses are standing by in peace, and primary hemostasis is balanced.",
            visualClues: "Smooth laminar red flow, steady vessel luminosity, gentle leukocyte rolling, and isolated golden platelets.",
            conditionName: "Physiological Homeostasis"
        ),
        PatientPreset(
            caseNumber: "Case 1",
            title: "Iron Deficiency Anemia",
            subtitle: "Erythropenia & tissue hypoxia",
            rbc: 2.8,
            wbc: 6500.0,
            plt: 250000.0,
            clinicalSummary: "Depleted iron reserves limit heme synthesis, plummeting erythrocyte count. The cardiovascular system exhibits compensatory tachycardia to overcome poor arterial oxygen content (CaO2).",
            visualClues: "Noticeably sparse red discs, pale desaturated vessel lumen, and rapid compensatory fluid dynamics.",
            conditionName: "Anemia (Erythropenia)"
        ),
        PatientPreset(
            caseNumber: "Case 2",
            title: "Acute Bacterial Infection",
            subtitle: "Marked leukocytosis & cytokine activation",
            rbc: 4.8,
            wbc: 19500.0,
            plt: 320000.0,
            clinicalSummary: "Pyogenic infection prompts cytokine-mediated bone marrow demargination and granulopoiesis. Leukocytes actively extravasate and release inflammatory mediators.",
            visualClues: "Surge of spherical white leukocytes patrolling the endothelial boundary, accompanied by luminous cytokine aura particles.",
            conditionName: "Leukocytosis (Active Infection)"
        ),
        PatientPreset(
            caseNumber: "Case 3",
            title: "Coagulation Disorder",
            subtitle: "Thrombocytosis & hypercoagulability risk",
            rbc: 5.1,
            wbc: 8000.0,
            plt: 560000.0,
            clinicalSummary: "Elevated thrombocyte proliferation creates extreme vascular collision rates, triggering primary platelet aggregation and spontaneous microthrombi formation.",
            visualClues: "Dense swarms of golden platelet fragments sticking together in clusters, anchoring fibrin mesh strands.",
            conditionName: "Thrombocytosis (Clotting Risk)"
        ),
        PatientPreset(
            caseNumber: "Case 4",
            title: "Dengue Hemorrhagic Risk",
            subtitle: "Severe thrombocytopenia & leukopenia",
            rbc: 4.6,
            wbc: 3400.0,
            plt: 65000.0,
            clinicalSummary: "Bone marrow suppression and immune-mediated destruction lead to profound thrombocytopenia and mild leukopenia, carrying severe hemorrhagic vulnerability.",
            visualClues: "Virtually no visible platelets in the stream, accompanied by diminished white immune cells.",
            conditionName: "Thrombocytopenia (Bleeding Risk)"
        )
    ]
}
