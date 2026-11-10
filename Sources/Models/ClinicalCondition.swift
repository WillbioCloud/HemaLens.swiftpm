import SwiftUI

// MARK: - Condition Severity
enum ConditionSeverity: String, Equatable {
    case optimal = "Optimal"
    case warning = "Clinical Warning"
    case critical = "Critical Alert"
    
    var color: Color {
        switch self {
        case .optimal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .optimal:
            return "checkmark.shield.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "cross.circle.fill"
        }
    }
}

// MARK: - Clinical Condition
enum ClinicalCondition: String, CaseIterable, Identifiable, Equatable {
    case homeostasis = "Physiological Homeostasis"
    case anemia = "Anemia (Erythropenia)"
    case polycythemia = "Polycythemia (Erythrocytosis)"
    case leukopenia = "Leukopenia (Immunosuppression)"
    case infectionResponse = "Leukocytosis (Active Infection)"
    case thrombocytopenia = "Thrombocytopenia (Bleeding Risk)"
    case thrombosisRisk = "Thrombocytosis (Clotting Risk)"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var medicalTerm: String {
        switch self {
        case .homeostasis: return "Euvolemic Homeostasis"
        case .anemia: return "Erythropenia / Tissue Hypoxia"
        case .polycythemia: return "Hyperviscosity Syndrome"
        case .leukopenia: return "Immunodeficiency / Neutropenia"
        case .infectionResponse: return "Reactive Leukocytosis"
        case .thrombocytopenia: return "Platelet Consumption / Deficit"
        case .thrombosisRisk: return "Intravascular Hypercoagulability"
        }
    }
    
    var severity: ConditionSeverity {
        switch self {
        case .homeostasis:
            return .optimal
        case .anemia, .leukopenia, .thrombocytopenia:
            return .warning
        case .polycythemia, .infectionResponse, .thrombosisRisk:
            return .critical
        }
    }
    
    var severityColor: Color {
        severity.color
    }
    
    var statusIcon: String {
        switch self {
        case .homeostasis: return "checkmark.seal.fill"
        case .anemia: return "lungs.fill"
        case .polycythemia: return "gauge.with.dots.needle.67percent"
        case .leukopenia: return "exclamationmark.shield.fill"
        case .infectionResponse: return "microbe.fill"
        case .thrombocytopenia: return "drop.triangle.fill"
        case .thrombosisRisk: return "waveform.path.ecg.rectangle.fill"
        }
    }
    
    var badgeTitle: String {
        switch self {
        case .homeostasis: return "OPTIMAL"
        case .anemia, .leukopenia, .thrombocytopenia: return "WARNING"
        case .polycythemia, .infectionResponse, .thrombosisRisk: return "CRITICAL ALERT"
        }
    }
    
    var laypersonExplanation: String {
        switch self {
        case .homeostasis:
            return "All three blood lineages are in dynamic harmony! Red cells supply ample oxygen, white cells maintain vigilant border security, and platelets float unactivated until needed."
        case .anemia:
            return "There are too few red blood cells carrying oxygen across the body. The bloodstream appears paler, tissues starve for oxygen, and the heart races to compensate, leading to fatigue and pallor."
        case .polycythemia:
            return "An excessive concentration of red cells turns blood into a thick, sluggish sludge. Watch the flow slow down dramatically, forcing the heart to exert perilous pumping effort."
        case .leukopenia:
            return "White immune cell reserves have collapsed. Without these cellular sentries, harmless environmental microbes can trigger overwhelming opportunistic infections."
        case .infectionResponse:
            return "Immune defense is on maximum alert! In response to bacterial or viral invasion, the bone marrow flooded the vessel with active leukocytes releasing chemical flares to destroy invaders."
        case .thrombocytopenia:
            return "Platelet count is dangerously low. Microscopic tears in the vessel walls cannot be patched quickly, leading to spontaneous bruising, petechiae, and uncontrolled bleeding."
        case .thrombosisRisk:
            return "Excessive platelets are colliding and sticking together. These spontaneous clusters trigger fibrin mesh cross-linking, creating life-threatening blood clots that can block vital arteries."
        }
    }
    
