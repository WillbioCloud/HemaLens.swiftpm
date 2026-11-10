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

// MARK: - Blood Cell & Biomarker Type
enum BloodCellType: String, CaseIterable, Identifiable {
    case erythrocytes = "Red Blood Cells (RBC)"
    case leukocytes = "White Blood Cells (WBC)"
    case platelets = "Platelets (PLT)"
    case glucose = "Blood Glucose (Glycemia)"
    
    var id: String { rawValue }
    
    var shortName: String {
        switch self {
        case .erythrocytes: return "RBC"
        case .leukocytes: return "WBC"
        case .platelets: return "PLT"
        case .glucose: return "Glucose"
        }
    }
    
    var commonName: String {
        switch self {
        case .erythrocytes: return "Red Blood Cells"
        case .leukocytes: return "White Blood Cells"
        case .platelets: return "Platelets"
        case .glucose: return "Blood Glucose"
        }
    }
    
    var scientificName: String {
        switch self {
        case .erythrocytes: return "Erythrocytes"
        case .leukocytes: return "Leukocytes"
        case .platelets: return "Thrombocytes"
        case .glucose: return "Glycemia"
        }
    }
    
    var unit: String {
        switch self {
        case .erythrocytes: return "million/µL"
        case .leukocytes: return "/µL"
        case .platelets: return "/µL"
        case .glucose: return "mg/dL"
        }
    }
    
    var iconName: String {
        switch self {
        case .erythrocytes: return "drop.fill"
        case .leukocytes: return "shield.lefthalf.filled"
        case .platelets: return "bandage.fill"
        case .glucose: return "cube.fill"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .erythrocytes: return .red
        case .leukocytes: return .cyan
        case .platelets: return .yellow
        case .glucose: return .mint
        }
    }
    
    // MARK: - Sliders & Reference Ranges
    var minRange: Double {
        switch self {
        case .erythrocytes: return 2.0
        case .leukocytes: return 1000.0
        case .platelets: return 50000.0
        case .glucose: return 50.0
        }
    }
    
    var maxRange: Double {
        switch self {
        case .erythrocytes: return 7.0
        case .leukocytes: return 25000.0
        case .platelets: return 600000.0
        case .glucose: return 350.0
        }
    }
    
    var step: Double {
        switch self {
        case .erythrocytes: return 0.1
        case .leukocytes: return 500.0
        case .platelets: return 10000.0
        case .glucose: return 5.0
        }
    }
    
    var defaultValue: Double {
        switch self {
        case .erythrocytes: return 5.0
        case .leukocytes: return 7500.0
        case .platelets: return 280000.0
        case .glucose: return 88.0
        }
    }
    
    var normalRange: ClosedRange<Double> {
        switch self {
        case .erythrocytes: return 4.5...5.9
        case .leukocytes: return 4500.0...11000.0
        case .platelets: return 150000.0...450000.0
        case .glucose: return 70.0...99.0
        }
    }
    
    var criticalLowThreshold: Double {
        switch self {
        case .erythrocytes: return 4.0
        case .leukocytes: return 4000.0
        case .platelets: return 140000.0
        case .glucose: return 65.0
        }
    }
    
    var criticalHighThreshold: Double {
        switch self {
        case .erythrocytes: return 6.0
        case .leukocytes: return 12000.0
        case .platelets: return 450000.0
        case .glucose: return 140.0
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
        case .leukocytes, .platelets:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
        case .glucose:
            return "\(Int(value.rounded()))"
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
        case .glucose:
            return "Primary cellular fuel powering brain neurons, red blood cells, and skeletal muscles via ATP synthesis."
        }
    }
    
    var visual3DDescription: String {
        switch self {
        case .erythrocytes:
            return "Biconcave red discs dynamically tumbling in the laminar stream. Their concentration dictates plasma color and vessel luminosity."
        case .leukocytes:
            return "Larger, granular white-bluish spheres slowly rolling along the endothelial wall. During active infection, they release glowing radial cytokine particles."
        case .platelets:
            return "Organic golden biconvex cellular fragments. When triggered by high counts, they aggregate into dense clusters and weave fibrin thread networks."
        case .glucose:
            return "Translucent crystalline molecules suspended in plasma. Above 140 mg/dL, crystals accumulate, flow becomes sluggish, and vessel walls darken from glycation stress."
        }
    }
    