    var biomedicalNote: String {
        switch self {
        case .homeostasis:
            return "Normal hematocrit (~40–45%), normal leukocyte count (4,500–11,000/µL), and normal platelet count (150,000–450,000/µL). Poiseuille laminar flow is preserved."
        case .anemia:
            return "Depressed erythrocyte count severely reduces arterial oxygen content (CaO2 = 1.34 × Hb × SaO2 + 0.003 × PaO2), triggering reflex sympathetic tachycardia and peripheral vasodilation."
        case .polycythemia:
            return "Elevated hematocrit (>55%) causes an exponential spike in whole blood relative viscosity, drastically reducing shear rate and microvascular tissue perfusion."
        case .leukopenia:
            return "Absolute neutrophil count (ANC) below threshold impairs innate phagocytosis and respiratory burst, compromising mucosal barriers and humoral defense."
        case .infectionResponse:
            return "Marked granulocytosis driven by IL-1, TNF-alpha, and G-CSF mobilizes marginal pool leukocytes. Leukocytes exhibit rolling, endothelial adherence, and diapedesis."
        case .thrombocytopenia:
            return "Failure of primary hemostasis: inadequate platelet adhesion to subendothelial collagen via von Willebrand Factor (vWF), predisposing to mucosal and cerebral hemorrhage."
        case .thrombosisRisk:
            return "Elevated shear-induced platelet activation (SIPA) triggers alpha and dense granule release (ADP, TXA2), catalyzing rapid thrombin generation and insoluble fibrin clot deposition."
        }
    }
    
    var cardiovascularImpact: String {
        switch self {
        case .homeostasis:
            return "Balanced cardiac output (~5 L/min) and normal systemic vascular resistance."
        case .anemia:
            return "High-output circulatory state with compensatory tachycardia (>100 bpm)."
        case .polycythemia:
            return "High peripheral resistance, systemic hypertension, and cardiac strain."
        case .leukopenia:
            return "Hemodynamically unstable if systemic bacteremia evolves into septic shock."
        case .infectionResponse:
            return "Elevated core body temperature and hyperdynamic inflammatory pulse (~95 bpm)."
        case .thrombocytopenia:
            return "Risk of hypovolemic shock if major internal bleeding occurs."
        case .thrombosisRisk:
            return "Imminent risk of pulmonary embolism (PE), myocardial infarction, or stroke."
        }
    }
    
    var visual3DClues: [String] {
        switch self {
        case .homeostasis:
            return [
                "Lively ruby-red laminar flow",
                "Steady physiological velocity",
                "Occasional white sentry cells rolling",
                "Evenly dispersed golden platelets"
            ]
        case .anemia:
            return [
                "Sparse red disc population",
                "Translucent, desaturated vessel lumen",
                "Rapid compensatory pulse oscillations",
                "Diminished overall cell crowding"
            ]
        case .polycythemia:
            return [
                "Overcrowded, opaque red cell traffic",
                "Sluggish, creeping blood flow",
                "Severe viscous drag along vessel walls",
                "Dark crimson hyper-saturated lumen"
            ]
        case .leukopenia:
            return [
                "Absence of rolling immune spheres",
                "Vulnerable, unpatrolled endothelial surface",
                "Normal red cell and platelet dynamics"
            ]
        case .infectionResponse:
            return [
                "Surge of prominent textured white leukocytes",
                "Glowing cytokine particle emitters active",
                "Active patrolling and rolling motions",
                "Hyperdynamic vessel pulsation"
            ]
        case .thrombocytopenia:
            return [
                "Noticeable absence of golden platelet discs",
                "Endothelial micro-fissures remain unsealed",
                "Clear, unhindered plasma stream"
            ]
        case .thrombosisRisk:
            return [
                "Dense clusters of aggregated platelets",
                "Entangled fibrin thread networks forming",
                "Localized flow turbulence around clumps",
                "High collision frequency"
            ]
        }
    }
    
    var primaryOrganAtRisk: String {
        switch self {
        case .homeostasis: return "Whole Body (Optimal)"
        case .anemia: return "Brain & Heart (Hypoxia)"
        case .polycythemia: return "Heart & Kidneys (Viscosity Overload)"
        case .leukopenia: return "Immune Defenses & Mucosa"
        case .infectionResponse: return "Microvasculature & Lungs"
        case .thrombocytopenia: return "Microcirculation (Hemorrhage)"
        case .thrombosisRisk: return "Coronary & Cerebral Arteries"
        }
    }
    
    var clinicalAction: String {
        switch self {
        case .homeostasis:
            return "Maintain balanced nutrition, adequate hydration, and regular exercise."
        case .anemia:
            return "Investigate iron reserves (ferritin), vitamin B12/folate, or occult blood loss."
        case .polycythemia:
            return "Evaluate hydration status, JAK2 mutation, or perform therapeutic phlebotomy."
        case .leukopenia:
            return "Implement reverse isolation precautions; investigate bone marrow or drug reactions."
        case .infectionResponse:
            return "Identify infective focus, obtain cultures, and initiate targeted antimicrobials."
        case .thrombocytopenia:
            return "Avoid invasive procedures and NSAIDs; screen for immune thrombocytopenia (ITP)."
        case .thrombosisRisk:
            return "Initiate antiplatelet/anticoagulant therapy and investigate myeloproliferative cause."
        }
    }
}