    var deficiencyImpact: String {
        switch self {
        case .erythrocytes:
            return "Hypoxia, tissue oxygen debt, extreme fatigue, tachycardia, and visible pallor in the bloodstream."
        case .leukocytes:
            return "Severe immunosuppression (neutropenia), making the body vulnerable to opportunistic bacterial and viral infections."
        case .platelets:
            return "Impaired primary hemostasis, prolonged bleeding time, spontaneous petechiae, and hemorrhagic risks."
        case .glucose:
            return "Neuroglycopenia: acute cerebral energy starvation causing shakiness, sweating, confusion, and fainting."
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
        case .glucose:
            return "Hyperosmolar plasma drag, hemoglobin glycation (HbA1c), endothelial oxidative stress, and long-term microvascular damage."
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
    let glucose: Double
    let clinicalSummary: String
    let visualClues: String
    let conditionName: String
    
    static func == (lhs: PatientPreset, rhs: PatientPreset) -> Bool {
        lhs.id == rhs.id
    }
    
    static let presets: [PatientPreset] = [
        PatientPreset(
            caseNumber: "Baseline",
            title: "Healthy Control",
            subtitle: "Normal physiological homeostasis",
            rbc: 5.0,
            wbc: 7500.0,
            plt: 280000.0,
            glucose: 86.0,
            clinicalSummary: "Optimal cellular and metabolic balance. Tissue perfusion is uninterrupted, glycemia is tightly regulated, and immune defenses stand ready.",
            visualClues: "Smooth laminar red flow, steady vessel luminosity, calm organs, and zero glucose crystal buildup.",
            conditionName: "Physiological Homeostasis"
        ),
        PatientPreset(
            caseNumber: "Case 1",
            title: "Iron Deficiency Anemia",
            subtitle: "Erythropenia & tissue hypoxia",
            rbc: 2.8,
            wbc: 6500.0,
            plt: 250000.0,
            glucose: 88.0,
            clinicalSummary: "Depleted iron reserves limit hemoglobin synthesis, plummeting erythrocyte count and forcing compensatory tachycardia.",
            visualClues: "Sparse red discs, pale desaturated lumen, and pulsing Brain/Lungs hypoxia alert in the 3D Body.",
            conditionName: "Anemia (Erythropenia)"
        ),
        PatientPreset(
            caseNumber: "Case 2",
            title: "Acute Bacterial Infection",
            subtitle: "Marked leukocytosis & cytokine activation",
            rbc: 4.8,
            wbc: 19500.0,
            plt: 320000.0,
            glucose: 112.0,
            clinicalSummary: "Pyogenic infection triggers cytokine-mediated bone marrow mobilization alongside mild stress hyperglycemia.",
            visualClues: "Surge of white leukocytes with soft glowing cytokine particles; glowing Bone Marrow in 3D Body.",
            conditionName: "Leukocytosis (Active Infection)"
        ),
        PatientPreset(
            caseNumber: "Case 3",
            title: "Coagulation Disorder",
            subtitle: "Thrombocytosis & hypercoagulability",
            rbc: 5.1,
            wbc: 8000.0,
            plt: 560000.0,
            glucose: 94.0,
            clinicalSummary: "Excessive thrombocyte proliferation accelerates vascular collisions, triggering spontaneous platelet aggregation and fibrin cross-linking.",
            visualClues: "Dense golden platelet clusters anchored by fibrin strands; Heart & Brain clotting alerts.",
            conditionName: "Thrombocytosis (Clotting Risk)"
        ),
        PatientPreset(
            caseNumber: "Case 4",
            title: "Uncontrolled Diabetes Risk",
            subtitle: "Hyperglycemia & endothelial glycation",
            rbc: 4.9,
            wbc: 10200.0,
            plt: 440000.0,
            glucose: 265.0,
            clinicalSummary: "Persistent insulin resistance spikes plasma glucose above 250 mg/dL, driving hyperosmolar drag, HbA1c glycation, and oxidative vascular stress.",
            visualClues: "Translucent glucose crystals flooding plasma, darkened endothelium, and sluggish blood flow.",
            conditionName: "Hyperglycemia (Diabetes Risk)"
        ),
        PatientPreset(
            caseNumber: "Case 5",
            title: "Pancytopenia (Marrow Failure)",
            subtitle: "Tri-lineage suppression",
            rbc: 2.7,
            wbc: 2100.0,
            plt: 75000.0,
            glucose: 84.0,
            clinicalSummary: "Simultaneous depression of erythrocytes, leukocytes, and platelets indicating severe bone marrow aplasia or toxic suppression.",
            visualClues: "Depleted bloodstream across all 3 cell lineages and dimmed/alert Bone Marrow in Macro View.",
            conditionName: "Pancytopenia (Marrow Suppression)"
        )
    ]
}
